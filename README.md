# crops 
_Calculates statistics on Stardew Valley crops_


**NOTE**: This is a pet project for me and my girlfriend's Stardew
world and crop information is added as we discover it in-game; it will 
likely never be complete. Please do not submit new crop information in 
a PR.

## Syntax
Crop data and its syntax are stored by default in `stardew_crops`. 
Comments begin with `#` by default and are ignored by `crops`.

## Arguments
### Value options (minimum one):
 * `-p`  profit for an individual crop
 * `-P`  profit for a crop over an entire plot
 * `-s`  profit for an individual crop throughout the season
 * `-S`  profit for a crop throughout the season, over a plot
 * `-w`  average profit for a crop over a week (assuming planted at start of 
         week)
 * `-W`  average profit for a crop over a week (assuming planted at start of 
         week), over a plot
 * `-t`  days per harvest

### Preference options:
 * `-z`  specifies a custom plot size (in tiles)
 * `-c`  enables cleaner output (for piping into other scripts)

### Season options:
 * Typing two hyphens followed by the season name (e.g. `--winter`)
   specifies that only that season's crops are to be processed.
 * Specifying `--all` will only process crops that can be grown in
   all seasons.
 * If no season is specified, print all complete crop records.

**NOTE**: Any crop with a season value outside of `Summer`, `Autumn`,
`Spring`, `Winter` or `All` will be skipped. `N/A` signifies a crop
with an unknown growing season.

## Requirements
Requires `gawk` and its `getopt()` library function, as well as `bash`.
 * `crops` looks for `getopt()` according to the `AWKPATH` environment 
   variable, which is set in the shell wrapper (the `crops` script)
   according to the detected OS it's being run on (currenly only `linux-gnu`
   and `darwin`). If you need to change this elsewhere, set it in this file.
