source(here::here("code", "make_1h_stripchart.R"))

#'
#' This chart begins at January 1, 2020.
#' 
SFBA_PM25_1h_stripchart <- local({
  
  #'
  #' TODO: improve chart title and subtitle.
  #'
  chart_description <- 
    ggplot2::labs(
      title = "Ambient PM2.5 Measurements",
      subtitle = glue::glue(
        "Source: AirNowTech.",
        "Points jittered to reduce overplotting.",
        "Y-axis clipped at {max(chart_y_limits)}, but no data are dropped when calculating group means.",
        .sep = "\n"),
      caption = glue::glue(
        "DRAFT {format(Sys.Date(), '%Y-%m-%d')}"))
  
  filtered_data <-
    SFBA_1h_data %>%
    filter(
      dttm >= ISOdate(2020, 01, 01, hour = 00, tz = dttm_tz))
    
  SFBA_PM25_1h_stripchart <-
    make_1h_stripchart(
      filtered_data,
      value_var = "PM25",
      value_unit = "ug/m3",
      value_limits = c(-5, 35)) +
    chart_description
  
})

show(SFBA_PM25_1h_stripchart)

ggplot2::ggsave(
  here::here("figures", "SFBA-PM25-1h-stripchart.pdf"),
  SFBA_PM25_1h_stripchart,
  width = 11 - 2,
  height = 17 - 2)
