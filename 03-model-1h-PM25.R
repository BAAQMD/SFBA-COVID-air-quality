model_1h_data <-
  SFBA_1h_data %>%
  with_epoch(
    na.rm = TRUE) %>%
  exclude_1h_data(
    blacklist = SFBA_1h_blacklist) %>%
  mutate(
    elapsed = dttm - first(dttm))

PM25_linear_model <-
  stats::lm(
    PM25 ~ AQSID + epoch + elapsed, 
    data = model_1h_data)

summary(PM25_linear_model)

fit_lmer <- function (.data, formula, ...) {
  require(lme4)
  lmer_object <- lme4::lmer(formula, data = .data, ...)
  print(summary(lmer_object))
  return(invisible(lmer_object))
}

PM25_mixed_model <- 
  lme4::lmer(
    PM25 ~ epoch + (1 | SiteName) + 0,
    data = model_1h_data)

summary(PM25_mixed_model)
coef(PM25_mixed_model)
confint(PM25_mixed_model)
