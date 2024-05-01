#!/bin/gawk -f
     
# crops - Calculates statistics on Stardew Valley crops - (c) 2024 Zappi
#
# Value options:
#  -p  profit for a crop
#  -P  profit for a crop over a plot
#  -s  profit for a crop throughout the season
#  -S  profit for a crop throughout the season, over a plot
#  -t  days per harvest"
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
    # Number of crops in each plot
    PLOT_SIZE = 72  

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
            "psPSht", 
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
    printf "%s - %s\n====\n", cname, season
    
    # Go through arguments to see which values to print
    if (and(prefs_bit, A_PROFIT_BIT))          # p (just profit) 
        printf "Profit:\t\t£ %6i\n", 
            profit(sellp, basep)

    if (and(prefs_bit, A_PROFIT_PLOT_BIT))     # P (profit over entire plot)
        printf "Plot profit:\t£ %6i\n", 
            profit(sellp, basep) * PLOT_SIZE

    if (and(prefs_bit, A_SEASON_BIT))          # s (profit over season)
        printf "Season:\t\t£ %6i\n", 
            profit_season(sellp, basep, tph)

    if (and(prefs_bit, A_SEASON_PLOT_BIT))     # S (profit over plot & season)
        printf "Season - plot:\t£ %6i\n", 
            profit_season(sellp, basep, tph) * PLOT_SIZE

    if (and(prefs_bit, A_TPH_BIT))             # t (days per harvest)
        printf "Harvest time:\t%i days\n", tph

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
    return 28 / tph
}

# Calculate number of harvests in a week
function in_week(tph) {
    return 7 / tph
}

# Calculate raw profit for one crop without replanting
function profit(sellp, basep) {
    return sellp - basep
}

# Calculate profit for one crop over the season, if replanted
function profit_season(sellp, basep, tph) {
    return in_season(tph) * profit(sellp, basep)
}

