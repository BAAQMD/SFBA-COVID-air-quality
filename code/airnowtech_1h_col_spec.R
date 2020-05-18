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
    O3 = col_double(),
    CO = col_double(),
    NO2 = col_double())
