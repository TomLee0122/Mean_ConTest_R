\name{contest_constants}
\alias{contest_constants}
\title{Read the current package testing constants}
\description{Get a copy of the testing constants shared by all \code{ConTest} objects.}
\usage{contest_constants()}
\details{
Defaults are \code{DEFAULT_TOLERANCE_FLOAT = 1e-7},
\code{DEFAULT_TOLERANCE_PROB = 6e-3}, \code{DEFAULT_ERR_TH = 0.05},
\code{DEFAULT_SIGMA = 1}, \code{C_1 = 5}, \code{C_2_1 = 50},
\code{C_2_2 = 50}, \code{C_P_1 = 5}, \code{C_0_1 = 0.7},
\code{C_LB_1 = 5} and \code{_VERBOSE = TRUE}. \code{C_LB_1} is unused in the
current source implementation.

Change settings through \code{ConTest()$change_constants(names, values)}.
To restore settings, save this function's return value and pass its names and
values back to that method. Use a list to retain the logical type of
\code{_VERBOSE} when changing it alongside numeric constants.
}
\value{A named list. Modifying the returned list does not change package settings.}
\seealso{\code{\link{ConTest}}}
\examples{
settings <- contest_constants()
obj <- ConTest()
obj$change_constants("_VERBOSE", FALSE)
obj$change_constants(names(settings), settings)
}
