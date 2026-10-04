"""Check Python against the dense reference with floating-point weights.

Run from any directory with Python and NumPy installed. R validates the same
fixtures in tests/parity.R, which also runs during R CMD check.
"""
import csv
from pathlib import Path
import sys

import numpy as np

PACKAGE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PACKAGE.parent / "package_mean_contest" / "src"))
from mean_contest import ConTest
from mean_contest import constants
from mean_contest.utilities import Utilities
from mean_contest.sub_algorithms import SubAlgorithms

FIXTURES = PACKAGE / "inst" / "parity"


def read_rows(name):
    with (FIXTURES / name).open(newline="", encoding="utf-8") as stream:
        return list(csv.DictReader(stream))


def vector(text):
    return np.asarray([float(value) for value in text.split(";")])


def assert_weights(actual, expected, label):
    if expected == "NULL":
        assert actual is None, label
    else:
        assert actual is not None and actual.dtype == np.float64, label
        np.testing.assert_allclose(actual.ravel(), vector(expected), rtol=1e-10, atol=1e-12, err_msg=str(label))


def main():
    u = Utilities(1e-7, 6e-3)
    algorithms = SubAlgorithms(u, 1e-7, 6e-3)
    for row in read_rows("utilities.csv"):
        n, rate = int(row["n_sam"]), float(row["cr_rate"])
        dim, projection = getattr(u, "get_" + row["kind"] + "_opt_dim")(vector(row["values"]), n, rate)
        assert dim == int(row["dim_opt"]), row
        np.testing.assert_allclose(np.diag(projection), vector(row["projection"]))
        np.testing.assert_allclose(u.get_C_P_RAW(n, dim, rate, 0.05), float(row["c_p"]), rtol=1e-12)

    samples = {row["case"]: row for row in read_rows("sample_weights.csv")}
    previous = constants.C_2_1, constants.C_2_2
    try:
        for row in read_rows("pipeline.csv"):
            data = np.loadtxt(FIXTURES / (row["case"] + ".csv"), delimiter=",").reshape(int(row["n_sam"]), int(row["dim_full"]))
            kind = row["kind"]
            kwargs = dict(cr_rate=float(row["cr_rate"]), sigma=float(row["sigma"]), constr_type=None if kind == "none" else kind)
            if kind in ["hr", "ep"]:
                kwargs["sides" if kind == "hr" else "axes"] = vector(row["values"])
            if kind == "others":
                kwargs.update(dim_opt=int(row["dim_opt"]), proj_oper=np.loadtxt(FIXTURES / (row["case"] + "_projection.csv"), delimiter=","))
            constants.C_2_1 = constants.C_2_2 = float(row["c2"])
            obj = ConTest()
            obj.data_load(data, **kwargs)
            captured = []
            for method in ("sample_filtering_1", "sample_filtering_2"):
                original = getattr(obj.sub_algorithms, method)
                def capture(*args, original=original, method=method):
                    result = original(*args)
                    captured.append((method, None if result is None else result.copy()))
                    return result
                setattr(obj.sub_algorithms, method, capture)
            result = obj.testing()
            assert obj.dim_opt == int(row["dim_opt"]), row
            assert ("NULL" if result is None else result) == row["result"], row
            if row["case"] in samples:
                reference = samples[row["case"]]
                assert len(captured) == 1 and captured[0][0] == reference["method"], row
                assert_weights(captured[0][1], reference["expected"], row["case"])
            else:
                assert not captured, row
    finally:
        constants.C_2_1, constants.C_2_2 = previous

    for row in read_rows("sub_algorithms.csv"):
        obs = np.loadtxt(FIXTURES / (row["case"] + ".csv"), delimiter=",")
        n, dim = obs.shape
        rate = float(row["cr_rate"])
        method = row["method"]
        if method == "prefiltering":
            out = algorithms.prefiltering(rate, obs.copy(), dim, float(row["gamma"]))
        elif method.startswith("sample_filtering"):
            weights = np.ones(n, dtype=int if row["dtype"] == "int" else float)
            out = getattr(algorithms, method)(rate, obs, dim, float(row["gamma"]), weights)
        elif method == "weight_filtering":
            out = algorithms.weight_filtering(rate, obs, dim, np.linspace(0.15, 1, n))
        else:
            out = algorithms.final_test(rate, 0.05, obs, dim, np.linspace(0.15, 1, n), 0.7, 5)
        expected = row["expected"]
        if expected == "NULL":
            assert out is None, row
        elif expected in ["Accept", "Reject"]:
            assert out == expected, row
        else:
            np.testing.assert_allclose(np.ravel(out), vector(expected), rtol=1e-10, atol=1e-12, err_msg=str(row))
            if method.startswith("sample_filtering"):
                assert out.dtype == np.float64, row
    print("Python matches 54 geometry, 14 pipeline, 24 subalgorithm and 11 intermediate weight references.")


if __name__ == "__main__":
    main()
