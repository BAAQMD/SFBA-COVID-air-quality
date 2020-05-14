# SFBA-COVID-air-quality

Skeleton for analysis of air quality data in the San Francisco Bay Area (SFBA), pre- and post- "COVID-19".

## Contact information

- David Holstius <dholstius@baaqmd.gov>

## Setup and Data

`00-setup.R` should be run first
- loads libraries
- defines a function `with_epoch()`
    - labels data with "Pre" and "Post" in a new `epoch` column
    - "Pre" and "Post" are separated by a "transition" interval --- most plausible effects would not be instantaneous

`01-harvest-1h.R` pulls hourly data 
- *for the entire United States* 
- from [AirNowTech.org](http://airnowtech.org)
- using the [`cacher`](https://github.com/BAAQMD/cacher) package
    - to cache the results locally
    - backed by the high-performance [`.fst`](http://www.fstpackage.org) format for tabular data

The approximate size of `./cache/` will be **~400 Mb for 1h data from Jan 01 through May 13, 2000**.

## Exploratory Work

`02-chart-1h-PM25.R` is a quick peek
- shows all the data
- shows means for both "Pre" and "Post"

`03-model-1h-PM25.R` is a rough start
- simple linear model with fixed effect by `AQSID` (i.e., montoring site ID)
- simple mixed-effects model using `lme4`

## TODO

- more sophisticated modeling
- construct explicit counterfactual using data from 2019, 2018, ...
- look at the `fable()` package and/or Prophet?

