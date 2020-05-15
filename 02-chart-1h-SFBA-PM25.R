source(here::here("code", "tidy_1h_data.R"))

#'
#' TODO: Expand `value_vars` beyond just "PM25".
#' 
chart_vars <- 
  tidyselect::vars_select(
    names(SFBA_1h_data),
    PM25)

chart_data <-
  SFBA_1h_data %>%
  tidy_1h_data(
    value_vars = chart_vars,
    na.rm = TRUE) %>%
  with_epoch(
    na.rm = TRUE)

chart_y_limits <- c(
  5 * floor(min(0, with(chart_data, min(value, na.rm = TRUE))) / 5),
  35)

chart_description <- 
  ggplot2::labs(
    title = "Bay Area Monitoring Data (PM2.5, Hourly)",
    subtitle = glue(
      "Source: AirNowTech.",
      "Points jittered to reduce overplotting.",
      "Y-axis clipped at {max(chart_y_limits)}, but no data are dropped when calculating group means.",
      .sep = "\n"),
    caption = glue("DRAFT {format(Sys.Date(), '%Y-%m-%d')}"))

chart_x_scale <-
  scale_x_datetime(
    name = str_remove(
      lubridate::tz(pull(chart_data, dttm)),
      fixed("Etc/")),
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
    #scales = "free_y",
    repeat.tick.labels = "y",
    ncol = 3)

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
  scale_color_excel_new() +
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
    ylim = chart_y_limits,
    clip = FALSE) # don't actually drop any data, as `limits` would do

show(chart_object)

ggplot2::ggsave(
  here::here("figures", "chart-1h-SFBA-PM25.pdf"),
  chart_object,
  width = 11,
  height = 17)
