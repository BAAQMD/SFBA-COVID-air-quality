# SFBA-COVID-air-quality

Skeleton for analysis of air quality data in the San Francisco Bay Area (SFBA), pre- and post- "COVID-19".

## TODO

- handle non-normal, not-strictly-positive distribution
    - true values are non-negative, but some measurements are negative
    - true values are right-skewed, and so are the measurements
    - somehow model a two-part process (second part is additive error) using Stan?
    - somehow transform data to "approximately normal" in a way that is reasonable?

- construct explicit counterfactual using data from 2019, 2018, ...
    - look at [`fable`](https://cran.r-project.org/web/packages/fable/index.html) package 
    - look at [`prophet`](https://cran.r-project.org/web/packages/prophet/index.html) package

- exploit / account for correlation:
    - within each (site, pollutant) series (i.e., temporal autocorrelation)
    - between different pollutants measured at the same site
    - between sites (e.g. using [`spatstat`](https://cran.r-project.org/web/packages/spatstat/index.html))
    
## Setup and Data

`00-setup.R` should be run first
- loads libraries
- defines a function `with_epoch()`
    - labels data with "Pre" and "Post" in a new `epoch` column
    - **most plausible effects would not be instantaneous**, so "Pre" and "Post" are separated by a "transition" interval
    - accepts your definition of `transition_start` and `transition_end`

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

## Contact information

- David Holstius <dholstius@baaqmd.gov>

