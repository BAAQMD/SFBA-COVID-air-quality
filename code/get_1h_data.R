#'
#' Get a subset of columns, and don't try to be fancy.
#' 
airnowtech_1h_col_spec <- 
  readr::cols_only(
    AQSID = col_character(),
    StateName = col_character(),
    SiteName = col_character(),
    Status = col_factor(),
    GMTOffset = col_double(),
    ValidDate = col_character(),
    ValidTime = col_character(),
    PM25 = col_double(),
    PM10 = col_double(),
    NO2 = col_double())

#'
#' Uncached variant:
#'
#' - forms the correct URL, given `dttm` 
#' - uses `httr` library to get content, as text 
#' - uses `readr` library to parse as CSV
#'
#' FIXME: Should `url_tz` be "UTC"? What is AirNow's convention? There's a GMT
#' offset supplied in the file contents, but what about the filename?
#' 
get_1h_data__ <- function (
  dttm, 
  url_tz = "UTC", 
  col_types = airnowtech_1h_col_spec
) {
  
  url_dttm <- 
    lubridate::with_tz(
      dttm, 
      tz = url_tz) 
  
  url <- 
    airnowtech_url_for_1h_data(
      url_dttm)
  
  response <- httr::GET(url)
  httr::stop_for_status(response)
  
  unparsed_content <- 
    httr::content(
      response, 
      as = "text", 
      encoding = "UTF-8")
  
  parsed_data <- 
    readr::read_csv(
      unparsed_content, 
      col_types = col_types)
  
  return(parsed_data)
  
}

#'
#' Cached variant:
#' 
#' - uses the `cacher` package to wrap `get_airnowtech_1h_data__`
#' - filesystem-backed, using the .fst format (very efficient for tabular data)
#' - allows for filtering, using `...`
#'
get_1h_data <- function (
  dttm, 
  state,
  ...
) {
  
  require(cacher)
  
  stopifnot(
    length(state) == 1, 
    state %in% state.abb)
  
  cache_root <- 
    here::here("cache")
  
  state_1h_data <- 
    cacher::cached(
      state,
      format(dttm, "%Y%m%d"),
      format(dttm, str_c(state, "-%Y%m%d-%H00h")), 
      ext = ".fst", 
      root = cache_root) %or% {
        filter(
          get_1h_data__(dttm, ...),
          StateName == state)
      }
  
  return(state_1h_data)
  
}