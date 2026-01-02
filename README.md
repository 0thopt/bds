# Blockwise Direct Search (BDS)

BDS is a package for solving nonlinear optimization problems without using derivatives. The current version can handle unconstrained problems. 

## What is BDS?

BDS is a derivative-free package using blockwise direct-search methods. The current version is implemented in MATLAB, and it is being implemented in other programming languages.

See [Haitian LI's presentation](https://lht97.github.io/documents/DFOS2024.pdf) on BDS for more information.

## How to install BDS?

1. Clone this repository. You should then get a folder named `bds` containing this README file and the
[`setup.m`](https://github.com/blockwise-direct-search/bds/blob/main/setup.m) file.

2. In the command window of MATLAB, change your directory to the above-mentioned folder, and execute

```matlab
setup
```

If the above succeeds, then the package `bds` is installed and ready to use. Try `help bds` for more information.

We do not support MATLAB R2017a or earlier. If there exists any problems, please open an issue by
https://github.com/blockwise-direct-search/bds/issues.

## The coverage of unit test (offered by [Codecov](https://about.codecov.io/))

[![Codecov](https://img.shields.io/codecov/c/github/blockwise-direct-search/bds?style=for-the-badge&logo=codecov)](https://app.codecov.io/github/blockwise-direct-search/bds)

## Test of BDS.
The tests are **automated** by [GitHub Actions](https://docs.github.com/en/actions).
- [![Check Spelling](https://github.com/blockwise-direct-search/bds/actions/workflows/spelling.yml/badge.svg)](https://github.com/blockwise-direct-search/bds/actions/workflows/spelling.yml)
- [![Unit test of BDS](https://github.com/blockwise-direct-search/bds/actions/workflows/unit_test.yml/badge.svg)](https://github.com/blockwise-direct-search/bds/actions/workflows/unit_test.yml)
- [![Coverage test of BDS](https://github.com/blockwise-direct-search/bds/actions/workflows/unit_test_coverage.yml/badge.svg)](https://github.com/blockwise-direct-search/bds/actions/workflows/unit_test_coverage.yml)
- [![Verify norma](https://github.com/zeroth-order-optimization/bds/actions/workflows/verify_norma.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/verify_norma.yml)
- [![Gradient test of BDS](https://github.com/zeroth-order-optimization/bds/actions/workflows/gradient_test.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/gradient_test.yml)

The following tests are implemented by [Optiprofiler](https://github.com/optiprofiler/optiprofiler).

- [Tests](https://github.com/dfopt/bds/actions) at [dfopt/bds](https://github.com/dfopt/bds)

- [![Profile cbds func 10, tol 03 and 06, small, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_03_06_small_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_03_06_small_matcutest.yml)
- [![Profile cbds func 10, tol 03 and 06, small, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_03_06_small_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_03_06_small_s2mpj.yml)
- [![Profile cbds func 10, tol 03 and 06, big, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_03_06_big_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_03_06_big_matcutest.yml)
- [![Profile cbds func 10, tol 03 and 06, big, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_03_06_big_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_03_06_big_s2mpj.yml)
- [![Profile cbds func 10, tol 03 and 06, large, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_03_06_large_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_03_06_large_matcutest.yml)
- [![Profile cbds func 10, tol 03 and 06, large, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_03_06_large_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_03_06_large_s2mpj.yml)
- [![Profile cbds func 10, tol 06 and 09, small, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_06_09_small_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_06_09_small_matcutest.yml)
- [![Profile cbds func 10, tol 06 and 09, small, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_06_09_small_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_06_09_small_s2mpj.yml)
- [![Profile cbds func 10, tol 06 and 09, big, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_06_09_big_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_06_09_big_matcutest.yml)
- [![Profile cbds func 10, tol 06 and 09, big, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_06_09_big_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_06_09_big_s2mpj.yml)
- [![Profile cbds func 10, tol 06 and 09, large, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_06_09_large_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_06_09_large_matcutest.yml)
- [![Profile cbds func 10, tol 06 and 09, large, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_06_09_large_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_10_tol_06_09_large_s2mpj.yml)
- [![Profile cbds func 15, tol 03 and 06, small, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_03_06_small_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_03_06_small_matcutest.yml)
- [![Profile cbds func 15, tol 03 and 06, small, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_03_06_small_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_03_06_small_s2mpj.yml)
- [![Profile cbds func 15, tol 03 and 06, big, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_03_06_big_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_03_06_big_matcutest.yml)
- [![Profile cbds func 15, tol 03 and 06, big, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_03_06_big_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_03_06_big_s2mpj.yml)
- [![Profile cbds func 15, tol 03 and 06, large, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_03_06_large_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_03_06_large_matcutest.yml)
- [![Profile cbds func 15, tol 03 and 06, large, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_03_06_large_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_03_06_large_s2mpj.yml)
- [![Profile cbds func 15, tol 06 and 09, small, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_06_09_small_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_06_09_small_matcutest.yml)
- [![Profile cbds func 15, tol 06 and 09, small, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_06_09_small_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_06_09_small_s2mpj.yml)
- [![Profile cbds func 15, tol 06 and 09, big, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_06_09_big_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_06_09_big_matcutest.yml)
- [![Profile cbds func 15, tol 06 and 09, big, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_06_09_big_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_06_09_big_s2mpj.yml)
- [![Profile cbds func 15, tol 06 and 09, large, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_06_09_large_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_06_09_large_matcutest.yml)
- [![Profile cbds func 15, tol 06 and 09, large, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_06_09_large_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_15_tol_06_09_large_s2mpj.yml)
- [![Profile cbds func 20, tol 03 and 06, small, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_03_06_small_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_03_06_small_matcutest.yml)
- [![Profile cbds func 20, tol 03 and 06, small, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_03_06_small_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_03_06_small_s2mpj.yml)
- [![Profile cbds func 20, tol 03 and 06, big, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_03_06_big_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_03_06_big_matcutest.yml)
- [![Profile cbds func 20, tol 03 and 06, big, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_03_06_big_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_03_06_big_s2mpj.yml)
- [![Profile cbds func 20, tol 03 and 06, large, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_03_06_large_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_03_06_large_matcutest.yml)
- [![Profile cbds func 20, tol 03 and 06, large, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_03_06_large_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_03_06_large_s2mpj.yml)
- [![Profile cbds func 20, tol 06 and 09, small, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_06_09_small_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_06_09_small_matcutest.yml)
- [![Profile cbds func 20, tol 06 and 09, small, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_06_09_small_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_06_09_small_s2mpj.yml)
- [![Profile cbds func 20, tol 06 and 09, big, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_06_09_big_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_06_09_big_matcutest.yml)
- [![Profile cbds func 20, tol 06 and 09, big, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_06_09_big_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_06_09_big_s2mpj.yml)
- [![Profile cbds func 20, tol 06 and 09, large, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_06_09_large_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_06_09_large_matcutest.yml)
- [![Profile cbds func 20, tol 06 and 09, large, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_06_09_large_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_20_tol_06_09_large_s2mpj.yml)
