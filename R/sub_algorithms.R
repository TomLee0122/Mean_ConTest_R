#' Construct the four-step testing algorithms
#' @param utilities_obj An object returned by \code{Utilities()}.
#' @param max_tolerance_float Positive floating point tolerance, at most 0.01.
#' @param max_tolerance_prob Probability tolerance, strictly between 0 and 0.2.
#' @return An environment containing the individual algorithm methods.
#' @export
SubAlgorithms <- function(utilities_obj = Utilities(),
                          max_tolerance_float = utilities_obj$max_tolerance_float,
                          max_tolerance_prob = utilities_obj$max_tolerance_prob) {
  if (!inherits(utilities_obj, "Utilities")) {
    stop("utilities_obj must be an object returned by Utilities().", call. = FALSE)
  }
  .scalar(max_tolerance_float, "max_tolerance_float", lower = 0, upper = 0.01,
          lower_open = TRUE)
  .scalar(max_tolerance_prob, "max_tolerance_prob", lower = 0, upper = 0.2,
          lower_open = TRUE, upper_open = TRUE)
  obj <- new.env(parent = emptyenv())
  obj$utilities_obj <- utilities_obj
  obj$max_tolerance_float <- max_tolerance_float
  obj$max_tolerance_prob <- max_tolerance_prob
  obj$prefiltering <- function(cr_rate, obs, dim_opt, gm_1) {
    obs <- .sub_inputs(cr_rate, obs, dim_opt)
    .scalar(gm_1, "gm_1", lower = 0, lower_open = TRUE)
    n_sam <- nrow(obs)
    count <- 0L
    for (i in seq_len(n_sam)) {
      norm_sq <- sum(obs[i, ]^2)
      if (!is.finite(norm_sq)) {
        stop("An observation norm overflowed; rescale the input data.", call. = FALSE)
      }
      if (abs(norm_sq - dim_opt) > gm_1) {
        count <- count + 1L
        temp_norm <- sqrt(norm_sq)
        if (temp_norm == 0) {
          stop("A zero-norm observation cannot be normalized in prefiltering.", call. = FALSE)
        }
        obs[i, ] <- obs[i, ] / temp_norm * sqrt(dim_opt)
      }
    }
    if (count > cr_rate * n_sam) return(NULL)
    obs
  }
  obj$sample_filtering_1 <- function(cr_rate, obs, dim_opt, gm_2, omega) {
    obs <- .sub_inputs(cr_rate, obs, dim_opt, omega)
    omega <- as.numeric(omega)
    .scalar(gm_2, "gm_2", lower = 0, lower_open = TRUE)
    n_sam <- nrow(obs)
    get_eig <- function() .leading_eigen(crossprod(obs, obs * omega) - n_sam * diag(dim_opt))
    eig <- get_eig()
    while (eig$lam >= gm_2) {
      tau <- ifelse(omega > obj$utilities_obj$max_tolerance_float,
                    as.vector(obs %*% eig$v)^2, 0)
      des_index <- rev(order(tau))
      max_tau <- tau[des_index[1L]]
      if (!is.finite(max_tau) || max_tau <= 0) {
        stop("Sample filtering cannot progress because all scores are zero.", call. = FALSE)
      }
      i <- 0L
      temp_sum <- 0
      while (i < n_sam && temp_sum < 2 * cr_rate * n_sam) {
        i <- i + 1L
        temp_sum <- temp_sum + omega[des_index[i]]
      }
      previous <- omega
      sel_index <- des_index[seq_len(i)]
      for (j in sel_index) {
        omega[j] <- (1 - tau[j] / max_tau) * omega[j]
      }
      if (sum(abs(1 - omega)) > 2 * cr_rate * n_sam) return(NULL)
      if (identical(previous, omega)) {
        stop("Sample filtering did not update any weights.", call. = FALSE)
      }
      eig <- get_eig()
    }
    omega
  }
  obj$sample_filtering_2 <- function(cr_rate, obs, dim_opt, gm_3, omega) {
    obs <- .sub_inputs(cr_rate, obs, dim_opt, omega)
    omega <- as.numeric(omega)
    .scalar(gm_3, "gm_3", lower = 0, lower_open = TRUE)
    n_sam <- nrow(obs)
    gram <- tcrossprod(obs)
    get_eig <- function() {
      root_weights <- sqrt(omega)
      .leading_eigen(gram * outer(root_weights, root_weights) -
                      dim_opt * diag(as.numeric(omega), nrow = n_sam))
    }
    eig <- get_eig()
    while (eig$lam >= gm_3) {
      tau <- rep(0, n_sam)
      mask <- omega > obj$utilities_obj$max_tolerance_float
      tau[mask] <- eig$v[mask]^2 / omega[mask]
      max_tau <- max(tau)
      if (!is.finite(max_tau) || max_tau <= 0) {
        stop("Sample filtering cannot progress because all scores are zero.", call. = FALSE)
      }
      previous <- omega
      for (i in seq_len(n_sam)) {
        omega[i] <- (1 - tau[i] / max_tau) * omega[i]
      }
      if (sum(abs(1 - omega)) > 6 * cr_rate * n_sam) return(NULL)
      if (identical(previous, omega)) {
        stop("Sample filtering did not update any weights.", call. = FALSE)
      }
      eig <- get_eig()
    }
    omega
  }
  obj$weight_filtering <- function(cr_rate, obs, dim_opt, omega) {
    obs <- .sub_inputs(cr_rate, obs, dim_opt, omega)
    omega <- as.numeric(omega)
    temp_sum_vector <- colSums(obs * sqrt(omega))
    inner_products <- sqrt(omega) * as.vector(obs %*% temp_sum_vector)
    differences <- abs(inner_products - omega * dim_opt)
    tau <- ifelse(omega > obj$utilities_obj$max_tolerance_float, differences, 0)
    des_index <- rev(order(tau))[seq_len(as.integer(cr_rate * nrow(obs)))]
    omega[des_index] <- 0
    omega
  }
  obj$final_test <- function(cr_rate, err_th, obs, dim_opt, omega, C_0_1, C_P_1) {
    obs <- .sub_inputs(cr_rate, obs, dim_opt, omega)
    .scalar(C_0_1, "C_0_1", lower = 0, lower_open = TRUE)
    .scalar(C_P_1, "C_P_1", lower = 0, lower_open = TRUE)
    n_sam <- nrow(obs)
    c_p <- obj$utilities_obj$get_C_P_RAW(n_sam, dim_opt, cr_rate, err_th)
    sum_scaled_obs <- colSums(obs * sqrt(omega))
    empirical_term <- sum(sum_scaled_obs^2)
    expected_term <- dim_opt * sum(abs(omega))
    threshold <- C_0_1 * n_sam^2 * C_P_1 * c_p
    if (any(!is.finite(c(empirical_term, expected_term, threshold)))) {
      stop("The final test overflowed; rescale the input data.", call. = FALSE)
    }
    if (abs(empirical_term - expected_term) >= threshold) "Reject" else "Accept"
  }
  class(obj) <- "SubAlgorithms"
  obj
}
