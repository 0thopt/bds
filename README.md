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
- [![Verify norma](https://github.com/zeroth-order-optimization/bds/actions/workflows/verify_norma.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/verify_norma.yml)

The following tests are implemented by [Optiprofiler](https://github.com/optiprofiler/optiprofiler).
    
- [Tests](https://github.com/0thopt/bds/actions) at [0thopt/bds](https://github.com/0thopt/bds)

    - [![Profile original cbds and lht1, big](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_lht1_big.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_lht1_big.yml)
    - [![Profile original cbds and lht1, small](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_lht1_small.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_lht1_small.yml)
    - [![Profile original cbds and fm, big](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_fm_big.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_fm_big.yml)
    - [![Profile original cbds and fm, small](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_fm_small.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_fm_small.yml)
    - [![Profile original cbds and lam1, big](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_lam1_big.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_lam1_big.yml)
    - [![Profile original cbds and lam1, small](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_lam1_small.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_lam1_small.yml)
    - [![Profile original cbds and original lam1, big](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_lam1_big.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_lam1_big.yml)
    - [![Profile original cbds and original lam1, small](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_lam1_small.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_lam1_small.yml)
    - [![Profile original cbds and original lht1, big](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_lht1_big.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_lht1_big.yml)
    - [![Profile original cbds and original lht1, small](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_lht1_small.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_lht1_small.yml)
    - [![Profile original cbds and cbds with terminating outer, small](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_cbds_terminate_outer_small.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_cbds_terminate_outer_small.yml)
    - [![Profile original cbds and cbds with terminating outer, big](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_cbds_terminate_outer_big.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_cbds_terminate_outer_big.yml)
    - [![Profile original cbds with original cbds not preserving order, small](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_cbds_not_preserve_order_small.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_cbds_not_preserve_order_small.yml)
    - [![Profile original cbds with original cbds not preserving order, big](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_cbds_not_preserve_order_big.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_orig_cbds_not_preserve_order_big.yml)
    - [![Profile lam1 with original lam1 not preserving order, small](https://github.com/0thopt/bds/actions/workflows/profile_lam1_orig_lam1_not_preserve_order_small.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_lam1_orig_lam1_not_preserve_order_small.yml)
    - [![Profile lam1 with original lam1 not preserving order, big](https://github.com/0thopt/bds/actions/workflows/profile_lam1_orig_lam1_not_preserve_order_big.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_lam1_orig_lam1_not_preserve_order_big.yml)
    - [![Profile lht1 and lam1, big](https://github.com/0thopt/bds/actions/workflows/profile_lht1_lam1_big.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_lht1_lam1_big.yml)
    - [![Profile lht1 and lam1, small](https://github.com/0thopt/bds/actions/workflows/profile_lht1_lam1_small.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_lht1_lam1_small.yml)
    - [![Profile original lam1 and sd box lam1, small](https://github.com/0thopt/bds/actions/workflows/profile_orig_lam1_sd_box_lam1_small.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_lam1_sd_box_lam1_small.yml)
    - [![Profile original lam1 and sd box lam1, big](https://github.com/0thopt/bds/actions/workflows/profile_orig_lam1_sd_box_lam1_big.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_lam1_sd_box_lam1_big.yml)
    - [![Profile sd box lam, sd box lam1, and sd box lam2, small](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam_sd_box_lam1_sd_box_lam2_small.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam_sd_box_lam1_sd_box_lam2_small.yml)
    - [![Profile sd box lam, sd box lam1, and sd box lam2, big](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam_sd_box_lam1_sd_box_lam2_big.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam_sd_box_lam1_sd_box_lam2_big.yml)
    - [![Profile sd box lam1 and original sd box lam1, small](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam1_sd_box_lam1_orig_small.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam1_sd_box_lam1_orig_small.yml)
    - [![Profile sd box lam1 and original sd box lam1, big](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam1_sd_box_lam1_orig_big.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam1_sd_box_lam1_orig_big.yml)
    - [![Profile sd box lam1 and sd box lam1 not allowing small step, small](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam1_sd_box_lam1_not_allow_small_step_small.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam1_sd_box_lam1_not_allow_small_step_small.yml)
    - [![Profile sd box lam1 and sd box lam1 not allowing small step, big](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam1_sd_box_lam1_not_allow_small_step_big.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam1_sd_box_lam1_not_allow_small_step_big.yml)
    - [![Profile sd box lam2 and sd box lam2 not allowing small step, small](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam2_sd_box_lam2_not_allow_small_step_small.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam2_sd_box_lam2_not_allow_small_step_small.yml)
    - [![Profile sd box lam2 and sd box lam2 not allowing small step, big](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam2_sd_box_lam2_not_allow_small_step_big.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam2_sd_box_lam2_not_allow_small_step_big.yml)
    - [![Profile sd box lam2 and original sd box lam2, small](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam2_sd_box_lam2_orig_small.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam2_sd_box_lam2_orig_small.yml)
    - [![Profile sd box lam2 and original sd box lam2, big](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam2_sd_box_lam2_orig_big.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_sd_box_lam2_sd_box_lam2_orig_big.yml)