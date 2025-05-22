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
The tests are **automated** by [GitHub Actions](https://docs.github.com/en/actions).
- [![Check Spelling](https://github.com/blockwise-direct-search/bds/actions/workflows/spelling.yml/badge.svg)](https://github.com/blockwise-direct-search/bds/actions/workflows/spelling.yml)

The following tests are implemented by [Optiprofiler](https://github.com/optiprofiler/optiprofiler).

- [Tests](https://github.com/zeroth-order-optimization/bds/actions) at [zeroth-order-optimization/bds](https://github.com/zeroth-order-optimization/bds)

    - [![Profile original cbds with original cbds with reduction factor 6x, small](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_6_small.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_6_small.yml)
    - [![Profile original cbds with original cbds with reduction factor 6x, big](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_6_big.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_6_big.yml)
    - [![Profile original cbds with original cbds with reduction factor 8x, small](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_8_small.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_8_small.yml)
    - [![Profile original cbds with original cbds with reduction factor 8x, big](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_8_big.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_8_big.yml)
    - [![Profile original cbds with original cbds with reduction factor 10x, small](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_10_small.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_10_small.yml)
    - [![Profile original cbds with original cbds with reduction factor 10x, big](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_10_big.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_10_big.yml)
    - [![Profile original cbds with original cbds with reduction factor 12x, small](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_12_small.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_12_small.yml)
    - [![Profile original cbds with original cbds with reduction factor 12x, big](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_12_big.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_cbds_orig_cbds_reduction_factor_12_big.yml)