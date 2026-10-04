.scalar <- function(x, name, lower = -Inf, upper = Inf,
                    lower_open = FALSE, upper_open = FALSE,
                    integer = FALSE) {
  if (!is.numeric(x) || is.complex(x) || length(x) != 1L ||
      !is.finite(x)) {
    stop(sprintf("%s must be a finite numeric scalar.", name), call. = FALSE)
  }
  if ((lower_open && x <= lower) || (!lower_open && x < lower) ||
      (upper_open && x >= upper) || (!upper_open && x > upper) ||
      (integer && x != floor(x))) {
    interval <- paste0(if (lower_open) "(" else "[", lower, ", ", upper,
                       if (upper_open) ")" else "]")
    stop(sprintf("%s must be %sin %s.", name,
                 if (integer) "an integer " else "", interval), call. = FALSE)
  }
  invisible(x)
}

.numeric_vector <- function(x, name, size = NULL) {
  if (!is.numeric(x) || is.complex(x) || !is.null(dim(x)) ||
      length(x) == 0L || any(!is.finite(x)) ||
      (!is.null(size) && length(x) != size)) {
    suffix <- if (is.null(size)) "" else sprintf(" of length %s", size)
    stop(sprintf("%s must be a nonempty finite numeric vector%s.",
                 name, suffix), call. = FALSE)
  }
  as.numeric(x)
}

.observation_matrix <- function(x, name = "data") {
  if (!is.matrix(x) || !is.numeric(x) || is.complex(x) ||
      any(dim(x) == 0L) || any(!is.finite(x))) {
    stop(sprintf("%s must be a nonempty finite numeric matrix.", name),
         call. = FALSE)
  }
  storage.mode(x) <- "double"
  x
}

.sub_inputs <- function(cr_rate, obs, dim_opt, omega = NULL) {
  .scalar(cr_rate, "cr_rate", lower = 0, upper = 1)
  obs <- .observation_matrix(obs, "obs")
  .scalar(dim_opt, "dim_opt", lower = 1, integer = TRUE)
  if (dim_opt != ncol(obs)) {
    stop("dim_opt must match the number of columns in obs.", call. = FALSE)
  }
  if (!is.null(omega)) {
    .numeric_vector(omega, "omega", nrow(obs))
    if (any(omega < 0 | omega > 1)) {
      stop("omega must contain weights in [0, 1].", call. = FALSE)
    }
  }
  obs
}

.leading_eigen <- function(x) {
  if (any(!is.finite(x))) {
    stop("The filtering matrix overflowed; rescale the input data.", call. = FALSE)
  }
  eig <- eigen(x, symmetric = FALSE)
  if (is.complex(eig$values) || is.complex(eig$vectors)) {
    # Matrices used by the algorithm are real symmetric; tiny imaginary roundoff
    # may occur when a general LAPACK eigensolver is used, as in numpy.linalg.eig.
    tol <- 100 * .Machine$double.eps * max(1, max(abs(x)))
    if (any(abs(Im(eig$values)) > tol) || any(abs(Im(eig$vectors)) > tol)) {
      stop("The filtering eigendecomposition returned complex values.", call. = FALSE)
    }
    eig$values <- Re(eig$values)
    eig$vectors <- Re(eig$vectors)
  }
  index <- which.max(abs(eig$values))
  list(lam = abs(eig$values[index]), v = eig$vectors[, index])
}
