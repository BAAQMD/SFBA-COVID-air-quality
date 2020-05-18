source(here::here("code", "chart-helpers.R"))
source(here::here("code", "tidy_1h_data.R"))
source(here::here("code", "with_epoch.R"))

#'
#' To apply a hypothesis test to `Pre` and `Post` from `input_data`,
#' where our `input_data` is already in tidy form (i.e., having columns 
#' `epoch`, `variable`, and `value`).
#' 
#' Returns a tidied result (see `broom::tidy()`).
#'
tidy_htest <- function (
  input_data,
  htest,
  ...
) {
  if (rlang::is_empty(input_data)) return(NULL)
  data_list <- split(input_data, input_data$epoch)
  value_list <- map(data_list, pull, value) 
  quieted <- purrr::invoke(quietly(htest), unname(value_list))
  result <- pluck(quieted, "result")
  tidied <- broom::tidy(result)
  return(tidied)
}

#'
#' Summarize pre-vs-post differences in the PM2.5 data with a few 
#' convenient statistics (i.e., hypothesis tests).
#' 
#' TODO: make the statistics more pluggable.
#' 
#' FIXME: `ks.test()` is for *continuous* distributions. These ECDFs
#' are of rounded measurements --- they have been discretized. See:
#' 
#'  https://github.com/BAAQMD/SFBA-COVID-air-quality/issues/1
#'
make_htest_data <- function (
  input_data,
  value_vars = c("PM25", "NO2")
) {
  
  nested_data <-
    input_data %>%
    group_by(
      SiteName,
      variable) %>%
    nest() 
  
  summarised_data <-
    nested_data %>%
    summarise_at(
      vars(data),
      list(
        ks.test = ~ map(., tidy_htest, ks.test),
        t.test = ~ map(., tidy_htest, t.test))) %>%
    ungroup() 
  
  tidied_data <-
    summarised_data %>%
    gather(
      stat_fun,
      stat_obj,
      dplyr::matches(".test")) %>%
    mutate_at(
      vars(stat_obj),
      ~ map(., select, stat_value = statistic, stat_p_value = p.value)) %>%
    unnest(
      c(stat_obj)) %>%
    mutate(
      stat_var = recode(stat_fun, ks.test = "D", t.test = "t")) 
  
  return(tidied_data)
  
}

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
  
  format_stat <- function (stat_var, stat_value, stat_p_value) {
    stars <- if_else(stat_p_value < 0.05, "**", "  ")
    glue::glue(
      "{stat_var} = {format_decimal(stat_value, digits = 2)}{stars}")
  }
  
  label_layer <- local({
    
    label_data <-  
      chart_data %>%
      make_htest_data(
        value_vars = value_var) %>%
      group_by(
        SiteName) %>%
      summarise(
        stat_text = glue::glue_collapse(
          format_stat(stat_var, stat_value, stat_p_value),
          sep = "\n"))
    
    geom_text(
      aes(label = stat_text, x = 35, y = 0),
      vjust = -0.1,
      hjust = 1,
      size = I(3.0),
      data = label_data)
    
  })
  
  ecdf_layer <-
    geom_step(
      aes(color = epoch),
      show.legend = FALSE,
      stat = "ecdf") 
  
  chart_object <-
    chart_data %>%
    ggplot() +
    aes(x = value) +
    ecdf_layer +
    label_layer + 
    chart_color_scale +
    chart_faceting +
    chart_guides +
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
        "The Kolmogorov D statistic quantifies the area between two such curves (larger = more different).",
        "The t statistic is also shown. Both are two-sided, and do not assume equal variance.",
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

ggplot2::ggsave(
  here::here("figures", "SFBA-PM25-1h-ecdf-chart.pdf"),
  SFBA_1h_PM25_ecdf_chart_v2,
  width = 8.5,
  height = 11)
