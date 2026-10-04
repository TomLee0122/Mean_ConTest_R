# Mean-ConTest for R

`meancontest` is an R counterpart of the
[Mean-ConTest Python package](https://github.com/TomLee0122/Mean_ConTest).
It implements robust constrained Gaussian mean
testing with hyperrectangle, ellipsoid, unconstrained, or supplied projection
constraints. The implementation follows the Python source, including its
particular formulas, constants, and filtering behavior.

This standalone repository originated as `code/package_mean_contest_r` in a
research workspace, alongside the Python source in `code/package_mean_contest`.
The commands below run from the root of this R repository.

## Install and use

Clone and install the R package:

```sh
git clone https://github.com/TomLee0122/Mean_ConTest_R.git
cd Mean_ConTest_R
R CMD INSTALL .
```

Or install from an R session:

```r
install.packages(".", repos = NULL, type = "source")
```

R 4.0 or later is required. The runtime uses base R and standard R packages;
there are no third-party dependencies or compiled extensions.

```r
library(meancontest)

set.seed(42)
data <- matrix(rnorm(200 * 5), nrow = 200, ncol = 5)
test <- ConTest()
test$change_constants("_VERBOSE", FALSE)
test$data_load(data, cr_rate = 0.02, err_th = 0.05, sigma = 1,
               constr_type = "ep", axes = sqrt(5) / (1:5)^2)
test$testing()       # "Accept", "Reject", or NULL
test$clear()
```

Each observation is a row of a finite numeric matrix. `sigma` is the known
standard deviation, so the original covariance is `sigma^2 * I`. Data and
constraint lengths are normalized by `sigma` internally.

`"Accept"` means the test did not reject the null hypothesis; it does not prove
that the mean is zero. `NULL` means the selected optimal dimension is zero and
the test is unavailable for that configuration. Calling `testing()` without a
successful `data_load()` raises an error.

## Matching Python and R interfaces

| Python | R |
| --- | --- |
| `mean_contest.ConTest()` | `ConTest()` |
| `test.data_load(...)` | `test$data_load(...)` |
| `test.testing()` | `test$testing()` |
| `test.clear()` | `test$clear()` |
| `test.change_constants(names, values)` | `test$change_constants(names, values)` |
| `Utilities(tolerance_float, tolerance_prob)` | `Utilities(tolerance_float, tolerance_prob)` |
| `SubAlgorithms(utilities, tolerance_float, tolerance_prob)` | `SubAlgorithms(utilities, tolerance_float, tolerance_prob)` |
| `(dim_opt, proj_oper)` | `list(dim_opt = ..., proj_oper = ...)` |
| `None`, NumPy vector, NumPy matrix | `NULL`, numeric vector, numeric matrix |

The `data_load` argument names and order match Python: `data`, `cr_rate`,
`err_th`, `sigma`, `constr_type`, `sides`, `axes`, `dim_opt`, `proj_oper`,
`max_tolerance_float`, and `max_tolerance_prob`.

- `constr_type = NULL`: all dimensions are used.
- `constr_type = "hr"`: supply `sides`, a vector of hyperrectangle semisides.
- `constr_type = "ep"`: supply `axes`, a vector of ellipsoid semiaxes.
- `constr_type = "others"`: supply a positive `dim_opt` and a square
  `proj_oper` matrix with dimension `ncol(data)`.

Negative constraint lengths are converted to absolute values. The corruption
rate is in `[0, 1/6]`, significance level is strictly between 0 and 0.2, and
`sigma` must be positive. Constraint vectors must match the data dimension.
The floating tolerance is in `(0, 0.01]`; the probability tolerance is strictly
between 0 and 0.2. A failed reload retains the preceding complete configuration.

Use `contest_constants()` to inspect current settings. Constants are shared
across objects, matching Python module globals. Updates validate the entire
request before applying any changes. Use a list when mixing numbers and logical
values, for example `test$change_constants(c("C_1", "_VERBOSE"), list(5, FALSE))`.
After changing default loading parameters, reload the object to apply them.
The `C_*` thresholds and verbosity are read when testing runs.

## Examples and experiments

The scripts run directly from the source tree, even before installation:

```sh
Rscript examples/demo.R --smoke
Rscript examples/demo.R --full
Rscript tests/reproduction/reproduce_paper.R --smoke
Rscript tests/reproduction/reproduce_paper.R --full
Rscript tests/reproduction/plot.R
```

The smoke modes run small configurations. The full demo uses the original two
Python profiles. The full reproduction runs both original scenario grids,
including 50 mean norms and 200 replications per setting, so it is substantial
computational work. Full Monte Carlo runs are excluded from package checks.

The source mapping below uses paths relative to each package's own root.

| Python source | R source |
| --- | --- |
| `src/mean_contest/api.py` | `R/api.R` |
| `src/mean_contest/constants.py` | `R/constants.R` |
| `src/mean_contest/utilities.py` | `R/utilities.R` |
| `src/mean_contest/sub_algorithms.py` | `R/sub_algorithms.R` |
| `examples/*.py` | corresponding `examples/*.R` |
| `tests/{test_constants,test_utilities,reproduce_paper,plot}.py` | corresponding `tests/reproduction/*.R` |
| `tests/results/*.npy` | `tests/reproduction/results/*.csv` |
| `tests/results/*.pdf` | unchanged `tests/reproduction/results/*.pdf` |

The archived CSV files are lossless exports of the existing Python results.
New R experiments write native RDS arrays and long-form CSV files. Plotting uses
base R. NumPy and R produce different random streams for the same numeric seed;
new Monte Carlo results need not be identical to the archived Python results.
Smoke outputs go to `tests/reproduction/results/smoke`; full outputs go to
`tests/reproduction/results/generated`. Supply `--save-dir=directory` to choose
another location or `--no-plot` to skip plots. The standalone plotting command
reads archived results by default and writes to `results/plots`; optional first
and second arguments select the input and output directories.

## Algorithm fidelity and limitations

The port preserves all four stages, the optimal-dimension selection rules, the
normalization used instead of deleting prefiltered observations, corruption
multipliers, threshold formulas, and the final `>=` comparison. Both maintained
packages use floating-point weights, correcting the original Python integer
array bug that truncated fractional updates. Direct sample-filtering methods
also promote integer inputs to doubles; use their returned weight vectors.
This correction can change filter trajectories and accept/reject decisions.

The supplied projection is processed using a general eigendecomposition, as in
Python. Exact score ties, repeated eigenvalues, or data extremely close to a
decision threshold can produce different rounding or ordering across numerical
libraries. Invalid data, overflow, and stalled filtering raise clear errors.
The existing experimental ellipsoid mean-construction formula is also retained;
the port does not replace it with a different geometric construction.

## Verify

```sh
R CMD build .
R CMD check --no-manual meancontest_0.1.0.tar.gz
```

The optional Python comparison requires Python, NumPy, and a matching corrected
Python counterpart installed in the comparison environment. The Python source
is maintained in its own repository; once the matching weight fixes are
published there, it can be installed with:

```sh
python -m pip install "git+https://github.com/TomLee0122/Mean_ConTest.git"
python tools/verify_python_parity.py
```

For local development, install the corresponding Python source with
`python -m pip install -e /path/to/package_mean_contest`. The comparison helper
also recognizes a sibling directory named `package_mean_contest` containing
`src/mean_contest`, as in the original research workspace. A standalone R clone
does not include that Python directory; its R package checks use the bundled
reference fixtures and do not require Python.

The shared reference suite includes 54 geometry/threshold cases, 14 complete
tests, 24 intermediate filtering cases, and 11 intermediate weight vectors.
References come from the original dense Python implementation with only its
weight initialization corrected; direct integer-input expectations match its
original floating-input outputs. R checks them during `R CMD check`; the Python
script checks the maintained Python package against the same reference values.
Additional R boundary tests exercise input validation and object lifecycle.

Local validation passed on Python 3.10 and R 4.3.1: 17 Python regression tests,
all 103 reference cases in both languages, package installation/builds, both full
demo profiles, reduced scans, archive plotting, and `R CMD check` (`Status: OK`).
The full paper-scale Monte Carlo scans were not rerun. Archived results predate
the fractional-weight correction and should be regenerated before treating them
as results of the corrected implementation.

Package layout follows the official
[Writing R Extensions](https://www.stat.math.ethz.ch/CRAN/doc/manuals/r-release/R-exts.html)
manual. See `REVIEW.md` in the separately maintained Python package for the
quality review and the algorithm-sensitive findings that remain unchanged.

## Citation and license

Yikun Li and Matey Neykov, *Robust Signal Detection with Quadratically Convex
Orthosymmetric Constraints*, [arXiv:2308.13036](https://arxiv.org/abs/2308.13036).
Run `citation("meancontest")` for a BibTeX entry. The package uses the original
MIT license; see `LICENSE` and `LICENSE.md`.
