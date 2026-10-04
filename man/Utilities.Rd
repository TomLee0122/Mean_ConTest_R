\name{Utilities}
\alias{Utilities}
\title{Optimal dimension, projection and raw critical value utilities}
\description{Construct the auxiliary methods used by the original testing implementation.}
\usage{
Utilities(
  max_tolerance_float = contest_constants()$DEFAULT_TOLERANCE_FLOAT,
  max_tolerance_prob = contest_constants()$DEFAULT_TOLERANCE_PROB
)
}
\arguments{
\item{max_tolerance_float}{Strictly positive numeric tolerance at most 0.01.}
\item{max_tolerance_prob}{Numeric probability tolerance strictly between zero and 0.2.}
}
\details{
The returned object's methods are:
\preformatted{
obj$get_hr_opt_dim(sides, n_sam, cr_rate)
obj$get_ep_opt_dim(axes, n_sam, cr_rate)
obj$get_C_P_RAW(n_sam, dim_opt, cr_rate, err_th)
}
\code{sides} and \code{axes} are nonempty finite numeric semi-length vectors.
Negative entries are converted to absolute values. \code{n_sam} is a positive
integer observation count. Geometry methods accept \code{cr_rate} in
\eqn{[0, 1/6]}. \code{get_C_P_RAW} accepts a corruption fraction in
\eqn{[0,1]}, a nonnegative integer \code{dim_opt}, and a significance level
\code{err_th} strictly between zero and 0.2. No additional scaling by
\code{sigma} occurs in these methods: pass normalized lengths when necessary.
The raw critical value omits the final test's multiplicative constants.
}
\value{
An environment with the methods above and the two tolerance fields. Each
geometry method returns \code{list(dim_opt, proj_oper)} with named components:
the selected dimension and a diagonal full-dimensional projection matrix.
\code{get_C_P_RAW} returns a numeric scalar, also when \code{dim_opt = 0}.
}
\seealso{\code{\link{ConTest}}, \code{\link{SubAlgorithms}}}
\examples{
u <- Utilities()
u$get_hr_opt_dim(c(2, 1, 0.05), n_sam = 100, cr_rate = 0.05)
u$get_ep_opt_dim(c(2, 1, 0.05), n_sam = 100, cr_rate = 0.05)
u$get_C_P_RAW(n_sam = 100, dim_opt = 2, cr_rate = 0.05, err_th = 0.05)
}
