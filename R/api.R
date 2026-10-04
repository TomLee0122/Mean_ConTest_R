#' Construct a robust constrained mean testing object
#'
#' The methods and argument names mirror the Python \code{ConTest} API.
#' @return An environment with \code{data_load}, \code{testing}, \code{clear},
#'   and \code{change_constants} methods, plus the loaded configuration.
#' @export
ConTest <- function() {
  obj <- new.env(parent = emptyenv())
  obj$parameter_names <- c("data", "n_sam", "dim_full", "cr_rate", "err_th",
                           "constr_type", "sides", "axes", "dim_opt", "proj_oper",
                           "sigma", "max_tolerance_float", "max_tolerance_prob",
                           "file_log", "log_dir", "__configured")
  obj$used_classes <- c("utilities", "sub_algorithms")

  obj$clear <- function() {
    for (name in c(obj$parameter_names, obj$used_classes)) obj[[name]] <- NULL
    obj[["__configured"]] <- FALSE
    invisible(NULL)
  }

  obj$change_constants <- function(names, values) {
    if (!is.character(names) || anyNA(names)) {
      stop("names must be a character vector of testing constant names.", call. = FALSE)
    }
    if (!(is.list(values) || is.atomic(values)) || length(names) != length(values)) {
      stop("The lengths of names and values must be the same.", call. = FALSE)
    }
    for (i in seq_along(names)) .validate_constant(names[i], values[[i]])
    for (i in seq_along(names)) .contest_settings[[names[i]]] <- values[[i]]
    invisible(NULL)
  }

  obj$data_load <- function(data, cr_rate, err_th = NULL, sigma = NULL,
                            constr_type = NULL, sides = NULL, axes = NULL,
                            dim_opt = NULL, proj_oper = NULL,
                            max_tolerance_float = NULL, max_tolerance_prob = NULL) {
    # Build and validate a separate configuration before changing this object.
    # A failed reload leaves the previous complete configuration usable.
    settings <- contest_constants()
    data <- .observation_matrix(data)
    n_sam <- nrow(data)
    dim_full <- ncol(data)
    .scalar(cr_rate, "cr_rate", lower = 0, upper = 1 / 6)
    if (is.null(err_th)) err_th <- settings$DEFAULT_ERR_TH
    .scalar(err_th, "err_th", lower = 0, upper = 0.2,
            lower_open = TRUE, upper_open = TRUE)
    if (is.null(sigma)) sigma <- settings$DEFAULT_SIGMA
    .scalar(sigma, "sigma", lower = 0, lower_open = TRUE)
    if (is.null(max_tolerance_float)) max_tolerance_float <- settings$DEFAULT_TOLERANCE_FLOAT
    if (is.null(max_tolerance_prob)) max_tolerance_prob <- settings$DEFAULT_TOLERANCE_PROB
    util <- Utilities(max_tolerance_float, max_tolerance_prob)
    sub <- SubAlgorithms(util, max_tolerance_float, max_tolerance_prob)
    if (!is.null(constr_type) &&
        (!is.character(constr_type) || length(constr_type) != 1L ||
         is.na(constr_type) || !constr_type %in% c("hr", "ep", "others"))) {
      stop("constr_type must be NULL, 'hr', 'ep', or 'others'.", call. = FALSE)
    }
    if (!is.null(sides)) {
      if (!identical(constr_type, "hr")) {
        warning("sides is specified but constr_type is not 'hr'; sides is ignored.", call. = FALSE)
        sides <- NULL
      } else {
        sides <- abs(.numeric_vector(sides, "sides", dim_full)) / sigma
      }
    }
    if (!is.null(axes)) {
      if (!identical(constr_type, "ep")) {
        warning("axes is specified but constr_type is not 'ep'; axes is ignored.", call. = FALSE)
        axes <- NULL
      } else {
        axes <- abs(.numeric_vector(axes, "axes", dim_full)) / sigma
      }
    }
    if (identical(constr_type, "hr") || identical(constr_type, "ep")) {
      if (!is.null(dim_opt)) {
        warning("dim_opt is determined from the constraint; the input is ignored.", call. = FALSE)
      }
      if (!is.null(proj_oper)) {
        warning("proj_oper is determined from the constraint; the input is ignored.", call. = FALSE)
      }
      if (identical(constr_type, "hr")) {
        if (is.null(sides)) stop("sides is required for constr_type = 'hr'.", call. = FALSE)
        optimal <- util$get_hr_opt_dim(sides, n_sam, cr_rate)
      } else {
        if (is.null(axes)) stop("axes is required for constr_type = 'ep'.", call. = FALSE)
        optimal <- util$get_ep_opt_dim(axes, n_sam, cr_rate)
      }
      dim_opt <- optimal$dim_opt
      proj_oper <- optimal$proj_oper
    } else if (is.null(constr_type)) {
      if (!is.null(dim_opt) || !is.null(proj_oper)) {
        warning("dim_opt and proj_oper are determined automatically; the inputs are ignored.", call. = FALSE)
      }
      dim_opt <- dim_full
      proj_oper <- diag(dim_full)
    } else {
      if (is.null(dim_opt) || is.null(proj_oper)) {
        stop("For constr_type = 'others', dim_opt and proj_oper are required.", call. = FALSE)
      }
      .scalar(dim_opt, "dim_opt", lower = 1, upper = dim_full, integer = TRUE)
      proj_oper <- .observation_matrix(proj_oper, "proj_oper")
      if (!identical(dim(proj_oper), c(dim_full, dim_full))) {
        stop("proj_oper must be square with the same dimension as the data.", call. = FALSE)
      }
    }
    data <- data / sigma
    if (any(!is.finite(data)) || (!is.null(sides) && any(!is.finite(sides))) ||
        (!is.null(axes) && any(!is.finite(axes)))) {
      stop("Normalization by sigma overflowed; check the input scale.", call. = FALSE)
    }
    configuration <- list(data = data, n_sam = n_sam, dim_full = dim_full,
                          cr_rate = cr_rate, err_th = err_th, sigma = sigma,
                          constr_type = constr_type, sides = sides, axes = axes,
                          dim_opt = dim_opt, proj_oper = proj_oper,
                          max_tolerance_float = max_tolerance_float,
                          max_tolerance_prob = max_tolerance_prob,
                          utilities = util, sub_algorithms = sub)
    for (name in names(configuration)) obj[[name]] <- configuration[[name]]
    obj[["__configured"]] <- TRUE
    invisible(NULL)
  }

  obj$testing <- function() {
    if (!isTRUE(obj[["__configured"]])) {
      stop("The testing procedure is not configured; run data_load first.", call. = FALSE)
    }
    if (obj$dim_opt == 0) {
      warning("The optimal dimension is zero; testing is not applicable.", call. = FALSE)
      return(NULL)
    }
    settings <- contest_constants()
    log_info <- function(...) {
      if (isTRUE(settings[["_VERBOSE"]])) message(...)
    }
    log_info("The optimal dimension is ", obj$dim_opt, ".")

    # numpy.linalg.eig preserves coordinates for diagonal projections. Preserve
    # the same basis directly instead of R's eigenvalue sorting for that case.
    op <- obj$proj_oper
    if (all(op == diag(diag(op), nrow = obj$dim_full))) {
      eig_values <- diag(op)
      eig_vectors <- diag(obj$dim_full)
    } else {
      eig <- eigen(op, symmetric = FALSE)
      if (is.complex(eig$values) || is.complex(eig$vectors)) {
        stop("proj_oper must have a real projection eigendecomposition.", call. = FALSE)
      }
      eig_values <- eig$values
      eig_vectors <- eig$vectors
    }
    mask <- abs(eig_values) >= obj$max_tolerance_float
    if (sum(mask) != obj$dim_opt) {
      stop("The projection's nonzero eigenvalue count does not match dim_opt.", call. = FALSE)
    }
    if (!all(eig_values[mask] >= 1 - obj$max_tolerance_float &
             eig_values[mask] <= 1 + obj$max_tolerance_float)) {
      stop("proj_oper is not a projection matrix.", call. = FALSE)
    }

    gm_1 <- settings$C_1 * sqrt(obj$dim_opt * log(obj$n_sam / obj$err_th)) +
      log(obj$n_sam / obj$err_th)
    correction <- 0
    if (obj$cr_rate >= obj$max_tolerance_float) {
      correction <- obj$cr_rate * obj$n_sam * log(1 / obj$cr_rate)
    }
    gm_2 <- settings$C_2_1 * (sqrt(obj$n_sam * obj$dim_opt) +
      sqrt(obj$n_sam * log(1 / obj$err_th)) + log(1 / obj$err_th) + correction)
    gm_3 <- settings$C_2_2 * (sqrt(obj$n_sam * obj$dim_opt) +
      sqrt(obj$dim_opt * log(1 / obj$err_th)) + log(1 / obj$err_th) + correction)
    log_info("The constant gamma_1 is set to be ", gm_1, ".")
    log_info("The constant gamma_2 is set to be ", gm_2, ".")
    log_info("The constant gamma_3 is set to be ", gm_3, ".")

    proj_obs <- obj$data %*% t(op) %*% eig_vectors[, mask, drop = FALSE]
    proj_obs <- obj$sub_algorithms$prefiltering(obj$cr_rate, proj_obs, obj$dim_opt, gm_1)
    if (is.null(proj_obs)) {
      log_info("The null hypothesis is rejected at the prefiltering step.")
      return("Reject")
    }
    # Keep fractional downweights throughout the filtering pipeline.
    omega <- rep(1, obj$n_sam)
    if (obj$n_sam > obj$dim_opt) {
      omega <- obj$sub_algorithms$sample_filtering_1(
        2 * obj$cr_rate, proj_obs, obj$dim_opt, gm_2, omega)
    } else {
      omega <- obj$sub_algorithms$sample_filtering_2(
        2 * obj$cr_rate, proj_obs, obj$dim_opt, gm_3, omega)
    }
    if (is.null(omega)) {
      log_info("The null hypothesis is rejected at the sample filtering step.")
      return("Reject")
    }
    omega <- obj$sub_algorithms$weight_filtering(2 * obj$cr_rate, proj_obs,
                                                obj$dim_opt, omega)
    result <- obj$sub_algorithms$final_test(obj$cr_rate, obj$err_th, proj_obs,
                                           obj$dim_opt, omega,
                                           settings$C_0_1, settings$C_P_1)
    if (result == "Reject") log_info("The null hypothesis is rejected in the final test.")
    result
  }
  obj$clear()
  class(obj) <- "ConTest"
  obj
}

#' @export
print.ConTest <- function(x, ...) {
  if (isTRUE(x[["__configured"]])) {
    cat(sprintf("ConTest: %s observations, %s dimensions, optimal dimension %s\n",
                x$n_sam, x$dim_full, x$dim_opt))
  } else {
    cat("ConTest: unconfigured\n")
  }
  invisible(x)
}
