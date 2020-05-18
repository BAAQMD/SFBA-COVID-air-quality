source(here::here("code", "chart-helpers.R"))
source(here::here("code", "tidy_1h_data.R"))
source(here::here("code", "with_epoch.R"))

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
