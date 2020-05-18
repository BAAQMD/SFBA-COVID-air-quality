# README

This repository is a skeleton for exploratory analyses of air quality data in the San Francisco Bay Area (SFBA), pre- _vs._ post- "COVID-19". Please read the sections below before running the code. If you have questions, please contact <a href="mailto:dholstius@baaqmd.gov">David Holstius</a>. Thank you!

## TODO

- handle non-normal, not-strictly-positive distribution
    - true values are non-negative, but some measurements are negative
    - true values are right-skewed, and so are the measurements
    - somehow model a two-part process (second part is additive error) using Stan?
    - somehow transform data to "approximately normal" in a way that is reasonable?

- construct explicit counterfactual using data from 2019, 2018, ...
    - look at [`fable`](https://cran.r-project.org/web/packages/fable/index.html) package 
    - look at [`prophet`](https://cran.r-project.org/web/packages/prophet/index.html) package

- exploit / account for covariance:
    - within each (site, pollutant) series (e.g. temporal autocorrelation)
    - between different pollutants measured at the same site
    - between sites (e.g. using [`spatstat`](https://cran.r-project.org/web/packages/spatstat/index.html))
    
## Setup and Definitions

`00-setup.R` should be run first. It loads the requisite libraries.

`ddtm_tz`, `dttm_start`, and `dttm_end` define the "transition" interval --- between "pre" and "post". This is used by [`with_epoch()`](https://github.com/BAAQMD/SFBA-COVID-air-quality/blob/master/code/with_epoch.R) to create a new `epoch` column with values "Pre", "Post", or `NA`. It is set up to handle the assumption that **most large effects would not plausibly be instantaneous**; they might play out over several days or even weeks. 

`SFBA_1h_blacklist` defines combinations of sites and times that should be omitted from further analyses. These were manually identified during early explorations and are not guaranteed to be complete or correct!

## Harvested Data

`01-harvest-1h-CA.R` pulls hourly data *for the entire state of California* from [AirNowTech.org](http://airnowtech.org). It does so using the [`BAAQMD/cacher`](https://github.com/BAAQMD/cacher) package to cache the results locally; backed by the high-performance [`.fst`](http://www.fstpackage.org) format for tabular data. After running `01-harvest-1h-CA.R`, the approximate size of `./cache/` will be **~50 Mb for 1h California data from Jan 01 through May 13, 2020**.

## Exploratory Work

`02-chart-1h-SFBA-PM25.R` generates a quick time-series chart of Bay Area PM2.5. This chart:
- is faceted by site
- shows means for both "Pre" and "Post"
- shows most of the data
    - Y-axis is (visually) clipped at -5 and 35 µg/m^3
    - no datapoints are actually dropped, so the (displayed) group means are accurate

`03-model-1h-SFBA-PM25.R` is a rough start. These models have been fit:
- simple linear model with fixed effect by `AQSID` (i.e., montoring site ID)
- simple mixed-effects model using `lme4`

`04-compare-1h-SFBA-PM25.R` compares pre/post distributions, ignoring autocorrelation. It shows:
- is faceted by site
- shows empirical cumulative distribution functions (ECDFs) for both "Pre" and "Post"
- shows _D-_ and _t-_ statistics (two-sided, unequal variance) with stars
- NOTE: the stars are likely _overconfident_ measures of "significance"

See **TODO** (above) for some ideas for next steps.
