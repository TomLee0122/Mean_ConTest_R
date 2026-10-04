# Base R ports of the paper's classical and high-dimensional plot functions.
.plot_file <- tryCatch(sys.frame(1L)$ofile, error = function(e) NULL)
if (is.null(.plot_file)) {
  .plot_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (!length(.plot_argument)) stop("Run with Rscript or source this file.", call. = FALSE)
  .plot_file <- sub("^--file=", "", .plot_argument[1L])
}
.plot_dir <- dirname(normalizePath(.plot_file, mustWork = TRUE))
sys.source(file.path(.plot_dir, "test_constants.R"), envir = environment())

read_rejection_results <- function(n_sam, config, save_dir) {
  stem <- file.path(save_dir, paste0("reject_array_n_sample_", n_sam))
  if (file.exists(paste0(stem, ".rds"))) {
    result <- readRDS(paste0(stem, ".rds"))
    if (length(dim(result)) != 3L || dim(result)[1L] != length(config$DIM_FULL_LIST) ||
        dim(result)[2L] != length(config$CR_RATE_LIST) || dim(result)[3L] < 3L) {
      stop("Saved result dimensions do not match the requested scenario.", call. = FALSE)
    }
    rows <- list()
    for (i in seq_along(config$DIM_FULL_LIST)) {
      for (j in seq_along(config$CR_RATE_LIST)) {
        rows[[length(rows) + 1L]] <- data.frame(
          n_sam = n_sam, dim_full = config$DIM_FULL_LIST[i], cr_rate = config$CR_RATE_LIST[j],
          norm = seq(result[i, j, 1L], result[i, j, 2L], length.out = dim(result)[3L] - 2L),
          reject_rate = result[i, j, -(1:2)])
      }
    }
    return(do.call(rbind, rows))
  }
  path <- paste0(stem, ".csv")
  if (!file.exists(path)) stop(paste("Missing results:", path), call. = FALSE)
  result <- read.csv(path, check.names = FALSE)
  required <- c("n_sam", "dim_full", "cr_rate", "norm", "reject_rate")
  if (!all(required %in% names(result)) || any(!vapply(result[required], is.numeric, logical(1L)))) {
    stop("Result CSV must have numeric n_sam, dim_full, cr_rate, norm, reject_rate columns.", call. = FALSE)
  }
  result
}

plot_rejection_results <- function(config, save_dir = file.path(.plot_dir, "results"),
                                   output_dir = file.path(save_dir, "plots")) {
  config <- check_reproduction_configuration(config)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  outputs <- character()
  for (n_sam in config$N_SAM_LIST) {
    result <- read_rejection_results(n_sam, config, save_dir)
    n_panels <- length(config$DIM_FULL_LIST)
    n_cols <- min(2L, n_panels)
    n_rows <- ceiling(n_panels / n_cols)
    path <- file.path(output_dir, paste0(config$SCENARIO, "_N_", n_sam, ".pdf"))
    grDevices::pdf(path, width = 6 * n_cols, height = 5 * n_rows)
    tryCatch({
      graphics::par(mfrow = c(n_rows, n_cols), mar = c(4.5, 4.5, 3, 1), oma = c(0, 0, 3, 0))
      colors <- grDevices::hcl.colors(length(config$CR_RATE_LIST), palette = "Dark 3")
      for (dim_full in config$DIM_FULL_LIST) {
        panel <- result[result$dim_full == dim_full & result$n_sam == n_sam, , drop = FALSE]
        if (!nrow(panel)) stop(paste("No results for dimension", dim_full), call. = FALSE)
        graphics::plot(range(panel$norm), c(0, 1), type = "n", xlab = "Norm of mean",
                       ylab = "Correct rate", main = paste("Full dimension =", dim_full))
        graphics::grid()
        for (j in seq_along(config$CR_RATE_LIST)) {
          curve <- panel[abs(panel$cr_rate - config$CR_RATE_LIST[j]) < 1e-12, , drop = FALSE]
          if (!nrow(curve)) stop(paste("No results for corruption rate", config$CR_RATE_LIST[j]), call. = FALSE)
          curve <- curve[order(curve$norm), , drop = FALSE]
          graphics::lines(curve$norm, curve$reject_rate, type = "b", pch = 16,
                          lty = 2, lwd = 2, col = colors[j])
        }
        graphics::abline(h = 0.95, lty = 2, lwd = 1.5)
        graphics::legend("bottomright", c(paste("Corruption rate =", config$CR_RATE_LIST),
                                          "95% Correct Rate Threshold"),
                         col = c(colors, "black"), lty = 2,
                         pch = c(rep(16, length(colors)), NA), cex = 0.8, bty = "n")
      }
      if (n_rows * n_cols > n_panels) graphics::plot.new()
      title <- if (config$SCENARIO == "classic") "Classical case" else "High-dimensional case"
      graphics::mtext(paste0(title, ", N=", n_sam), outer = TRUE, font = 2, cex = 1.3)
    }, finally = grDevices::dev.off())
    outputs <- c(outputs, path)
  }
  invisible(outputs)
}

plot_results_classic <- function(save_dir = file.path(.plot_dir, "results"),
                                 output_dir = file.path(save_dir, "plots")) {
  plot_rejection_results(class_scenario(), save_dir, output_dir)
}

plot_results_high_dim <- function(save_dir = file.path(.plot_dir, "results"),
                                  output_dir = file.path(save_dir, "plots")) {
  plot_rejection_results(high_dim_scenario(), save_dir, output_dir)
}

if (sys.nframe() == 0L) {
  options <- commandArgs(trailingOnly = TRUE)
  if (length(options) > 2L) stop("Usage: Rscript tests/reproduction/plot.R [results-directory] [output-directory]", call. = FALSE)
  save_dir <- if (length(options)) options[1L] else file.path(.plot_dir, "results")
  output_dir <- if (length(options) > 1L) options[2L] else file.path(save_dir, "plots")
  plot_results_classic(save_dir, output_dir)
  plot_results_high_dim(save_dir, output_dir)
}
