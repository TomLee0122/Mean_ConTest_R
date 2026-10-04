#' Construct the auxiliary testing utilities
#' @param max_tolerance_float Positive floating point tolerance, at most 0.01.
#' @param max_tolerance_prob Probability tolerance, strictly between 0 and 0.2.
#' @return An environment with optimal dimension and critical value methods.
#' @export
Utilities <- function(max_tolerance_float = contest_constants()$DEFAULT_TOLERANCE_FLOAT,
                      max_tolerance_prob = contest_constants()$DEFAULT_TOLERANCE_PROB) {
  .scalar(max_tolerance_float, "max_tolerance_float", lower = 0, upper = 0.01,
          lower_open = TRUE)
  .scalar(max_tolerance_prob, "max_tolerance_prob", lower = 0, upper = 0.2,
          lower_open = TRUE, upper_open = TRUE)
  obj <- new.env(parent = emptyenv())
  obj$max_tolerance_float <- max_tolerance_float
  obj$max_tolerance_prob <- max_tolerance_prob
  get_opt_dim <- function(lengths, n_sam, cr_rate, hyperrectangle) {
    lengths <- abs(.numeric_vector(lengths, if (hyperrectangle) "sides" else "axes"))
    .scalar(n_sam, "n_sam", lower = 1, integer = TRUE)
    .scalar(cr_rate, "cr_rate", lower = 0, upper = 1 / 6)
    dim_full <- length(lengths)
    indices <- order(lengths)
    kol_width <- 0
    projection <- rep(1, dim_full)
    alt_sel <- max(cr_rate, 1 / sqrt(n_sam))
    for (i in seq_len(dim_full)) {
      if (hyperrectangle) kol_width <- kol_width + lengths[indices[i]]^2
      criterion <- if (hyperrectangle) kol_width else lengths[indices[i]]^2
      if (criterion > sqrt((dim_full - i + 1) / n_sam) * alt_sel) {
        if (i > 1L) projection[indices[seq_len(i - 1L)]] <- 0
        return(list(dim_opt = dim_full - i + 1L,
                    proj_oper = diag(projection, nrow = dim_full)))
      }
    }
    list(dim_opt = 0L, proj_oper = matrix(0, dim_full, dim_full))
  }
  obj$get_hr_opt_dim <- function(sides, n_sam, cr_rate) {
    get_opt_dim(sides, n_sam, cr_rate, TRUE)
  }
  obj$get_ep_opt_dim <- function(axes, n_sam, cr_rate) {
    get_opt_dim(axes, n_sam, cr_rate, FALSE)
  }
  obj$get_C_P_RAW <- function(n_sam, dim_opt, cr_rate, err_th) {
    .scalar(n_sam, "n_sam", lower = 1, integer = TRUE)
    .scalar(dim_opt, "dim_opt", lower = 0, integer = TRUE)
    .scalar(cr_rate, "cr_rate", lower = 0, upper = 1)
    .scalar(err_th, "err_th", lower = 0, upper = 0.2,
            lower_open = TRUE, upper_open = TRUE)
    if (cr_rate >= obj$max_tolerance_float) {
      max(cr_rate * log(n_sam / err_th) / sqrt(n_sam),
          cr_rate^2 * log(n_sam / err_th),
          cr_rate * sqrt(dim_opt * log(n_sam / err_th) / n_sam),
          cr_rate^2 * log(1 / cr_rate),
          sqrt(dim_opt) * log(1 / err_th) / n_sam)
    } else {
      sqrt(dim_opt) * log(1 / err_th) / n_sam
    }
  }
  class(obj) <- "Utilities"
  obj
}
