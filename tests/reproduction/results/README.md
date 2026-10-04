# Archived Python experiment results

The four CSV files are lossless, long-form exports of the four corresponding
NumPy arrays in `code/package_mean_contest/tests/results` at the start of this
update. They contain the existing experiment results, not fresh R simulations.

Columns are `n_sam`, `dim_full`, `cr_rate`, `norm`, and `reject_rate`. For each
dimension/corruption group, the 50 norms are the same evenly spaced grid encoded
by the original array's first two entries, and the rejection rates are the
remaining entries. Sample sizes 200/2000 use dimensions 5/10/20/50; sample sizes
100/500 use dimensions 100/500. All use corruption rates 0.01/0.015/0.02/0.025.

The four PDFs are unchanged copies of the original saved Python plots. The R
plotting script can read the CSV files directly. R simulation writes native RDS
arrays and CSV files. NumPy and R random streams differ, so rerunning the Monte
Carlo experiments in R need not give identical rejection rates.

These archived runs predate the integer-weight bug correction. The corrected
Python and R pipelines retain fractional sample-filter weights, which can
change rejection rates whenever sample-filtering updates occur. These files
remain historical artifacts and were not regenerated as part of the fix.
