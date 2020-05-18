source(here::here("code", "get_1h_data.R"))
source(here::here("code", "SFBA_1h_site_set.R")) # depends on `get_1h_data.R`

#' 
#' Scoped variant:
#' 
#' - tacks a `filter()` clause onto the cached variant
#' 
get_1h_SFBA_data <- function (
  dttm, 
  site_ids = SFBA_1h_site_set,
  ...
) {
  
  filtered_data <-
    filter(
      get_1h_data(dttm, state = "CA"),
      AQSID %in% site_ids)
  
  return(filtered_data)
  
}
