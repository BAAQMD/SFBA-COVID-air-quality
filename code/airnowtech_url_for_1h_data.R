#'
#' To construct the URL for a particular hour's worth of data.
#'
#' AirNowTech hosts CSV-formatted files on Amazon S3. They all have the
#' extension ".dat", for some reason. Each file contains one hour's worth
#' of monitoring data, from all sites across the United States.
#' 
airnowtech_url_for_1h_data <- function (dttm) {
  glue::glue(
    "https://s3-us-west-1.amazonaws.com/",
    "files.airnowtech.org/airnow/",
    "{format(dttm, '%Y')}/",
    "{format(dttm, '%Y%m%d')}/",
    "HourlyAQObs_{format(dttm, '%Y%m%d%H')}.dat")
}
