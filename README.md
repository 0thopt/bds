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

## Test of BDS.
The tests are **automated** by [GitHub Actions](https://docs.github.com/en/actions) and
the following tests are implemented by [Optiprofiler](https://github.com/optiprofiler/optiprofiler).

- [Tests](https://github.com/zeroth-order-optimization/bds/actions) at [zeroth-order-optimization/bds](https://github.com/zeroth-order-optimization/bds)

    - [![Profile original cbds with original cbds with reduction factor 3x, small, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_3_small_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_3_small_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 3x, big, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_3_big_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_3_big_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 3x, large, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_3_large_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_3_large_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 4x, small, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_4_small_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_4_small_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 4x, big, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_4_big_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_4_big_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 4x, large, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_4_large_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_4_large_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 6x, small, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_6_small_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_6_small_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 6x, big, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_6_big_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_6_big_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 6x, large, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_6_large_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_6_large_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 8x, small, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_8_small_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_8_small_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 8x, big, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_8_big_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_8_big_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 8x, large, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_8_large_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_8_large_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 10x, small, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_10_small_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_10_small_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 10x, big, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_10_big_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_10_big_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 10x, large, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_10_large_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_10_large_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 12x, small, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_12_small_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_12_small_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 12x, big, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_12_big_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_12_big_s2mpj.yml)
    - [![Profile original cbds with original cbds with reduction factor 12x, large, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_12_large_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_12_large_s2mpj.yml)
    - [![Asymptotic Insensitivity of the Reduction Factors, big, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_reduction_factors_plain_big_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_reduction_factors_plain_big_s2mpj.yml)
    - [![Robustness Analysis of the Update Thresholds, big, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_rho_plain_big_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_rho_plain_big_s2mpj.yml)
    - [![Sensitivity Analysis of the Acceptance Threshold, big, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_rho1_plain_big_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_rho1_plain_big_s2mpj.yml)
