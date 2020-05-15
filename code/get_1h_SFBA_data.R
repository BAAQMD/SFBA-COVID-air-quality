#' 
#' Scoped variant:
#' 
#' - tacks a `filter()` clause onto the cached variant
#' 
get_1h_SFBA_data <- function (
  dttm, 
  site_ids = SFBA_site_set,
  ...
) {
  
  filtered_data <-
    filter(
      get_1h_data(dttm, state = "CA"),
      AQSID %in% site_ids)
  
  return(filtered_data)
  
}
