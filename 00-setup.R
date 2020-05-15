library(tidyverse)
library(lubridate)
library(glue)
library(furrr)
library(cacher) # devtools::install_github("BAAQMD/cacher)
library(lme4)

#'
#' These don't need to be attached; we'll just use `pkg::foo` instead.
#' 
imported_packages <- c(
  "ggthemes",
  "httr",
  "lemon",
  "tictoc",
  "here")

for (pkg in imported_packages) {
  requireNamespace(pkg)
}

#' 
#' To speed things up, we are going to both:
#' 
#' - cache responses to `GET` requests, using the `cacher` package; and
#' - use the `furrr` package to do asynchronous requests
#' 
#' This multisession plan is the `furrr` part.
#' 
future::plan(
  future::multisession(
    workers = 12))

#'
#' This is the bit that determines what we consider to be "Pre",
#' what we consider to be "Post", and (as a corollary) what we consider to
#' be "Transition" (i.e., `NA`).
#' 
source(here::here("code", "with_epoch.R"))
