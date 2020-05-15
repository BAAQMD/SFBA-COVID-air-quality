#'
#' To convert both `ValidDate` and `ValidTime` into a single parsed `dttm`.
#'
parse_date_time <- function (date, time, ...) {
  concatenated <- str_c(date, time, sep = " ")
  parsed_dttm <- lubridate::mdy_hm(concatenated, ...)
  return(parsed_dttm)
}
