source(here::here("code", "airnowtech_url_for_1h_data.R"))
source(here::here("code", "get_1h_data.R"))
source(here::here("code", "SFBA_1h_site_set.R")) # depends on `get_1h_data.R`
source(here::here("code", "get_1h_SFBA_data.R"))
source(here::here("code", "parse_date_time.R"))
source(here::here("code", "exclude_1h_data.R"))

#'
#' What timespan are we interested in?
#' 
dttm_tz    <- "Etc/GMT+8" 
dttm_start <- ISOdate(2020, 01, 01, hour = 00, tz = dttm_tz)
dttm_end   <- ISOdate(2020, 05, 13, hour = 23, tz = dttm_tz)
dttm_set   <- seq(from = dttm_end, to = dttm_start, by = dhours(-1))

#'
#' What do we want to exclude?
#'
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
#' Do the heavy lifting:
#' 
#' - actually fetch SFBA data
#' - parse timestamps
#' - keep only active sites
#' - drop data manually identified as "problematic"
#' - select and rearrange columns
#' 
#' See also `SFB_1h_blacklist` (above).
#'
SFBA_1h_data <- local({
  
  raw_data <-
    furrr::future_map_dfr(
      .x = dttm_set,
      .f = possibly(
        get_1h_SFBA_data, # use the cached variant (see above)
        otherwise = NULL,
        quiet = FALSE),
      .progress = TRUE) 
  
  parsed_data <-
    raw_data %>%
    mutate(
      dttm = parse_date_time(
        ValidDate, 
        ValidTime, 
        tz = dttm_tz)) 
  
  filtered_data <-
    parsed_data %>%
    filter(
      Status == "Active") %>%
    exclude_1h_data(
      blacklist = SFBA_1h_blacklist) 
  
  tidied_data <-
    filtered_data %>%
    select(
      dttm,
      everything(),
      -ValidDate,
      -ValidTime,
      -GMTOffset)
  
})

#'
#' Take a peek.
#' 
SFBA_1h_data %>% glimpse()
SFBA_1h_data %>% object.size() %>% format(units = "Mb")
SFBA_1h_data %>% summary()
