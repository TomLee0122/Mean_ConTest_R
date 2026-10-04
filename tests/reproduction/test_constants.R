# Configuration functions for Section 5 experiments. No experiment or RNG seed
# is run merely by sourcing this file.
reproduction_configuration <- function() {
  list(DEFAULT_LOWER = 0, DEFAULT_UPPER = 1.2,
       DEFAULT_N_LOOP_1 = 50L, DEFAULT_N_LOOP_2 = 200L,
       N_SAM_LIST = 1000L, DIM_FULL_LIST = 10L, SIGMA = 1,
       CR_RATE_LIST = 0.01, ERR_TH = 0.05, FLAG_ADV = 3L, SEED = 42L,
       CONSTR_TYPE = NULL, VERBOSE = FALSE, FLAG_PLOT = FALSE,
       SCENARIO = "custom")
}

check_reproduction_configuration <- function(config) {
  positive_integers <- function(value) is.numeric(value) && length(value) > 0L &&
    all(is.finite(value)) && all(value > 0) && all(value == floor(value))
  finite_scalar <- function(value) is.numeric(value) && length(value) == 1L && is.finite(value)
  if (!finite_scalar(config$DEFAULT_LOWER) || config$DEFAULT_LOWER < 0 ||
      !finite_scalar(config$DEFAULT_UPPER) || config$DEFAULT_UPPER <= config$DEFAULT_LOWER) {
    stop("Norm bounds must satisfy 0 <= DEFAULT_LOWER < DEFAULT_UPPER.", call. = FALSE)
  }
  for (name in c("DEFAULT_N_LOOP_1", "DEFAULT_N_LOOP_2", "N_SAM_LIST", "DIM_FULL_LIST")) {
    if (!positive_integers(config[[name]]) ||
        (name %in% c("DEFAULT_N_LOOP_1", "DEFAULT_N_LOOP_2") && length(config[[name]]) != 1L)) {
      stop(paste(name, "must contain positive integers."), call. = FALSE)
    }
  }
  if (!is.numeric(config$CR_RATE_LIST) || length(config$CR_RATE_LIST) < 1L ||
      any(!is.finite(config$CR_RATE_LIST)) || any(config$CR_RATE_LIST < 0 | config$CR_RATE_LIST >= 1 / 6)) {
    stop("CR_RATE_LIST must contain corruption rates in [0, 1/6).", call. = FALSE)
  }
  if (!finite_scalar(config$SIGMA) || config$SIGMA <= 0) stop("SIGMA must be positive.", call. = FALSE)
  if (!finite_scalar(config$ERR_TH) || config$ERR_TH <= 0 || config$ERR_TH >= 0.2) {
    stop("ERR_TH must be in (0, 0.2).", call. = FALSE)
  }
  if (!finite_scalar(config$SEED) || config$SEED < 0 || config$SEED != floor(config$SEED) ||
      config$SEED > .Machine$integer.max) stop("SEED must be a non-negative R integer.", call. = FALSE)
  if (!is.null(config$CONSTR_TYPE) &&
      !(is.character(config$CONSTR_TYPE) && length(config$CONSTR_TYPE) == 1L &&
        config$CONSTR_TYPE %in% c("hr", "ep"))) {
    stop("CONSTR_TYPE must be NULL, 'hr', or 'ep'.", call. = FALSE)
  }
  if (length(config$FLAG_ADV) != 1L || !config$FLAG_ADV %in% 1:4) {
    warning("Invalid FLAG_ADV; using strategy 1.", call. = FALSE)
    config$FLAG_ADV <- 1L
  }
  config
}

class_scenario <- function() {
  config <- reproduction_configuration()
  config$N_SAM_LIST <- c(200L, 2000L)
  config$DIM_FULL_LIST <- c(5L, 10L, 20L, 50L)
  config$CR_RATE_LIST <- c(0.01, 0.015, 0.02, 0.025)
  config$CONSTR_TYPE <- "ep"
  config$SCENARIO <- "classic"
  check_reproduction_configuration(config)
}

high_dim_scenario <- function() {
  config <- class_scenario()
  config$N_SAM_LIST <- c(100L, 500L)
  config$DIM_FULL_LIST <- c(100L, 500L)
  config$SCENARIO <- "high_dimensional"
  check_reproduction_configuration(config)
}

smoke_scenario <- function(scenario = c("classic", "high_dimensional")) {
  scenario <- match.arg(scenario)
  config <- if (scenario == "classic") class_scenario() else high_dim_scenario()
  config$N_SAM_LIST <- if (scenario == "classic") 80L else 60L
  config$DIM_FULL_LIST <- if (scenario == "classic") 3L else 12L
  config$CR_RATE_LIST <- c(0.01, 0.02)
  config$DEFAULT_N_LOOP_1 <- 3L
  config$DEFAULT_N_LOOP_2 <- 2L
  check_reproduction_configuration(config)
}
