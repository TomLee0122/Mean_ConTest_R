library(meancontest)

expect_error <- function(expr, pattern = NULL) {
  result <- tryCatch(force(expr), error = identity)
  stopifnot(inherits(result, "error"))
  if (!is.null(pattern)) stopifnot(grepl(pattern, conditionMessage(result), fixed = TRUE))
  invisible(result)
}

settings <- contest_constants()
obj <- ConTest()
obj$change_constants("_VERBOSE", FALSE)
expect_error(obj$testing(), "not configured")

data <- matrix(c(0.5, -0.5, 1, -1, 0.2, -0.2, 0.6, -0.6), ncol = 2)
original_data <- data
obj$data_load(data, 0.1)
result <- obj$testing()
stopifnot(result %in% c("Accept", "Reject"))
stopifnot(identical(obj$testing(), result), identical(data, original_data))
data[1, 1] <- 100
stopifnot(identical(obj$data, original_data))

# Failed reloads retain the prior complete configuration atomically.
expect_error(obj$data_load(matrix(NA_real_, 2, 2), 0.1), "finite")
stopifnot(identical(obj$testing(), result), identical(obj$data, original_data))
obj$data_load(original_data, 0.1)
expect_error(obj$data_load(original_data, 0.2), "cr_rate")
stopifnot(identical(obj$testing(), result), obj$cr_rate == 0.1)

# Validate concrete package boundaries, including R's vector/matrix distinction.
invalid_data <- list(NULL, 1:4, matrix(numeric(), 0, 2),
                     matrix(TRUE, 2, 2), matrix(1 + 1i, 2, 2),
                     matrix(Inf, 2, 2), matrix("1", 2, 2))
for (value in invalid_data) expect_error(obj$data_load(value, 0.1))
for (rate in list(NA_real_, Inf, -0.01, 1, "0.1", c(0.1, 0.1))) {
  expect_error(obj$data_load(original_data, rate))
}
for (sigma in list(0, -1, Inf, NA_real_, "1")) {
  expect_error(obj$data_load(original_data, 0.1, sigma = sigma))
}
for (err in list(0, 0.2, Inf, NA_real_)) {
  expect_error(obj$data_load(original_data, 0.1, err_th = err))
}
expect_error(obj$data_load(original_data, 0.1, max_tolerance_float = 0))
expect_error(obj$data_load(original_data, 0.1, max_tolerance_prob = 0))
expect_error(obj$data_load(original_data, 0.1, constr_type = "invalid"))
expect_error(obj$data_load(original_data, 0.1, constr_type = "hr"), "sides")
expect_error(obj$data_load(original_data, 0.1, constr_type = "ep"), "axes")
expect_error(obj$data_load(original_data, 0.1, constr_type = "hr", sides = 1))
expect_error(obj$data_load(original_data, 0.1, constr_type = "ep", axes = c(1, NA)))
expect_error(obj$data_load(original_data, 0.1, constr_type = "others"))
expect_error(obj$data_load(original_data, 0.1, constr_type = "others",
                           dim_opt = 1.5, proj_oper = diag(2)))
expect_error(obj$data_load(original_data, 0.1, constr_type = "others",
                           dim_opt = 1, proj_oper = diag(3)))

# Shape and rank failures remain clear instead of producing recycling errors.
obj$data_load(original_data, 0.1, constr_type = "others", dim_opt = 1,
              proj_oper = diag(2))
expect_error(obj$testing(), "eigenvalue count")
obj$data_load(original_data, 0.1, constr_type = "others", dim_opt = 2,
              proj_oper = diag(c(1, 2)))
expect_error(obj$testing(), "projection matrix")

# Constant updates must be all-or-nothing and whitelist restricted.
before <- contest_constants()
expect_error(obj$change_constants(c("C_1", "missing"), c(2, 2)), "Unknown")
stopifnot(identical(contest_constants(), before))
expect_error(obj$change_constants(c("C_1", "C_2_1"), c(2, -1)))
stopifnot(identical(contest_constants(), before))
expect_error(obj$change_constants("C_1", list(NA_real_)))
expect_error(obj$change_constants("_VERBOSE", 0))
expect_error(obj$change_constants("DEFAULT_TOLERANCE_FLOAT", 0))
expect_error(obj$change_constants(c("C_1", "C_2_1"), 2))
stopifnot(identical(contest_constants(), before))
snapshot <- contest_constants()
snapshot$C_1 <- 999
stopifnot(contest_constants()$C_1 == before$C_1)

