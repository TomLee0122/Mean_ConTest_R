# These functions preserve the Python simulation distributions. R's random
# generator differs from NumPy's, so identical seeds do not give identical data.
gen_default_mu_alt <- function(dim_full, sigma) {
  sigma * rep(DEFAULT_MU_ALT_SOURCE, dim_full)
}

gen_mu_alt_hr <- function(sides) {
  magnitude <- runif(length(sides), 0.5, 1) * abs(sides)
  ifelse(runif(length(sides)) < 0.5, -magnitude, magnitude)
}

gen_mu_alt_ep <- function(axes) {
  dim_full <- length(axes)
  angles <- runif(dim_full, 0, 2 * pi)
  mu_alt <- numeric(dim_full)
  for (i in seq_len(dim_full)) {
    coordinate <- axes[i]
    if (i > 1L) coordinate <- coordinate * prod(sin(angles[seq_len(i - 1L)]))
    mu_alt[i] <- coordinate * cos(angles[i]) * runif(1L, 0.5, 1)
  }
  mu_alt
}

gen_data <- function(n, mu_alt, dim, sigma) {
  if (length(n) != 1L || !is.numeric(n) || !is.finite(n) || n < 0 || n != floor(n)) {
    stop("n must be a non-negative integer.", call. = FALSE)
  }
  if (length(dim) != 1L || !is.numeric(dim) || !is.finite(dim) || dim <= 0 || dim != floor(dim)) {
    stop("dim must be a positive integer.", call. = FALSE)
  }
  if (!is.numeric(mu_alt) || !is.null(base::dim(mu_alt)) || length(mu_alt) != dim ||
      any(!is.finite(mu_alt))) stop("mu_alt must be a finite vector of length dim.", call. = FALSE)
  if (length(sigma) != 1L || !is.numeric(sigma) || !is.finite(sigma) || sigma <= 0) {
    stop("sigma must be positive.", call. = FALSE)
  }
  # Identity covariance allows independent Gaussian coordinates in base R.
  sweep(matrix(rnorm(n * dim, sd = sigma), nrow = n, ncol = dim), 2L, mu_alt, "+")
}
