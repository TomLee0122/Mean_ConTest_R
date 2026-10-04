# Literal translations of the Python reproduction helpers. In particular,
# get_ep_vec intentionally retains the source's axis (rather than squared-axis)
# formulas, and get_hr_vec retains its source coordinate order.
get_ep_vec <- function(axes, dim_opt, norm) {
  axes <- abs(axes)
  dim_full <- length(axes)
  descending <- order(axes, decreasing = TRUE)
  new_alt <- numeric(dim_full)
  if (dim_opt == dim_full) {
    new_alt[descending[1L]] <- norm
  } else if (norm^2 <= axes[descending[dim_opt + 1L]]) {
    new_alt[descending[dim_opt + 1L]] <- norm
  } else {
    largest <- axes[descending[1L]]
    following <- axes[descending[dim_opt + 1L]]
    new_alt[descending[1L]] <- sqrt((norm^2 * largest - largest * following) / (largest - following))
    new_alt[descending[dim_opt + 1L]] <- sqrt((largest * following - norm^2 * following) / (largest - following))
  }
  new_alt
}

get_hr_vec <- function(sides, dim_opt, norm, tolerance = 1e-7) {
  sides <- abs(sides)
  dim_full <- length(sides)
  descending <- order(sides, decreasing = TRUE)
  new_alt <- numeric(dim_full)
  remaining <- norm^2
  if (dim_opt == dim_full) {
    i <- 1L
    while (i <= dim_full && remaining - sides[descending[i]]^2 >= tolerance) {
      new_alt[descending[i]] <- sides[descending[i]]
      remaining <- remaining - sides[descending[i]]^2
      i <- i + 1L
    }
    if (i > dim_full) stop("Requested norm exhausts the source hyperrectangle allocation.", call. = FALSE)
    new_alt[descending[i]] <- sqrt(remaining)
  } else {
    # Python's starting index dim - dim_opt becomes one-based here.
    i <- dim_full - dim_opt + 1L
    while (i <= dim_full && remaining - sides[descending[i]]^2 >= tolerance) {
      new_alt[descending[i]] <- sides[descending[i]]
      remaining <- remaining - sides[descending[i]]^2
      i <- i + 1L
    }
    if (remaining > tolerance) {
      i <- 1L
      while (i <= dim_full - dim_opt && remaining - sides[descending[i]]^2 >= tolerance) {
        new_alt[descending[i]] <- sides[descending[i]]
        remaining <- remaining - sides[descending[i]]^2
        i <- i + 1L
      }
      if (i > dim_full) stop("Requested norm exhausts the source hyperrectangle allocation.", call. = FALSE)
      new_alt[descending[i]] <- sqrt(remaining)
    }
  }
  new_alt
}

get_none_vec <- function(dim_full, norm) rep(norm / sqrt(dim_full), dim_full)
