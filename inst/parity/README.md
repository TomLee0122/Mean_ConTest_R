# Python reference fixtures

These reference values use the original Python core in outer repository commit
`5bef40d`. Geometry, prefiltering, weight filtering, and the final-test formulas
are unchanged. For public-pipeline references, the only source change is
`np.repeat(1, self.n_sam)` replaced with `np.ones(self.n_sam, dtype=float)`.
The original dense matrix calculations remain, so these references are
independent of the maintained Python/R implementations and their optimizations.

- `utilities.csv`: 54 dimension/projection/raw-threshold cases, including zero
  optimal dimension, negative semiaxes, and different corruption rates.
- `pipeline.csv` and named observation matrices: 14 complete tests covering both
  sample/dimension regimes, every constraint type, a rotated projection, sigma
  normalization, acceptance, rejection, and an unavailable test (`NULL`).
- `sub_algorithms.csv` and `filter_*.csv`: 24 intermediate cases covering
  prefilter rejection/normalization, actual sample-filter iterations with both
  integer and fractional input weights, weight filtering, and the final test.
  Integer-input expectations now equal the original floating-input outputs,
  protecting against reintroduction of truncation during direct API calls.
- `sample_weights.csv`: 11 sample-filter outputs captured before weight
  filtering in the public pipeline. Fractional values must reach later stages.

The `legacy_result` and `legacy_expected` columns record the old integer-weight
behavior for comparison; they are not the corrected test expectations.
`fractional_weights_high` demonstrates a complete test that changes from the
old `Reject` to the corrected `Accept` because fractional weights are retained.

The default `C_2_1` and `C_2_2` are 50. Two pipeline cases deliberately set them
to 2 using the existing configuration interface so sample-filtering iterations
are exercised. Each row records the setting used.

Matrix CSV files have no header and use observations as rows. Semicolon-delimited
vectors in metadata files follow the original Python coordinate order. Flattened
prefilter matrices use row-major order. Comparison tolerance is `1e-10`.

`tests/parity.R` checks R against these reference results during `R CMD check`.
`tools/verify_python_parity.py` checks the maintained Python counterpart against
the same results. Fixtures avoid exact score ties and repeated dominant
eigenvalues; cross-language tie/eigenbasis equivalence is not guaranteed.
