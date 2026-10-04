# References use the original dense Python math with floating weight init fixed.
# Integer direct inputs must now match the original fractional-weight outputs.
library(meancontest)
fixture_dir <- system.file("parity", package = "meancontest")
stopifnot(nzchar(fixture_dir))
read_rows <- function(name) read.csv(file.path(fixture_dir, name), stringsAsFactors = FALSE)
vec <- function(value) as.numeric(strsplit(value, ";", fixed = TRUE)[[1L]])
read_matrix <- function(name) as.matrix(read.csv(file.path(fixture_dir, paste0(name, ".csv")), header = FALSE))
assert_close <- function(actual, expected, label) {
  if (!isTRUE(all.equal(as.numeric(actual), as.numeric(expected), tolerance = 1e-10))) {
    stop("Python/R numerical mismatch: ", label, call. = FALSE)
  }
}
u <- Utilities(1e-7, 6e-3)
algorithms <- SubAlgorithms(u, 1e-7, 6e-3)
rows <- read_rows("utilities.csv")
for (i in seq_len(nrow(rows))) {
  row <- rows[i, ]
  method <- if (row$kind == "hr") u$get_hr_opt_dim else u$get_ep_opt_dim
  out <- method(vec(row$values), row$n_sam, row$cr_rate)
  stopifnot(out$dim_opt == row$dim_opt)
  assert_close(diag(out$proj_oper), vec(row$projection), paste("projection", i))
  assert_close(u$get_C_P_RAW(row$n_sam, out$dim_opt, row$cr_rate, 0.05), row$c_p, paste("threshold", i))
}
previous <- contest_constants()[c("C_2_1", "C_2_2", "_VERBOSE")]
obj <- ConTest()
obj$change_constants("_VERBOSE", FALSE)
rows <- read_rows("pipeline.csv")
samples <- read_rows("sample_weights.csv")
for (i in seq_len(nrow(rows))) {
  row <- rows[i, ]
  data <- read_matrix(row$case)
  kind <- if (row$kind == "none") NULL else row$kind
  args <- list(data = data, cr_rate = row$cr_rate, sigma = row$sigma, constr_type = kind)
  if (row$kind %in% c("hr", "ep")) {
    args[[if (row$kind == "hr") "sides" else "axes"]] <- vec(row$values)
  }
  if (row$kind == "others") {
    args$dim_opt <- row$dim_opt
    args$proj_oper <- read_matrix(paste0(row$case, "_projection"))
  }
  obj$change_constants(c("C_2_1", "C_2_2"), c(row$c2, row$c2))
  do.call(obj$data_load, args)
  captured <- list()
  for (method in c("sample_filtering_1", "sample_filtering_2")) {
    obj$sub_algorithms[[method]] <- local({
      original <- obj$sub_algorithms[[method]]
      name <- method
      function(...) {
        out <- original(...)
        captured[[length(captured) + 1L]] <<- list(method = name, result = out)
        out
      }
    })
  }
  result <- obj$testing()
  stopifnot(obj$dim_opt == row$dim_opt)
  if (!identical(if (is.null(result)) "NULL" else result, row$result)) {
    stop("Python/R decision mismatch: ", row$case, call. = FALSE)
  }
  reference <- samples[samples$case == row$case, , drop = FALSE]
  if (nrow(reference)) {
    stopifnot(length(captured) == 1L, captured[[1L]]$method == reference$method)
    if (reference$expected == "NULL") {
      stopifnot(is.null(captured[[1L]]$result))
    } else {
      stopifnot(is.double(captured[[1L]]$result))
      assert_close(captured[[1L]]$result, vec(reference$expected), row$case)
    }
  } else {
    stopifnot(!length(captured))
  }
}
obj$change_constants(names(previous), previous)
rows <- read_rows("sub_algorithms.csv")
for (i in seq_len(nrow(rows))) {
  row <- rows[i, ]
  obs <- read_matrix(row$case)
  n <- nrow(obs)
  dim_opt <- ncol(obs)
  if (row$method == "prefiltering") {
    out <- algorithms$prefiltering(row$cr_rate, obs, dim_opt, row$gamma)
    if (is.matrix(out)) out <- as.vector(t(out))
  } else if (grepl("^sample_filtering", row$method)) {
    weights <- if (row$dtype == "int") rep(1L, n) else rep(1, n)
    out <- algorithms[[row$method]](row$cr_rate, obs, dim_opt, row$gamma, weights)
  } else if (row$method == "weight_filtering") {
    out <- algorithms$weight_filtering(row$cr_rate, obs, dim_opt, seq(0.15, 1, length.out = n))
  } else {
    out <- algorithms$final_test(row$cr_rate, 0.05, obs, dim_opt, seq(0.15, 1, length.out = n), 0.7, 5)
  }
  if (row$expected == "NULL") {
    stopifnot(is.null(out))
  } else if (row$expected %in% c("Accept", "Reject")) {
    stopifnot(identical(out, row$expected))
  } else {
    assert_close(out, vec(row$expected), paste(row$case, row$method, row$dtype, row$gamma))
    if (grepl("^sample_filtering", row$method)) stopifnot(is.double(out))
  }
}
cat("R matches 54 geometry, 14 pipeline, 24 subalgorithm and 11 intermediate weight references.\n")
