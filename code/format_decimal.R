format_decimal <- function (x, digits) {
  formatC(
    round(x, digits = digits), 
    digits = digits, 
    format = "f", 
    flag = "#", drop0trailing = FALSE)
}
