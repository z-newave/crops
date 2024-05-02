#!/bin/gawk -f
     
# crops - Calculates statistics on Stardew Valley crops - (c) 2024 Zappi
#
# Value options:
#  -p  profit for a crop
#  -P  profit for a crop over a plot
#  -s  profit for a crop throughout the season
#  -S  profit for a crop throughout the season, over a plot
#  -t  days per harvest
#  -w  average (rounded down) profit for a crop in a week
#  -W  average (rounded down) profit for a crop in a week, over a plot
#
# Preference options:
#  -z  specifies a custom plot size (in tiles)
#  -c  enables cleaner output (for piping into other scripts)
#
# Season options:
#  - Typing two hyphens followed by the season name (e.g. `--winter`)
#    specifies that only that season's crops are to be processed.
#  - Specifying `--all` will only process crops that can be grown in
#    all seasons.
#  - If no season is specified, print all complete crop records.
# NOTE: Any crop with a season value outside of Summer, Autumn,
# Spring, Winter or All will be skipped.
#
# Requires GNU awk and getopt() library function.
#
# This file is part of `crops` which is released under the GPLv3 licence.
# See file LICENSE for full licence details.

@include "/usr/share/awk/getopt.awk"

BEGIN {
    # Regular expression which marks commented-out lines to not be processed
    COMMENT_REGEXP = "^#"
    # Number of crops in each plot. This can be specified at runtime with the
    # `-z` flag
    PLOT_SIZE = 72  
    # Minimum number of fields in each record
    MIMUMUM_NR = 5

    # Bitpacked command-line arguments - 10-bit integer.
    # The right-most 5 bits represent requested seasons, while the rest
    # represent values to be calculated.
    prefs_bit = 0

    # prefs_bit bitmasks
    S_SUMMER_BIT        = 1
    S_AUTUMN_BIT        = 2
    S_WINTER_BIT        = 4
    S_SPRING_BIT        = 8
    S_ALL_BIT           = 16
    A_PROFIT_BIT        = 32
    A_PROFIT_PLOT_BIT   = 64
    A_SEASON_BIT        = 128
    A_SEASON_PLOT_BIT   = 256
    A_TPH_BIT           = 512
    A_WEEK_BIT          = 1024
    A_WEEK_PLOT_BIT     = 2048
    CLEAN_OUTPUT_BIT    = 4096

    prefs_bit = parse_args()

    # Delete ARGV after processing to prevent AWK from processing them as
    # file names.
    delete ARGV
}

$0 !~ COMMENT_REGEXP {
    cname   = $1    # name of crop
    basep   = $2    # base price at Pierre's
    sellp   = $3    # sell price for final crop
    tph     = $4    # time per harvest
    season  = $5    # season to be grown in
    
    # Don't process crops with N/A as their season
    if(season ~ "N/A") next

    # Don't process crops with incomplete values
    if (basep == 0 || sellp == 0 || tph == 0) next
 
    # Only process crops grown in specified seasons
    if(and(prefs_bit, 31)) {
        if(season ~ "Summer" && !(and(prefs_bit, S_SUMMER_BIT))) next
        if(season ~ "Autumn" && !(and(prefs_bit, S_AUTUMN_BIT))) next
        if(season ~ "Winter" && !(and(prefs_bit, S_WINTER_BIT))) next
        if(season ~ "Spring" && !(and(prefs_bit, S_SPRING_BIT))) next
        if(season ~ "All"    && !(and(prefs_bit, S_ALL_BIT))) next
    }
    
    # Calculate values specified in prefs_bit for current crop
    output_values(prefs_bit, cname, basep, sellp, tph, season) 
}

# Parse command-line arguments and return bitpacked preferences
function parse_args(        prefs_bit, Opterr) {
    # Option for getopt() - disables internal error message
    Opterr = 0

    # Error out if no arguments are passed
    if (ARGC < 2) {
        error("Not enough arguments passed")
        help()
        exit 1
    }

    # Process arguments and bitpack them into prefs_bit
    while ((c = getopt(ARGC, ARGV, 
            "psPShtwWcz:", 
            "summer,autumn,winter,spring,all")) != -1) {
        switch (c) {
            case "p":
                prefs_bit = prefs_bit + A_PROFIT_BIT
                break
            case "P":
                prefs_bit = prefs_bit + A_PROFIT_PLOT_BIT
                break
            case "s":
                prefs_bit = prefs_bit + A_SEASON_BIT
                break
            case "S":
                prefs_bit = prefs_bit + A_SEASON_PLOT_BIT
                break
            case "h":
                help()
                exit 0
            case "t":
                prefs_bit = prefs_bit + A_TPH_BIT
                break
            case "w":
                prefs_bit = prefs_bit + A_WEEK_BIT
                break
            case "W":
                prefs_bit = prefs_bit + A_WEEK_PLOT_BIT
                break
            case "c":
                prefs_bit = prefs_bit + CLEAN_OUTPUT_BIT
                break
            case "z":
                if (Optarg == 0) {
                    error("Plot size must be at least one")
                    exit 1
                }
                PLOT_SIZE = int(Optarg)
                break
            case "summer":
                prefs_bit = prefs_bit + S_SUMMER_BIT
                break
            case "autumn":
                prefs_bit = prefs_bit + S_AUTUMN_BIT
                break
            case "winter":
                prefs_bit = prefs_bit + S_WINTER_BIT
                break
            case "spring":
                prefs_bit = prefs_bit + S_SPRING_BIT
                break
            case "all":
                prefs_bit = prefs_bit + S_ALL_BIT
                break
            case "?":
                error("Invalid argument passed")
                help()
                exit 1
            default:
                error("Unknown error occured")
                help()
                exit 2
        }
    }
    return prefs_bit
}

