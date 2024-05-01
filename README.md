# crops - Calculates statistics on Stardew Valley crops

## Arguments
### Value options:
 -p  profit for a crop
 -P  profit for a crop over a plot
 -s  profit for a crop throughout the season
 -S  profit for a crop throughout the season, over a plot
 -t  days per harvest

### Season options:
 * Typing two hyphens followed by the season name (e.g. `--winter`)
   specifies that only that season's crops are to be processed.
 * Specifying `--all` will only process crops that can be grown in
   all seasons.
 * If no season is specified, print all complete crop records.
_NOTE_: Any crop with a season value outside of Summer, Autumn,
Spring, Winter or All will be skipped.

## Requirements
Requires GNU awk and its getopt() library function.
