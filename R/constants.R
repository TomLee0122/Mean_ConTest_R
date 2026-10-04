# Thresholds deliberately match the Python implementation.
.default_constants <- list(
  DEFAULT_TOLERANCE_FLOAT = 1e-7,
  DEFAULT_TOLERANCE_PROB = 6e-3,
  DEFAULT_ERR_TH = 0.05,
  DEFAULT_SIGMA = 1,
  C_1 = 5,
  C_2_1 = 50,
  C_2_2 = 50,
  C_P_1 = 5,
  C_0_1 = 0.7,
  C_LB_1 = 5,
  "_VERBOSE" = TRUE
)
.contest_settings <- list2env(.default_constants, parent = emptyenv())

#' Return the package's current testing constants
#' @return A named list. Modifying this list does not change package settings.
#' @export
contest_constants <- function() {
  stats::setNames(lapply(names(.default_constants),
                         function(name) .contest_settings[[name]]),
                  names(.default_constants))
}

.validate_constant <- function(name, value) {
  if (!name %in% names(.default_constants)) {
    stop(sprintf("Unknown testing constant '%s'.", name), call. = FALSE)
  }
  if (name == "_VERBOSE") {
    if (!is.logical(value) || length(value) != 1L || is.na(value)) {
      stop("_VERBOSE must be TRUE or FALSE.", call. = FALSE)
    }
  } else if (name == "DEFAULT_TOLERANCE_FLOAT") {
    .scalar(value, name, lower = 0, upper = 0.01, lower_open = TRUE)
  } else if (name %in% c("DEFAULT_TOLERANCE_PROB", "DEFAULT_ERR_TH")) {
    .scalar(value, name, lower = 0, upper = 0.2,
            lower_open = TRUE, upper_open = TRUE)
  } else {
    .scalar(value, name, lower = 0, lower_open = TRUE)
  }
  invisible(value)
}
