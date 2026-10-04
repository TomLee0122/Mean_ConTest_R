# The semi-sides and semi-axes match the Python demo exactly.
get_default_sides <- function(dim_full, sigma) {
  sigma * sqrt(dim_full) / seq_len(dim_full)^2
}

get_default_axes <- function(dim_full, sigma) {
  sigma * sqrt(dim_full) / seq_len(dim_full)^2
}
