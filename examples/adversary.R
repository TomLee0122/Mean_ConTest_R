# Four adversarial strategies from examples/adversary.py. The object's data is
# updated in place; ordinary R copy-on-modify protects the caller's input matrix.
Adversary <- function(data, cr_rate, alt_type, mu_alt, sigma,
                      constr_type = NULL, strategy_flag = 1L, mu_alt_adv = NULL,
                      sides = NULL, axes = NULL, ...) {
  if (!is.matrix(data) || !is.numeric(data) || nrow(data) < 1L || ncol(data) < 1L ||
      any(!is.finite(data))) stop("data must be a finite non-empty numeric matrix.", call. = FALSE)
  n_sam <- nrow(data)
  dim_full <- ncol(data)
  check_mean <- function(value, name) {
    if (!is.numeric(value) || !is.null(dim(value)) || length(value) != dim_full ||
        any(!is.finite(value))) {
      stop(paste(name, "must be a finite vector of length ncol(data)."), call. = FALSE)
    }
    value
  }
  check_mean(mu_alt, "mu_alt")
  for (name in c("mu_alt_adv", "sides", "axes")) {
    value <- get(name)
    if (!is.null(value)) check_mean(value, name)
  }
  if (!is.numeric(cr_rate) || length(cr_rate) != 1L || !is.finite(cr_rate) ||
      cr_rate < 0 || cr_rate >= 1 / 6) stop("cr_rate must be in [0, 1/6).", call. = FALSE)
  if (!is.numeric(sigma) || length(sigma) != 1L || !is.finite(sigma) || sigma <= 0) {
    stop("sigma must be positive.", call. = FALSE)
  }
  if (!is.character(alt_type) || length(alt_type) != 1L || !alt_type %in% c("alter", "null")) {
    stop("alt_type must be 'alter' or 'null'.", call. = FALSE)
  }
  if (!is.numeric(strategy_flag) || length(strategy_flag) != 1L || !is.finite(strategy_flag) ||
      !strategy_flag %in% 1:4) {
    stop("strategy_flag must be one of 1, 2, 3, 4.", call. = FALSE)
  }
  object <- new.env(parent = environment())
  object$data <- data
  extra <- list(...)
  adversary_mean <- function() {
    if (!is.null(mu_alt_adv)) return(mu_alt_adv)
    if (is.null(constr_type)) return(gen_default_mu_alt(dim_full, sigma))
    if (identical(constr_type, "hr")) {
      if (is.null(sides)) sides <- get_default_sides(dim_full, sigma)
      return(sides)
    }
    if (identical(constr_type, "ep")) {
      if (is.null(axes)) axes <- get_default_axes(dim_full, sigma)
      mean <- numeric(dim_full)
      index <- which.max(axes)
      mean[index] <- axes[index]
      return(mean)
    }
    if (is.function(constr_type)) return(check_mean(do.call(constr_type, extra), "adversary mean"))
    stop("Unsupported constraint for adversary mean generation.", call. = FALSE)
  }
  object$adversary_agent <- function() {
    k <- floor(cr_rate * n_sam)
    if (strategy_flag == 1L || k == 0L) return(object$data)
    if (strategy_flag == 2L) {
      indices <- sample.int(n_sam, k, replace = FALSE)
      replacement_mean <- if (alt_type == "alter") numeric(dim_full) else adversary_mean()
    } else if (strategy_flag == 3L) {
      norms <- sqrt(rowSums(object$data^2))
      indices <- order(norms, decreasing = alt_type == "alter")[seq_len(k)]
      replacement_mean <- if (alt_type == "alter") numeric(dim_full) else adversary_mean()
    } else {
      target_mean <- if (alt_type == "alter") mu_alt else adversary_mean()
      distances <- sqrt(rowSums(sweep(object$data, 2L, target_mean, "-")^2))
      indices <- order(distances, decreasing = TRUE)[seq_len(k)]
      replacement_mean <- if (alt_type == "alter") numeric(dim_full) else target_mean
    }
    object$data[indices, ] <- gen_data(k, replacement_mean, dim_full, sigma)
    object$data
  }
  class(object) <- "Adversary"
  object
}
