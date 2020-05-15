#'
#' To construct the URL for a particular hour's worth of data.
#'
#' AirNowTech hosts CSV-formatted files on Amazon S3. They all have the
#' extension ".dat", for some reason. Each file contains one hour's worth
#' of monitoring data, from all sites across the United States.
#' 
airnowtech_url_for_1h_data <- function (dttm) {
  glue::glue(
    "https://s3-us-west-1.amazonaws.com/",
    "files.airnowtech.org/airnow/",
    "{format(dttm, '%Y')}/",
    "{format(dttm, '%Y%m%d')}/",
    "HourlyAQObs_{format(dttm, '%Y%m%d%H')}.dat")
}

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

#'
#' Sites in the Bay Area.
#'
SFBA_site_set <- local({
  
  SFBA_COUNTY_FIPS_CODES <- c(
    Alameda = "001", `Contra Costa` = "013", Marin = "041", 
    Napa = "055", `San Francisco` = "075", `San Mateo` = "081", 
    `Santa Clara` = "085", Solano = "095", Sonoma = "097")
  
  sample_data <-
    get_1h_data(
      dttm = Sys.time() - ddays(1),
      state = "CA")
  
  site_blacklist <- c(
    "Vacaville") # in Solano County, but not BAAQMD jurisdiction
  
  SFBA_site_set <-
    sample_data %>%
    filter(
      str_sub(AQSID, 1, 5) %in% str_c("06", SFBA_COUNTY_FIPS_CODES)) %>%
    filter(
      !(SiteName %in% site_blacklist)) %>%
    distinct(
      SiteName, 
      AQSID) %>%
    deframe()
  
})

#' 
#' Scoped variant:
#' 
#' - tacks a `filter()` clause onto the cached variant
#' 
get_1h_SFBA_data <- function (
  dttm, 
  ...
) {
  
  filtered_data <-
    filter(
      get_1h_data(dttm, state = "CA"),
      AQSID %in% SFBA_site_set)
  
  return(filtered_data)
  
}

#'
#' What timespan are we interested in?
#' 
dttm_tz <- "Etc/GMT+8" 
dttm_start <- ISOdate(2020, 05, 01, hour = 00, tz = dttm_tz)
dttm_end <- ISOdate(2020, 05, 12, hour = 23, tz = dttm_tz)
dttm_set <- seq(from = dttm_end, to = dttm_start, by = dhours(-1))

#'
#' To convert both `ValidDate` and `ValidTime` into a single parsed `dttm`.
#'
parse_dttm <- function (date, time, ...) {
  concatenated <- str_c(date, time, sep = " ")
  parsed_dttm <- lubridate::mdy_hm(concatenated, ...)
  return(parsed_dttm)
}

exclude_1h_data <- function (
  input_data,
  blacklist
) {
  
  warning(
    "Excluding data from `blacklist`")
  
  blacklist_set <-
    mutate(
      blacklist,
      dttm = map2(
        .f = seq,
        .x = dttm_from,
        .y = dttm_to,
        by = dhours(1))) %>%
    select(
      -dttm_from,
      -dttm_to) %>%
    unnest_longer(
      col = c(dttm = dttm))
  
  anti_join(
    input_data,
    blacklist_set,
    by = names(blacklist_set))
  
}

SFBA_1h_blacklist <-
  tibble::tribble(
    ~ SiteName, ~ dttm_from, ~ dttm_to,
    "Rio Vista",
    dttm_start, 
    dttm_end,
    "Vacaville",
    ISOdate(2020, 02, 26, hour = 0, tz = dttm_tz), 
    ISOdate(2020, 03, 15, hour = 23, tz = dttm_tz))

tictoc::tic() # start timing

#'
#' Do the heavy lifting:
#' 
#' - actually fetch SFBA data
#' - parse timestamps
#'
SFBA_1h_data <-
  furrr::future_map_dfr(
    .x = dttm_set,
    .f = get_1h_SFBA_data, # use the cached variant (see above)
    .progress = TRUE) %>%
  mutate(
    dttm = parse_dttm(
      ValidDate, 
      ValidTime, 
      tz = dttm_tz)) %>%
  filter(
    Status == "Active") %>%
  exclude_1h_data(
    blacklist = SFBA_1h_blacklist) %>%
  select(
    dttm,
    everything(),
    -ValidDate,
    -ValidTime,
    -GMTOffset)

tictoc::toc() # stop timing; print elapsed time

show(format(object.size(SFBA_1h_data), units = "Mb"))
glimpse(SFBA_1h_data)

