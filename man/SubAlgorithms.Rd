\name{SubAlgorithms}
\alias{SubAlgorithms}
\title{Individual filtering steps and the final hypothesis test}
\description{Construct the individual algorithms used by \code{ConTest}.}
\usage{
SubAlgorithms(
  utilities_obj = Utilities(),
  max_tolerance_float = utilities_obj$max_tolerance_float,
  max_tolerance_prob = utilities_obj$max_tolerance_prob
)
}
\arguments{
\item{utilities_obj}{An environment returned by \code{Utilities()}.}
\item{max_tolerance_float}{Strictly positive numeric tolerance at most 0.01.}
\item{max_tolerance_prob}{Numeric probability tolerance strictly between zero and 0.2.}
}
\details{
The returned object's methods are:
\preformatted{
obj$prefiltering(cr_rate, obs, dim_opt, gm_1)
obj$sample_filtering_1(cr_rate, obs, dim_opt, gm_2, omega)
obj$sample_filtering_2(cr_rate, obs, dim_opt, gm_3, omega)
obj$weight_filtering(cr_rate, obs, dim_opt, omega)
obj$final_test(cr_rate, err_th, obs, dim_opt, omega, C_0_1, C_P_1)
}
\code{obs} is a nonempty finite numeric projected observation matrix with
observations in rows. \code{dim_opt} is a positive integer equal to its column
count. \code{cr_rate} is a fraction in \eqn{[0,1]}. The filtering methods
accept positive finite numeric thresholds \code{gm_1}, \code{gm_2} or
\code{gm_3}. \code{omega} is an integer or double vector with one weight per
observation, each in \eqn{[0,1]}. The final test's \code{err_th} is strictly
between zero and 0.2, and \code{C_0_1} and \code{C_P_1} are positive finite
threshold constants.

\code{sample_filtering_1} is used when the observation count exceeds
\code{dim_opt}; \code{sample_filtering_2} is used otherwise. \code{ConTest}
passes twice the input corruption fraction to sample and weight filtering,
matching the Python implementation. Direct callers supply the desired method
argument explicitly.

R vectors and matrices are copied on modification; use each method's returned
value. Sample and weight filtering promote integer weight vectors to double
precision, preserving fractional downweighting updates. The main
\code{ConTest} pipeline starts with double precision weights. Score ties and
eigensolver degeneracies may differ from NumPy.
Filtering raises an error if it cannot make progress, rather than looping
indefinitely or dividing by zero. Numerical overflow raises a descriptive error.
}
\value{
An environment with the methods above and their utilities and tolerance fields.
\code{prefiltering} returns the filtered observation matrix or \code{NULL}
when its rejection criterion holds. The two sample filtering methods return
updated weights or \code{NULL} when their rejection criteria hold.
\code{weight_filtering} returns updated weights. \code{final_test} returns
\code{"Accept"} or \code{"Reject"}; \code{"Accept"} denotes failure to
reject the null.
}
\seealso{\code{\link{ConTest}}, \code{\link{Utilities}}}
\examples{
a <- SubAlgorithms()
obs <- matrix(c(1, -1, 0.5, -0.5), ncol = 1)
filtered <- a$prefiltering(0.1, obs, dim_opt = 1, gm_1 = 10)
a$final_test(0.1, 0.05, filtered, 1, rep(1L, 4), 0.7, 5)
}
