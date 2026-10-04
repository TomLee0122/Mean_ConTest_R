# Demo configurations corresponding to the Python examples/constants.py.
# Sourcing this file does not seed or otherwise change the caller's RNG.
DEFAULT_MU_ALT_SOURCE <- 0.5

demo_configuration <- function() {
  list(MU_ALT = NULL, N_SAM = 1000L, DIM_FULL = 50L, SIGMA = 1,
       CR_RATE = 0.05, ERR_TH = 0.05, ALT_TYPE = "alter", CONSTR_TYPE = "hr",
       FLAG_ADV = 3L, SEED = 42L, MU_ALT_ADV = NULL, SIDES = NULL, AXES = NULL,
       ARGS = list(), KWARGS = list())
}

check_demo_configuration <- function(config) {
  integer_scalar <- function(value, positive = TRUE) {
    is.numeric(value) && length(value) == 1L && is.finite(value) &&
      value == floor(value) && (!positive || value > 0)
  }
  number <- function(value) is.numeric(value) && length(value) == 1L && is.finite(value)
  vector_ok <- function(value) is.numeric(value) && is.null(dim(value)) &&
    length(value) == config$DIM_FULL && all(is.finite(value))
  if (!integer_scalar(config$N_SAM) || !integer_scalar(config$DIM_FULL)) {
    stop("N_SAM and DIM_FULL must be positive integers.", call. = FALSE)
  }
  if (!number(config$SIGMA) || config$SIGMA <= 0) stop("SIGMA must be positive.", call. = FALSE)
  if (!number(config$CR_RATE) || config$CR_RATE < 0 || config$CR_RATE >= 1 / 6) {
    stop("CR_RATE must be in [0, 1/6).", call. = FALSE)
  }
  if (!number(config$ERR_TH) || config$ERR_TH <= 0 || config$ERR_TH >= 0.2) {
    stop("ERR_TH must be in (0, 0.2).", call. = FALSE)
  }
  if (length(config$ALT_TYPE) != 1L || !config$ALT_TYPE %in% c("alter", "null")) {
    stop("ALT_TYPE must be 'alter' or 'null'.", call. = FALSE)
  }
  if (!is.null(config$CONSTR_TYPE) && !is.function(config$CONSTR_TYPE) &&
      !(is.character(config$CONSTR_TYPE) && length(config$CONSTR_TYPE) == 1L &&
        config$CONSTR_TYPE %in% c("hr", "ep"))) {
    stop("CONSTR_TYPE must be NULL, 'hr', 'ep', or a mean-generating function.", call. = FALSE)
  }
  if (!integer_scalar(config$FLAG_ADV) || !config$FLAG_ADV %in% 1:4) {
    warning("Invalid FLAG_ADV; using strategy 1.", call. = FALSE)
    config$FLAG_ADV <- 1L
  }
  if (!integer_scalar(config$SEED, positive = FALSE) || config$SEED < 0 ||
      config$SEED > .Machine$integer.max) stop("SEED must be a non-negative R integer.", call. = FALSE)
  for (name in c("MU_ALT", "MU_ALT_ADV")) {
    if (!is.null(config[[name]]) && !vector_ok(config[[name]])) {
      stop(paste(name, "must be a finite numeric vector of length DIM_FULL."), call. = FALSE)
    }
  }
  for (name in c("SIDES", "AXES")) {
    type <- if (name == "SIDES") "hr" else "ep"
    if (!is.null(config[[name]])) {
      if (!identical(config$CONSTR_TYPE, type)) {
        warning(paste(name, "is ignored for this constraint."), call. = FALSE)
        config[name] <- list(NULL)
      } else if (!vector_ok(config[[name]])) {
        stop(paste(name, "must be a finite numeric vector of length DIM_FULL."), call. = FALSE)
      }
    }
  }
  config
}

default_configuration_1 <- function() {
  config <- demo_configuration()
  config$N_SAM <- 5000L
  config$DIM_FULL <- 20L
  config$ALT_TYPE <- "null"
  config["CONSTR_TYPE"] <- list(NULL)
  check_demo_configuration(config)
}

default_configuration_2 <- function() {
  config <- demo_configuration()
  config$N_SAM <- 10000L
  config$DIM_FULL <- 50L
  config$CR_RATE <- 0.1
  config$CONSTR_TYPE <- "ep"
  config$FLAG_ADV <- 4L
  check_demo_configuration(config)
}