# One-column matrices and one-coordinate diagonal projections retain dimensions.
single <- matrix(c(0.5, -0.5, 1, -1), ncol = 1)
obj$data_load(single, 0)
stopifnot(identical(dim(obj$data), c(4L, 1L)), obj$dim_opt == 1)
stopifnot(obj$testing() %in% c("Accept", "Reject"))
u <- Utilities()
optimal <- u$get_ep_opt_dim(2, 10, 0)
stopifnot(identical(dim(optimal$proj_oper), c(1L, 1L)))
optimal_zero <- u$get_ep_opt_dim(0, 10, 0)
stopifnot(optimal_zero$dim_opt == 0L, identical(dim(optimal_zero$proj_oper), c(1L, 1L)))
expect_error(u$get_ep_opt_dim(c(1, NA), 10, 0))
expect_error(u$get_C_P_RAW(0, 1, 0, 0.05))

# Runtime guards are exercised with thresholds that cannot permit progress.
a <- SubAlgorithms(u)
expect_error(a$sample_filtering_1(0, matrix(3, 4, 1), 1, 1, rep(1, 4)),
             "did not update")
expect_error(a$sample_filtering_2(0.1, matrix(0, 2, 2), 2, 1e-9, rep(1e-8, 2)),
             "scores are zero")
expect_error(a$weight_filtering(0.1, single, 1, rep(-1, 4)))
expect_error(a$prefiltering(0.1, matrix(0, 2, 2), 2, 1), "zero-norm")

obj$clear()
stopifnot(is.null(obj$data), is.null(obj$utilities),
          identical(contest_constants(), before))
expect_error(obj$testing(), "not configured")

# Fractional downweighting is retained even when callers supply integer weights.
# These matrices need one filtering update; expected weights follow directly
# from their distinct squared scores rather than the implementation's helpers.
low_obs <- matrix(c(3, 2, 1.3, 0.7, -0.4, -1), ncol = 1)
high_obs <- cbind(c(3, 2, 1), matrix(0, nrow = 3, ncol = 3))
low_expected <- c(0, 5 / 9, 1 - 1.3^2 / 9, 1, 1, 1)
high_expected <- c(0, 5 / 9, 8 / 9)
low_int <- rep(1L, nrow(low_obs))
high_int <- rep(1L, nrow(high_obs))
low_weights <- a$sample_filtering_1(0.2, low_obs, 1, 4, low_int)
high_weights <- a$sample_filtering_2(0.2, high_obs, 4, 4, high_int)
stopifnot(is.double(low_weights), is.double(high_weights),
          isTRUE(all.equal(low_weights, low_expected, tolerance = 1e-12)),
          isTRUE(all.equal(high_weights, high_expected, tolerance = 1e-12)),
          identical(low_int, rep(1L, nrow(low_obs))),
          identical(high_int, rep(1L, nrow(high_obs))))
stopifnot(isTRUE(all.equal(low_weights,
                          a$sample_filtering_1(0.2, low_obs, 1, 4, as.numeric(low_int)))),
          isTRUE(all.equal(high_weights,
                          a$sample_filtering_2(0.2, high_obs, 4, 4, as.numeric(high_int)))))
stopifnot(is.double(a$sample_filtering_1(0.2, low_obs, 1, 1000, low_int)),
          is.double(a$sample_filtering_2(0.2, high_obs, 4, 1000, high_int)))

# Capture public pipeline intermediates so this regression also covers initial
# weights and the transfer of fractions through weight filtering to final_test.
capture_pipeline <- function(data, method, expected) {
  pipeline <- ConTest()
  pipeline$data_load(data, cr_rate = 0.1)
  capture <- new.env(parent = emptyenv())
  sample_method <- pipeline$sub_algorithms[[method]]
  pipeline$sub_algorithms[[method]] <- function(cr_rate, obs, dim_opt, gamma, omega) {
    capture$initial <- omega
    capture$sample <- sample_method(cr_rate, obs, dim_opt, gamma, omega)
    capture$sample
  }
  final_method <- pipeline$sub_algorithms$final_test
  pipeline$sub_algorithms$final_test <- function(...) {
    capture$final <- list(...)[[5L]]
    final_method(...)
  }
  result <- pipeline$testing()
  stopifnot(result %in% c("Accept", "Reject"), is.double(capture$initial),
            is.double(capture$sample), is.double(capture$final),
            isTRUE(all.equal(capture$sample, expected, tolerance = 1e-12)),
            any(capture$sample > 0 & capture$sample < 1),
            any(capture$final > 0 & capture$final < 1),
            identical(pipeline$testing(), result))
}
obj$change_constants(c("C_2_1", "C_2_2"), c(0.4, 0.4))
capture_pipeline(low_obs, "sample_filtering_1", low_expected)
capture_pipeline(high_obs, "sample_filtering_2", high_expected)
obj$change_constants(names(settings), settings)
cat("R package boundary, fractional weight, transactional constant and runtime guard checks passed.\n")
