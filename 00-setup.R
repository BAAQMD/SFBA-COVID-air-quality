library(tidyverse)
library(lubridate)
library(furrr)
library(cacher) # devtools::install_github("BAAQMD/cacher)
require(broom)

#'
#' These don't need to be attached; we'll just use `pkg::foo` instead.
#' 
imported_packages <- c(
  "glue",
  "ggthemes",
  "httr",
  "lemon",
  "lme4",
  "here")

for (pkg in imported_packages) {
  requireNamespace(pkg)
}

#'-----------------------------------------------------------------------------
#' 
#' What timespan are we interested in?
#' 
#'-----------------------------------------------------------------------------
dttm_tz    <- "Etc/GMT+8" 
dttm_start <- ISOdate(2020, 01, 01, hour = 00, tz = dttm_tz)
dttm_end   <- ISOdate(2020, 05, 13, hour = 23, tz = dttm_tz)
dttm_set   <- seq(from = dttm_end, to = dttm_start, by = dhours(-1))

#'-----------------------------------------------------------------------------
#'
#' What do we want to exclude?
#'
#'-----------------------------------------------------------------------------
SFBA_1h_blacklist <-
  tibble::tribble(
    ~ SiteName, ~ dttm_from, ~ dttm_to,
    "Rio Vista",
    dttm_start, 
    dttm_end,
    "Vacaville",
    ISOdate(2020, 02, 26, hour = 0, tz = dttm_tz), 
    ISOdate(2020, 03, 15, hour = 23, tz = dttm_tz))

show(SFBA_1h_blacklist)

#'
#' This is the bit that determines what we consider to be "Pre",
#' what we consider to be "Post", and (as a corollary) what we consider to
#' be "Transition" (i.e., `NA`).
#' 
source(here::here("code", "with_epoch.R"))

#'
#' Source other useful functions.
#'
source(here::here("code", "format_decimal.R"))
