# Section 5 experiment port. Requires --smoke or --full when run as a script.
# R RNG streams differ from Python; fixed inputs to the core can be compared
# directly, while simulation rejection rates agree statistically.
.reproduction_file <- tryCatch(sys.frame(1L)$ofile, error = function(e) NULL)
if (is.null(.reproduction_file)) {
  .reproduction_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (!length(.reproduction_argument)) stop("Run with Rscript or source this file.", call. = FALSE)
  .reproduction_file <- sub("^--file=", "", .reproduction_argument[1L])
}
.reproduction_dir <- dirname(normalizePath(.reproduction_file, mustWork = TRUE))
.reproduction_project <- dirname(dirname(.reproduction_dir))
sys.source(file.path(.reproduction_project, "examples", "bootstrap.R"), envir = environment())
load_meancontest(.reproduction_project, envir = environment())
load_example_helpers(.reproduction_project, envir = environment())
for (.reproduction_helper in c("test_constants", "test_utilities", "plot")) {
  source(file.path(.reproduction_dir, paste0(.reproduction_helper, ".R")), local = environment())
}

testing_wrapper <- function(testing_obj, n_sam, dim_full, cr_rate, norm,
                            constr_type, config, utilities_obj = Utilities()) {
  sides <- axes <- NULL
  if (is.null(constr_type)) {
    mu_alt <- get_none_vec(dim_full, norm)
  } else if (constr_type == "hr") {
    sides <- get_default_sides(dim_full, config$SIGMA)
    dim_opt <- utilities_obj$get_hr_opt_dim(sides / config$SIGMA, n_sam, cr_rate)$dim_opt
    mu_alt <- get_hr_vec(sides, dim_opt, norm)
  } else {
    axes <- get_default_axes(dim_full, config$SIGMA)
    dim_opt <- utilities_obj$get_ep_opt_dim(axes / config$SIGMA, n_sam, cr_rate)$dim_opt
    mu_alt <- get_ep_vec(axes, dim_opt, norm)
  }
  if (config$VERBOSE) message("Mean vector: ", paste(signif(mu_alt, 4), collapse = ", "))
  reject_count <- 0L
  for (iteration in seq_len(config$DEFAULT_N_LOOP_2)) {
    raw <- gen_data(n_sam, mu_alt, dim_full, config$SIGMA)
    adversary <- Adversary(raw, cr_rate, "alter", mu_alt, config$SIGMA,
                          constr_type = constr_type, strategy_flag = config$FLAG_ADV,
                          sides = sides, axes = axes)
    testing_obj$clear()
    testing_obj$change_constants(c("_VERBOSE"), list(config$VERBOSE))
    testing_obj$data_load(adversary$adversary_agent(), cr_rate,
                          err_th = config$ERR_TH, sigma = config$SIGMA,
                          constr_type = constr_type, sides = sides, axes = axes)
    if (identical(testing_obj$testing(), "Reject")) reject_count <- reject_count + 1L
  }
  reject_count / config$DEFAULT_N_LOOP_2
}

linear_scan <- function(config, save_dir) {
  config <- check_reproduction_configuration(config)
  dir.create(save_dir, recursive = TRUE, showWarnings = FALSE)
  set.seed(config$SEED)
  tester <- ConTest()
  utility <- Utilities()
  norms <- seq(config$DEFAULT_LOWER, config$DEFAULT_UPPER,
               length.out = config$DEFAULT_N_LOOP_1)
  files <- character()
  for (n_sam in config$N_SAM_LIST) {
    reject_array <- array(0, dim = c(length(config$DIM_FULL_LIST),
                                   length(config$CR_RATE_LIST), length(norms) + 2L))
    rows <- list()
    for (i in seq_along(config$DIM_FULL_LIST)) {
      dim_full <- config$DIM_FULL_LIST[i]
      for (j in seq_along(config$CR_RATE_LIST)) {
        cr_rate <- config$CR_RATE_LIST[j]
        message(sprintf("%s: n=%d, dimension=%d, corruption=%.3f, repetitions=%d",
                        config$SCENARIO, n_sam, dim_full, cr_rate, config$DEFAULT_N_LOOP_2))
        reject_array[i, j, 1:2] <- c(config$DEFAULT_LOWER, config$DEFAULT_UPPER)
        skip_count <- 0L
        for (k in seq_along(norms)) {
          if (skip_count >= 3L) {
            reject_array[i, j, (k + 2L):(length(norms) + 2L)] <- 1
            break
          }
          rate <- testing_wrapper(tester, n_sam, dim_full, cr_rate, norms[k],
                                  config$CONSTR_TYPE, config, utility)
          reject_array[i, j, k + 2L] <- rate
          skip_count <- if (rate >= 1 - 1e-7) skip_count + 1L else 0L
        }
        rows[[length(rows) + 1L]] <- data.frame(
          n_sam = n_sam, dim_full = dim_full, cr_rate = cr_rate,
          norm = norms, reject_rate = reject_array[i, j, -(1:2)])
      }
    }
    stem <- file.path(save_dir, paste0("reject_array_n_sample_", n_sam))
    saveRDS(reject_array, paste0(stem, ".rds"))
    utils::write.csv(do.call(rbind, rows), paste0(stem, ".csv"), row.names = FALSE)
    saveRDS(config, paste0(stem, "_configuration.rds"))
    files <- c(files, paste0(stem, ".rds"), paste0(stem, ".csv"))
  }
  if (config$FLAG_PLOT) plot_rejection_results(config, save_dir, output_dir = save_dir)
  invisible(files)
}

run_reproduction <- function(full = FALSE, plot = TRUE,
                             save_dir = file.path(.reproduction_dir, "results",
                                                  if (full) "generated" else "smoke")) {
  configs <- if (full) list(class_scenario(), high_dim_scenario()) else
    list(smoke_scenario("classic"), smoke_scenario("high_dimensional"))
  files <- character()
  for (config in configs) {
    config$FLAG_PLOT <- plot
    files <- c(files, linear_scan(config, save_dir))
  }
  message("Results saved to: ", normalizePath(save_dir, mustWork = TRUE))
  invisible(files)
}

if (sys.nframe() == 0L) {
  .reproduction_options <- commandArgs(trailingOnly = TRUE)
  if (!any(.reproduction_options %in% c("--smoke", "--full"))) {
    stop(paste("Choose --smoke for a short verification or --full for the paper grid.",
               "Usage: Rscript tests/reproduction/reproduce_paper.R --smoke|--full",
               "[--no-plot] [--save-dir=directory]"), call. = FALSE)
  }
  .known_options <- .reproduction_options %in% c("--smoke", "--full", "--no-plot") |
    grepl("^--save-dir=.+", .reproduction_options)
  if (any(!.known_options) || all(c("--smoke", "--full") %in% .reproduction_options)) {
    stop("Invalid options; choose either --smoke or --full.", call. = FALSE)
  }
  .full <- "--full" %in% .reproduction_options
  .output_option <- grep("^--save-dir=", .reproduction_options, value = TRUE)
  .output <- if (length(.output_option)) sub("^--save-dir=", "", .output_option[1L]) else
    file.path(.reproduction_dir, "results", if (.full) "generated" else "smoke")
  run_reproduction(full = .full, plot = !"--no-plot" %in% .reproduction_options, save_dir = .output)
}
