\name{ConTest}
\alias{ConTest}
\alias{print.ConTest}
\title{Robust constrained Gaussian mean hypothesis testing}
\description{
Create a testing object whose methods mirror the Python mean-contest package.
The original source's formulas, thresholds, branch conditions and corruption
multipliers are retained. Filtering weights use double precision to preserve
fractional downweighting updates.
}
\usage{
ConTest()
\method{print}{ConTest}(x, ...)
}
\arguments{
\item{x}{An object returned by \code{ConTest()}.}
\item{...}{Unused additional print arguments.}
}
\details{
The returned environment has the following methods:
\preformatted{
obj$data_load(data, cr_rate, err_th = NULL, sigma = NULL,
              constr_type = NULL, sides = NULL, axes = NULL,
              dim_opt = NULL, proj_oper = NULL,
              max_tolerance_float = NULL, max_tolerance_prob = NULL)
obj$testing()
obj$clear()
obj$change_constants(names, values)
}
\code{data} is a nonempty finite numeric matrix, with observations in rows and
coordinates in columns. \code{cr_rate} is the known corruption fraction in
\eqn{[0, 1/6]}. The significance level \code{err_th} is strictly between zero
and 0.2. \code{sigma} is a strictly positive noise standard deviation: the
implementation divides observations and supplied sides or axes by this value.
Defaults are obtained from \code{contest_constants()}.

For an unconstrained test, use \code{constr_type = NULL}. For a hyperrectangle,
use \code{constr_type = "hr"} and a numeric \code{sides} vector with one
semi-side per coordinate. For an ellipsoid, use \code{constr_type = "ep"} and
an \code{axes} vector with one semi-axis per coordinate. Negative lengths are
converted to absolute values. For \code{constr_type = "others"}, provide a
positive integer \code{dim_opt} at most the number of coordinates and a square
\code{proj_oper} projection matrix of that full dimension. These two arguments
are ignored for automatically selected constraints. The projection eigenvalues
are checked when testing, using the original source's eigenvalue criterion.

\code{max_tolerance_float} must be strictly positive and at most 0.01;
\code{max_tolerance_prob} must be strictly between zero and 0.2. The probability
tolerance is retained for API compatibility; the source algorithms currently
do not use it in a decision threshold.

\code{data_load} validates a new configuration before replacing the old one.
A failed reload leaves the previous valid configuration usable. R's copy on
modify semantics keep the caller's input data unchanged. \code{clear} removes
all loaded data and configuration, but leaves package constants unchanged.

\code{change_constants} accepts a character vector of names and corresponding
values. Use a list when mixing logical and numeric constants. Every update is
validated before any value is changed. Settings are shared by all objects in
the current R session, as they are in the Python package. Loaded data retain
their existing noise scaling, tolerances and geometry; reload to apply changes
to defaults. Current \code{C_*} thresholds and \code{_VERBOSE} are read on each
testing call. \code{C_LB_1} is currently unused. \code{_VERBOSE = TRUE} emits
progress messages; use \code{FALSE} to silence them.

The initial weights inside \code{testing} use double precision, so filtering
preserves fractional downweighting updates. Integer vectors supplied directly
to \code{SubAlgorithms} are promoted to double precision as well.
LAPACK eigenvectors, tied score ordering
and floating point rounding may differ between languages near decision bounds.
}
\value{
\code{ConTest()} returns a mutable environment with the methods above and the
loaded configuration fields. \code{data_load}, \code{clear} and
\code{change_constants} return \code{NULL} invisibly. \code{testing} returns
\code{"Reject"} or \code{"Accept"}; the latter means failure to reject the
null. A constraint with zero optimal dimension produces a warning and
\code{NULL}. Invalid inputs, unconfigured testing and failed numerical
calculations raise errors.
}
\references{
Li, Y. and Neykov, M., Robust Signal Detection with Quadratically Convex
Orthosymmetric Constraints. \url{https://arxiv.org/abs/2308.13036}.
}
\seealso{\code{\link{Utilities}}, \code{\link{SubAlgorithms}},
\code{\link{contest_constants}}}
\examples{
set.seed(42)
data <- matrix(rnorm(200), nrow = 50, ncol = 4)
obj <- ConTest()
previous <- contest_constants()["_VERBOSE"]
obj$change_constants("_VERBOSE", FALSE)
obj$data_load(data, cr_rate = 0.05, constr_type = "ep",
              axes = c(2, 1, 0.5, 0.1))
obj$testing()
obj$clear()
obj$change_constants(names(previous), previous)
}
