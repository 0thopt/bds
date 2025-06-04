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

The following tests are implemented by [Optiprofiler](https://github.com/optiprofiler/optiprofiler).

- [Tests](https://github.com/derivative-free-optimization/bds/actions) at [derivative-free-optimization/bds](https://github.com/derivative-free-optimization/bds)
    - [![Profile original cbds, true, 1 with original cbds, false, 1, big](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_true_1_orig_cbds_false_1_big.yml/badge.svg)](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_true_1_orig_cbds_false_1_big.yml)
    - [![Profile original cbds, true, 3 with original cbds, false, 3, big](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_true_3_orig_cbds_false_3_big.yml/badge.svg)](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_true_3_orig_cbds_false_3_big.yml)
    - [![Profile original cbds, half, true, 1 with original cbds, half, false, 1, big](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_half_true_1_orig_cbds_half_false_1_big.yml/badge.svg)](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_half_true_1_orig_cbds_half_false_1_big.yml)
    - [![Profile original cbds, half, true, 2 with original cbds, half, false, 2, big](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_half_true_2_orig_cbds_half_false_2_big.yml/badge.svg)](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_half_true_2_orig_cbds_half_false_2_big.yml)
    - [![Profile original cbds, half, true, 3 with original cbds, half, false, 3, big](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_half_true_3_orig_cbds_half_false_3_big.yml/badge.svg)](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_half_true_3_orig_cbds_half_false_3_big.yml)
    - [![Profile original cbds, half, true, 4 with original cbds, half, false, 4, big](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_half_true_4_orig_cbds_half_false_4_big.yml/badge.svg)](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_half_true_4_orig_cbds_half_false_4_big.yml)
    - [![Profile original cbds, quarter, true, 1 with original cbds, quarter, false, 1, big](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_quarter_true_1_orig_cbds_quarter_false_1_big.yml/badge.svg)](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_quarter_true_1_orig_cbds_quarter_false_1_big.yml)
    - [![Profile original cbds, quarter, true, 2 with original cbds, quarter, false, 2, big](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_quarter_true_2_orig_cbds_quarter_false_2_big.yml/badge.svg)](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_quarter_true_2_orig_cbds_quarter_false_2_big.yml)
    - [![Profile original cbds, quarter, true, 3 with original cbds, quarter, false, 3, big](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_quarter_true_3_orig_cbds_quarter_false_3_big.yml/badge.svg)](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_quarter_true_3_orig_cbds_quarter_false_3_big.yml)
    - [![Profile original cbds, quarter, true, 4 with original cbds, quarter, false, 4, big](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_quarter_true_4_orig_cbds_quarter_false_4_big.yml/badge.svg)](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_cbds_quarter_true_4_orig_cbds_quarter_false_4_big.yml)
    - [![Profile original ds, true, 1 with original ds, false, 1, big](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_ds_true_1_orig_ds_false_1_big.yml/badge.svg)](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_ds_true_1_orig_ds_false_1_big.yml)
    - [![Profile original ds, true, 2 with original ds, false, 2, big](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_ds_true_2_orig_ds_false_2_big.yml/badge.svg)](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_ds_true_2_orig_ds_false_2_big.yml)
    - [![Profile original ds, true, 3 with original ds, false, 3, big](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_ds_true_3_orig_ds_false_3_big.yml/badge.svg)](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_ds_true_3_orig_ds_false_3_big.yml)
    - [![Profile original ds, true, 4 with original ds, false, 4, big](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_ds_true_4_orig_ds_false_4_big.yml/badge.svg)](https://github.com/derivative-free-optimization/bds/actions/workflows/profile_orig_ds_true_4_orig_ds_false_4_big.yml)
