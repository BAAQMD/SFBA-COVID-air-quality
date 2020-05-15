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
