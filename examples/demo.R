# Run: Rscript examples/demo.R [--full]
# The default is a small demonstration. --full uses the two Python profiles.
.demo_file <- tryCatch(sys.frame(1L)$ofile, error = function(e) NULL)
if (is.null(.demo_file)) {
  .demo_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (!length(.demo_argument)) stop("Run with Rscript or source this file.", call. = FALSE)
  .demo_file <- sub("^--file=", "", .demo_argument[1L])
}
.demo_project <- dirname(dirname(normalizePath(.demo_file, mustWork = TRUE)))
sys.source(file.path(.demo_project, "examples", "bootstrap.R"), envir = environment())
load_meancontest(.demo_project, envir = environment())
load_example_helpers(.demo_project, envir = environment())

prepare_demo_data <- function(config) {
  config <- check_demo_configuration(config)
  sides <- axes <- NULL
  if (identical(config$CONSTR_TYPE, "hr")) {
    sides <- if (is.null(config$SIDES)) get_default_sides(config$DIM_FULL, config$SIGMA) else config$SIDES
  } else if (identical(config$CONSTR_TYPE, "ep")) {
    axes <- if (is.null(config$AXES)) get_default_axes(config$DIM_FULL, config$SIGMA) else config$AXES
  }
  if (config$ALT_TYPE == "null") {
    mu_alt <- numeric(config$DIM_FULL)
  } else if (!is.null(config$MU_ALT)) {
    mu_alt <- config$MU_ALT
  } else if (is.null(config$CONSTR_TYPE)) {
    mu_alt <- gen_default_mu_alt(config$DIM_FULL, config$SIGMA)
  } else if (identical(config$CONSTR_TYPE, "hr")) {
    mu_alt <- gen_mu_alt_hr(sides)
  } else if (identical(config$CONSTR_TYPE, "ep")) {
    mu_alt <- gen_mu_alt_ep(axes)
  } else {
    mu_alt <- do.call(config$CONSTR_TYPE, c(config$ARGS, config$KWARGS))
  }
  raw <- gen_data(config$N_SAM, mu_alt, config$DIM_FULL, config$SIGMA)
  adversary <- Adversary(raw, config$CR_RATE, config$ALT_TYPE, mu_alt, config$SIGMA,
                        constr_type = config$CONSTR_TYPE, strategy_flag = config$FLAG_ADV,
                        mu_alt_adv = config$MU_ALT_ADV, sides = sides, axes = axes)
  list(data = adversary$adversary_agent(), sides = sides, axes = axes, mu_alt = mu_alt)
}

run_demo <- function(full = FALSE) {
  configs <- list(default_configuration_1(), default_configuration_2())
  if (!full) {
    configs[[1L]]$N_SAM <- 200L
    configs[[1L]]$DIM_FULL <- 5L
    configs[[2L]]$N_SAM <- 250L
    configs[[2L]]$DIM_FULL <- 5L
  }
  tester <- ConTest()
  outcomes <- character(length(configs))
  for (i in seq_along(configs)) {
    config <- configs[[i]]
    set.seed(config$SEED)
    simulated <- prepare_demo_data(config)
    tester$clear()
    tester$change_constants(c("_VERBOSE"), list(FALSE))
    tester$data_load(simulated$data, config$CR_RATE, err_th = config$ERR_TH,
                     sigma = config$SIGMA, constr_type = config$CONSTR_TYPE,
                     sides = simulated$sides, axes = simulated$axes)
    result <- tester$testing()
    outcomes[i] <- if (is.null(result)) "Not applicable" else result
    message(sprintf("Profile %d: n=%d, dimension=%d, hypothesis=%s, result=%s",
                    i, config$N_SAM, config$DIM_FULL, config$ALT_TYPE, outcomes[i]))
  }
  invisible(outcomes)
}

if (sys.nframe() == 0L) {
  .demo_options <- commandArgs(trailingOnly = TRUE)
  if (any(!.demo_options %in% c("--full", "--smoke"))) {
    stop("Usage: Rscript examples/demo.R [--full|--smoke]", call. = FALSE)
  }
  run_demo(full = "--full" %in% .demo_options)
}
