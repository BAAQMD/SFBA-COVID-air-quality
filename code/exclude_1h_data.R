exclude_1h_data <- function (
  input_data,
  blacklist
) {
  
  warning(
    "Excluding data from `blacklist`")
  
  blacklist_set <-
    mutate(
      blacklist,
      dttm = map2(
        .f = seq,
        .x = dttm_from,
        .y = dttm_to,
        by = dhours(1))) %>%
    select(
      -dttm_from,
      -dttm_to) %>%
    unnest_longer(
      col = c(dttm = dttm))
  
  anti_join(
    input_data,
    blacklist_set,
    by = names(blacklist_set))
  
}
