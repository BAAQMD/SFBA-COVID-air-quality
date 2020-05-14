library(tidyverse)
library(ggthemes)
library(lubridate)
library(glue)
library(furrr)
library(httr)
library(cacher) # devtools::install_github("BAAQMD/cacher)
library(tictoc)
library(lme4)

#' 
#' To speed things up, we are going to both:
#' 
#' - cache responses to `GET` requests, using the `cacher` package; and
#' - use the `furrr` package to do asynchronous requests
#' 
#' This multisession plan is the `furrr` part.
#' 
plan(multisession(workers = 12))

#'
#' To label `input_data` with a new column `epoch`, based on
#' a presumed variable `dttm`. This will cut `dttm` into three
#' epochs:
#' 
#' - "Pre"
#' - `NA` (a transition period, to be dropped)
#' - "Post"
#' 
#' Supplying `na.rm = TRUE` causes the transition period to be dropped.
#'
with_epoch <- function (
  input_data,
  epoch_start = ISOdate(2020, 03, 09, hour = 00, tz = dttm_tz),
  epoch_end = ISOdate(2020, 03, 23, hour = 00, tz = dttm_tz),
  epoch_levels = c("Pre", NA, "Post"),
  na.rm = TRUE
) {
  
  epoch_breaks <- c(
    dttm_start, 
    epoch_start,  # start of transition interval
    epoch_end,    # end of transition interval
    dttm_end)
  
  cut_epoch <- function (dttm) {
    as.character(cut(
      dttm,
      breaks = epoch_breaks,
      include.lowest = TRUE,
      labels = epoch_levels,
      levels = epoch_levels))
  }
  
  labeled_data <-
    mutate(
      input_data,
      epoch = cut_epoch(dttm))
  
  if (isTRUE(na.rm)) {
    labeled_data <-
      filter(
        labeled_data,
        !is.na(epoch))
  }
  
  labeled_data <-
    mutate_at(
      labeled_data,
      vars(epoch),
      ~ factor(., levels = na.omit(epoch_levels)))
  
  
  return(labeled_data)
  
}
