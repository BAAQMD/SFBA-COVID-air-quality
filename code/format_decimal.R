format_decimal <- function (x, digits, ...) {
  
  formatted <- 
    formatC(
      x,
      digits = digits, 
      ...,
      format = "g", 
      flag = "#", drop0trailing = FALSE)
  
  trimmed <- 
    stringr::str_remove(
      formatted,
      "\\.$")
  
  return(trimmed)
  
}
