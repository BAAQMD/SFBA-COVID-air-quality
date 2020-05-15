#'
#' To prepare for charting, or for anything else that expects long-format data.
#' 
#' - Select only the necessary columns
#' - Pivot to longer format
#' 
tidy_1h_data <- function (
  wide_1h_data, 
  value_vars,
  na.rm = TRUE
) {
  
  tidied_1h_data <-
    wide_1h_data %>%
    select(
      dttm,
      SiteName,
      !!value_vars) %>%
    gather(
      variable,
      value,
      tidyselect::one_of(value_vars)) 
  
  if (isTRUE(na.rm)) {
    tidied_1h_data <-
      filter(
        tidied_1h_data,
        is.finite(value))
  }
  
  return(tidied_1h_data)
  
}
