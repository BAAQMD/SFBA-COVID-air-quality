source(here::here("code", "tidy_1h_data.R"))

chart_guides <-
  guides(
    color = guide_legend(
      title = "Epoch",
      override.aes = list(size = 3, alpha = 1)))

chart_theme <-
  theme_minimal() +
  theme(
    axis.title.x = element_text(size = rel(0.9), margin = margin(1.5, 0, 0, 0, "lines")),
    strip.text = element_text(size = rel(0.9), hjust = 0, face = "bold"),
    panel.spacing.x = unit(2, "lines"),
    #axis.text.y = element_text(vjust = 0),
    plot.title = element_text(face = "bold"))

chart_color_scale <-
  ggthemes::scale_color_excel_new()

make_1h_stripchart <- function (
  input_data,
  value_var,
  value_limits,
  ...
) {
  
  chart_data <-
    input_data %>%
    tidy_1h_data(
      value_vars = value_var,
      na.rm = TRUE) %>%
    with_epoch(
      na.rm = TRUE)
  
  #'
  #' NOTE: `value_limits` is used in `coord_cartesian(ylim = .)`, instead
  #' of `scale_y_continous(limits = ., ...)`. That will ensure that,
  #' even though we are clipping the viewport, we aren't dropping the
  #' data --- so things like `geom_smooth()` will be using the full
  #' `chart_data` as the basis for smoothing.
  #'
  
  #'
  #' Let's show `dttm_tz` (the timezone) on the x-axis.
  #'
  chart_x_axis_title <-
    stringr::str_remove(
      lubridate::tz(pull(chart_data, dttm)),
      fixed("Etc/"))
  
  #'
  #' TODO: show vertical lines on Sundays instead of Mondays?
  #'
  chart_x_scale <-
    scale_x_datetime(
      name = chart_x_axis_title,
      expand = expansion(0, 0),
      date_labels = "%d\n%b",
      date_breaks = "2 weeks",
      date_minor_breaks = "1 week")
  
  chart_y_scale <-
    scale_y_continuous(
      name = NULL,
      expand = expansion(mult = 0, add = 0))
  
  chart_faceting <-
    lemon::facet_rep_wrap(
      ~ SiteName, 
      repeat.tick.labels = "y",
      ncol = 3)
  
  chart_object <-
    ggplot(chart_data) +
    aes(x = dttm, y = value, group = SiteName) +
    aes(color = epoch) +
    geom_hline(
      size = I(0.5),
      yintercept = 0) +
    geom_point(
      position = position_jitter(height = 0.5),
      show.legend = FALSE,
      size = I(0.3),
      alpha = I(0.2)) +
    chart_color_scale +
    chart_faceting +
    chart_x_scale +
    chart_y_scale +
    chart_guides +
    chart_theme +
    chart_description +
    geom_smooth(
      aes(group = str_c(epoch, SiteName)),
      method = "lm",
      se = FALSE,
      size = I(0.75),
      show.legend = FALSE,
      formula = y ~ x + 0) +
    coord_cartesian(
      ylim = value_limits,
      clip = FALSE) # don't actually drop any data, as `limits` would do
  
  return(chart_object)
  
}

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
  width = 11,
  height = 17)
