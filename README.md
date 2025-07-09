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

The following tests are implemented by [Optiprofiler](https://github.com/optiprofiler/optiprofiler).
  
- [Tests](https://github.com/dfopt/bds/actions) at [dfopt/bds](https://github.com/dfopt/bds)

    - [![Profile cbds with func window size 10, tol 06 and 09, big](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_window_size_10_tol_06_09_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_func_window_size_10_tol_06_09_big.yml)
    - [![Profile cbds with grad window size 01, tol 03 and 06, cd, default, big](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_01_tol_03_06_cd_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_01_tol_03_06_cd_default_big.yml)
    - [![Profile cbds with grad window size 02, tol 03 and 06, cd, default, big](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_02_tol_03_06_cd_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_02_tol_03_06_cd_default_big.yml)
    - [![Profile cbds with grad window size 03, tol 03 and 06, cd, default, big](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_03_tol_03_06_cd_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_03_tol_03_06_cd_default_big.yml)
    - [![Profile cbds with grad window size 05, tol 03 and 06, cd, default, big](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_05_tol_03_06_cd_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_05_tol_03_06_cd_default_big.yml)
    - [![Profile cbds with grad window size 01, tol 03 and 06, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_01_tol_03_06_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_01_tol_03_06_mix_default_big.yml)
    - [![Profile cbds with grad window size 02, tol 03 and 06, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_02_tol_03_06_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_02_tol_03_06_mix_default_big.yml)
    - [![Profile cbds with grad window size 03, tol 03 and 06, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_03_tol_03_06_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_03_tol_03_06_mix_default_big.yml)
    - [![Profile cbds with grad window size 05, tol 03 and 06, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_05_tol_03_06_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_05_tol_03_06_mix_default_big.yml)
    - [![Profile cbds with grad window size 01, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_01_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_01_tol_03_06_cd_mix_default_big.yml)
    - [![Profile cbds with grad window size 02, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_02_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_02_tol_03_06_cd_mix_default_big.yml)
    - [![Profile cbds with grad window size 03, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_03_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_03_tol_03_06_cd_mix_default_big.yml)
    - [![Profile cbds with grad window size 05, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_05_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_cbds_grad_window_size_05_tol_03_06_cd_mix_default_big.yml)
    - [![Profile rbds with one batch size, grad window size 01, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_rbds_one_batch_size_grad_window_size_01_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_rbds_one_batch_size_grad_window_size_01_tol_03_06_cd_mix_default_big.yml)
    - [![Profile rbds with one batch size, grad window size 02, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_rbds_one_batch_size_grad_window_size_02_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_rbds_one_batch_size_grad_window_size_02_tol_03_06_cd_mix_default_big.yml)
    - [![Profile rbds with one batch size, grad window size 03, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_rbds_one_batch_size_grad_window_size_03_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_rbds_one_batch_size_grad_window_size_03_tol_03_06_cd_mix_default_big.yml)
    - [![Profile rbds with one batch size, grad window size 05, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_rbds_one_batch_size_grad_window_size_05_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_rbds_one_batch_size_grad_window_size_05_tol_03_06_cd_mix_default_big.yml)
    - [![Profile rbds with quarter n batch size, grad window size 01, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_rbds_quarter_n_batch_size_grad_window_size_01_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_rbds_quarter_n_batch_size_grad_window_size_01_tol_03_06_cd_mix_default_big.yml)
    - [![Profile rbds with quarter n batch size, grad window size 02, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_rbds_quarter_n_batch_size_grad_window_size_02_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_rbds_quarter_n_batch_size_grad_window_size_02_tol_03_06_cd_mix_default_big.yml)
    - [![Profile rbds with quarter n batch size, grad window size 03, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_rbds_quarter_n_batch_size_grad_window_size_03_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_rbds_quarter_n_batch_size_grad_window_size_03_tol_03_06_cd_mix_default_big.yml)
    - [![Profile rbds with quarter n batch size, grad window size 05, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_rbds_quarter_n_batch_size_grad_window_size_05_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_rbds_quarter_n_batch_size_grad_window_size_05_tol_03_06_cd_mix_default_big.yml)
    - [![Profile rbds with half n batch size, grad window size 01, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_rbds_half_n_batch_size_grad_window_size_01_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_rbds_half_n_batch_size_grad_window_size_01_tol_03_06_cd_mix_default_big.yml)
    - [![Profile rbds with half n batch size, grad window size 02, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_rbds_half_n_batch_size_grad_window_size_02_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_rbds_half_n_batch_size_grad_window_size_02_tol_03_06_cd_mix_default_big.yml)
    - [![Profile rbds with half n batch size, grad window size 03, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_rbds_half_n_batch_size_grad_window_size_03_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_rbds_half_n_batch_size_grad_window_size_03_tol_03_06_cd_mix_default_big.yml)
    - [![Profile rbds with half n batch size, grad window size 05, tol 03 and 06, cd, mix, default, big](https://github.com/dfopt/bds/actions/workflows/profile_rbds_half_n_batch_size_grad_window_size_05_tol_03_06_cd_mix_default_big.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_rbds_half_n_batch_size_grad_window_size_05_tol_03_06_cd_mix_default_big.yml)