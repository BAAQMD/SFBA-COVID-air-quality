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

chart_faceting <-
  lemon::facet_rep_wrap(
    ~ SiteName, 
    repeat.tick.labels = "y",
    ncol = 3)