# Calculate and format each statistic for appropriate crops
function output_values(prefs_bit, cname, basep, sellp, tph, season) {
    if (!and(prefs_bit, CLEAN_OUTPUT_BIT))
        printf "%s - %s\n====\n", cname, season
    
    # Go through arguments to see which values to print
    if (and(prefs_bit, A_PROFIT_BIT))          # p (just profit)
        if(and(prefs_bit, CLEAN_OUTPUT_BIT))
            printf "%s\tprofit\t\t%i\n",
                cname, profit(sellp, basep)
        else
            printf "Profit:\t\t£ %6i\n", 
                profit(sellp, basep)

    if (and(prefs_bit, A_PROFIT_PLOT_BIT))     # P (profit over entire plot)
        if(and(prefs_bit, CLEAN_OUTPUT_BIT))
            printf "%s\tprofit_p\t%i\n",
                cname, profit(sellp, basep) * PLOT_SIZE
        else
            printf "Plot profit:\t£ %6i\n", 
                profit(sellp, basep) * PLOT_SIZE

    if (and(prefs_bit, A_SEASON_BIT))          # s (profit over season)
        if(and(prefs_bit, CLEAN_OUTPUT_BIT))
            printf "%s\tseason\t\t%i\n",
                cname, profit_season(sellp, basep, tph)
        else
            printf "Season:\t\t£ %6i\n", 
                profit_season(sellp, basep, tph)

    if (and(prefs_bit, A_SEASON_PLOT_BIT))     # S (profit over plot & season)
        if(and(prefs_bit, CLEAN_OUTPUT_BIT))
            printf "%s\tseason_p\t%i\n",
                cname, profit_season(sellp, basep, tph) * PLOT_SIZE
        else
            printf "Season plot:\t£ %6i\n", 
                profit_season(sellp, basep, tph) * PLOT_SIZE

    if (and(prefs_bit, A_WEEK_BIT))            # w (mean profit within a week)
        if(and(prefs_bit, CLEAN_OUTPUT_BIT))
            printf "%s\tweek\t\t%i\n",
                cname, profit_week(sellp, basep, tph)
        else
            printf "Week:\t\t£ %6i\n",
                profit_week(sellp, basep, tph)

    if (and(prefs_bit, A_WEEK_BIT))            # W (mean profit within a week
        if(and(prefs_bit, CLEAN_OUTPUT_BIT))   #    over an entire plot)
            printf "%s\tweek_p\t\t%i\n",
                cname, profit_week(sellp, basep, tph) * PLOT_SIZE
        else
            printf "Week plot:\t£ %6i\n",                       
                profit_week(sellp, basep, tph) * PLOT_SIZE
 
    if (and(prefs_bit, A_TPH_BIT))             # t (days per harvest)
        if(and(prefs_bit, CLEAN_OUTPUT_BIT))
            printf "%s\tharvest\t\t%i\n",
                cname, tph
        else
            printf "Harvest time:\t%i days\n", tph

    # Print crop's season out on its own line if the `-c` flag is set
    if (and(prefs_bit, CLEAN_OUTPUT_BIT))
        printf "%s\tgrowing\t\t%s", cname, season
         
    # Must include two quotations - otherwise will print $0 by default
    print ""

    return
}

# Print error message to STDERR
function error(msg, ext) {
    printf ("%s%s\n", msg, ext) > "/dev/stderr"
    
    return
}

# Print help screen
function help() {
    print "crops - Calculates statistics on Stardew Valley crops"
    print 
    print "Value options:"
    print " -p  profit for a crop"
    print " -P  profit for a crop over a plot"
    print " -s  profit for a crop throughout the season"
    print " -S  profit for a crop throughout the season, over a plot"
    print " -t  days per harvest"
    print " -w  average (rounded) profit for a crop in a week"
    print " -W  average (rounded) profit for a crop in a week, over a plot"
    print
    print "Preference options:"
    print " -z  specifies a custom plot size (in tiles)"
    print " -c  enables cleaner output (for piping into other scripts)"
    print
    print "Season options:" 
    print " - Typing two hyphens followed by the season name (e.g. `--winter`)"
    print "   specifies that only that season's crops are to be processed."
    print " - Specifying `--all` will only process crops that can be grown in"
    print "   all seasons."
    print " - If no season is specified, print all complete crop records."
    print "NOTE: Any crop with a season value outside of Summer, Autumn,"
    print "Spring, Winter or All will be skipped."
    print
    print "Requires GNU awk and getopt() library function."

    return
}

# Calculate number of harvests in a season
function in_season(tph) {
    return int(28 / tph)
}

# Calculate number of harvests in a week
function in_week(tph) {
    return int(7 / tph)
}

# Calculate raw profit for one crop without replanting
function profit(sellp, basep) {
    return sellp - basep
}

# Calculate profit for one crop over the season, if replanted
function profit_season(sellp, basep, tph) {
    return in_season(tph) * profit(sellp, basep)
}

# Calculate average profit for one crop over a week without replanting
function profit_week(sellp, basep, tph) {
    return in_week(tph) * profit(sellp, basep)
}

