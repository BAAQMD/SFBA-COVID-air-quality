#'
#' To make a chart of ECDFs, faceted by site, for a given `value_var`.
#'
make_ecdf_chart <- function (
  input_data,
  value_var,
  value_unit,
  value_limits = c(NA, NA),
  ...
) {
  
  chart_data <-
    input_data %>%
    tidy_1h_data(
      value_vars = value_var) %>%
    with_epoch()
  
  chart_y_breaks <-
    seq(0, 1, length.out = 3)
  
  chart_y_scale <- 
    scale_y_continuous(
      NULL,
      limits = c(0, 1),
      breaks = chart_y_breaks,
      labels = NULL, #chart_y_breaks %>% replace(-c(1, length(.)), ""),
      expand = expansion(0, 0))
  
  chart_x_title <-
    glue::glue(
      "Hourly {value_var} ({value_unit})")
  
  chart_x_scale <-
    scale_x_continuous(
      chart_x_title,
      expand = expansion(0, 0))
  
  chart_object <-
    chart_data %>%
    ggplot() +
    aes(x = value) +
    geom_step(
      aes(color = epoch),
      stat = "ecdf") +
    chart_color_scale +
    chart_faceting +
    chart_x_scale +
    chart_y_scale +
    chart_theme +
    geom_vline(
      xintercept = 0) +
    coord_cartesian(
      xlim = value_limits,
      clip = FALSE)
  
  return(chart_object)
  
}

#'
#' Use `make_ecdf_chart()` to visualize pre-vs-post distributions
#' of hourly `PM25` data, faceted by site.
#'
SFBA_1h_PM25_ecdf_chart <- local({
  
  chart_description <-
    ggplot2::labs(
      title = "Ambient PM2.5 Measurements",
      subtitle = str_c(
        "Shown here are empirical cumulative distributions for PM2.5, \"pre\" and \"post\".",
        "The Kolmogorov D statistic quantifies the area between two such curves.",
        "Larger D values correspond to larger differences.",
        sep = "\n"),
      caption = glue::glue(
        "DRAFT {format(Sys.Date(), '%Y-%m-%d')}"))
  
  filtered_data <-
    SFBA_1h_data %>%
    filter(
      dttm >= ISOdate(2020, 01, 01, hour = 00, tz = dttm_tz))
  
  SFBA_1h_PM25_ecdf_chart <-
    make_ecdf_chart(
      filtered_data,
      value_var = "PM25",
      value_limits = c(-5, 35),
      value_unit = "ug/m3") +
    chart_description
  
})

show(SFBA_1h_PM25_ecdf_chart)

#' 
#' Nest the data. This should be helpful for summarizing it.
#' 
#' TODO: use the `broom` package here.
#' 
nested_SFBA_1h_PM25_data <-
  SFBA_1h_data %>%
  tidy_1h_data(
    value_vars = "PM25") %>%
  with_epoch() %>%
  group_by(
    SiteName,
    variable) %>%
  nest() %>%
  spread(
    variable,
    data) %>%
  ungroup() %>%
  glimpse()

#'
#' To extract a two-element list (`Pre` and `Post`) from `input_data`,
#' where our `input_data` is already in tidy form (i.e., having columns 
#' `epoch`, `variable`, and `value`).
#'
pre_vs_post <- function (
  input_data,
  stat,
  ...
) {
  if (rlang::is_empty(input_data)) return(NULL)
  data_list <- split(input_data, input_data$epoch)
  value_list <- map(data_list, pull, value) 
  obj <- purrr::invoke(quietly(stat), unname(value_list))
  result <- pluck(obj, "result")
  return(result)
}

#'
#' Summarize pre-vs-post differences in the PM2.5 data with a few 
#' convenient statistics (i.e., hypothesis tests).
#'
SFBA_1h_PM25_summary_data <-
  nested_SFBA_1h_PM25_data %>%
  select(
    SiteName,
    PM25) %>%
  mutate(
    D_htest = map(PM25, pre_vs_post, stat = ks.test),
    t_htest = map(PM25, pre_vs_post, stat = t.test),
    D = map_dbl(D_htest, pluck, "statistic", .default = NA_real_)) %>%
  filter_at(
    vars(D),
    any_vars(is.finite(.)))

#'
#' Put the D-statistic onto our ECDF chart.
#' 
#' TODO: put a 95% CI for a two-sample t-test on here too.
#' 
SFBA_1h_PM25_ecdf_chart_v2 <-
  SFBA_1h_PM25_ecdf_chart +
  geom_text(
    aes(label = str_c("D = ", format_decimal(D, digits = 2)), x = 35, y = 0),
    vjust = 0,
    hjust = 1,
    size = I(3.25),
    data = PM25_summary_data)

show(SFBA_1h_PM25_ecdf_chart_v2)
