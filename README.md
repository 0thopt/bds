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
- [![Stress test of BDS](https://github.com/blockwise-direct-search/bds/actions/workflows/stress_test.yml/badge.svg)](https://github.com/blockwise-direct-search/bds/actions/workflows/stress_test.yml)
- [![Parallel test of BDS](https://github.com/blockwise-direct-search/bds/actions/workflows/parallel_test.yml/badge.svg)](https://github.com/blockwise-direct-search/bds/actions/workflows/parallel_test.yml)
- [![Recursive test of BDS](https://github.com/blockwise-direct-search/bds/actions/workflows/recursive_test.yml/badge.svg)](https://github.com/blockwise-direct-search/bds/actions/workflows/recursive_test.yml)
- [![Verify norma](https://github.com/zeroth-order-optimization/bds/actions/workflows/verify_norma.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/verify_norma.yml)

The following tests are implemented by [Optiprofiler](https://github.com/optiprofiler/optiprofiler).
- [Tests](https://github.com/zeroth-order-optimization/bds/actions) at [zeroth-order-optimization/bds](https://github.com/zeroth-order-optimization/bds)

    - [![Profile original cbds and original ds using optiprofiler, small, matcutest](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_orig_cbds_orig_ds_small_matcutest.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_orig_cbds_orig_ds_small_matcutest.yml)
    - [![Profile original cbds and original ds using optiprofiler, small, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_orig_cbds_orig_ds_small_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_orig_cbds_orig_ds_small_s2mpj.yml)
    - [![Profile original cbds and original ds using optiprofiler, big, matcutest](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_orig_cbds_orig_ds_big_matcutest.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_orig_cbds_orig_ds_big_matcutest.yml)
    - [![Profile original cbds and original ds using optiprofiler, big, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_orig_cbds_orig_ds_big_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_orig_cbds_orig_ds_big_s2mpj.yml)
    - [![Profile original cbds and original ds using optiprofiler, large, matcutest](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_orig_cbds_orig_ds_large_matcutest.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_orig_cbds_orig_ds_large_matcutest.yml)
    - [![Profile original cbds and original ds using optiprofiler, large, s2mpj](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_orig_cbds_orig_ds_large_s2mpj.yml/badge.svg)](https://github.com/zeroth-order-optimization/bds/actions/workflows/profile_orig_cbds_orig_ds_large_s2mpj.yml)

- [Tests](https://github.com/bladesopt/bds/actions) at [bladesopt/bds](https://github.com/bladesopt/bds)

    - [![Profile original cbds and newuoa using optiprofiler, small, matcutest](https://github.com/bladesopt/bds/actions/workflows/profile_orig_cbds_newuoa_small_matcutest.yml/badge.svg)](https://github.com/bladesopt/bds/actions/workflows/profile_orig_cbds_newuoa_small_matcutest.yml)
    - [![Profile original cbds and newuoa using optiprofiler, small, s2mpj](https://github.com/bladesopt/bds/actions/workflows/profile_orig_cbds_newuoa_small_s2mpj.yml/badge.svg)](https://github.com/bladesopt/bds/actions/workflows/profile_orig_cbds_newuoa_small_s2mpj.yml)
    - [![Profile original cbds and newuoa using optiprofiler, big, matcutest](https://github.com/bladesopt/bds/actions/workflows/profile_orig_cbds_newuoa_big_matcutest.yml/badge.svg)](https://github.com/bladesopt/bds/actions/workflows/profile_orig_cbds_newuoa_big_matcutest.yml)
    - [![Profile original cbds and newuoa using optiprofiler, big, s2mpj](https://github.com/bladesopt/bds/actions/workflows/profile_orig_cbds_newuoa_big_s2mpj.yml/badge.svg)](https://github.com/bladesopt/bds/actions/workflows/profile_orig_cbds_newuoa_big_s2mpj.yml)
    - [![Profile original cbds and newuoa using optiprofiler, large, matcutest](https://github.com/bladesopt/bds/actions/workflows/profile_orig_cbds_newuoa_large_matcutest.yml/badge.svg)](https://github.com/bladesopt/bds/actions/workflows/profile_orig_cbds_newuoa_large_matcutest.yml)
    - [![Profile original cbds and newuoa using optiprofiler, large, s2mpj](https://github.com/bladesopt/bds/actions/workflows/profile_orig_cbds_newuoa_large_s2mpj.yml/badge.svg)](https://github.com/bladesopt/bds/actions/workflows/profile_orig_cbds_newuoa_large_s2mpj.yml)

- [Tests](https://github.com/derivative-free-optimization/bds/actions) at [derivative-free-optimization/bds](https://github.com/derivative-free-optimization/bds)
    
- [Tests](https://github.com/0thopt/bds/actions) at [0thopt/bds](https://github.com/0thopt/bds)

    - [![Profile original cbds and bfo using optiprofiler, small, matcutest](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_bfo_small_matcutest.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_bfo_small_matcutest.yml)
    - [![Profile original cbds and bfo using optiprofiler, small, s2mpj](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_bfo_small_s2mpj.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_bfo_small_s2mpj.yml) 
    - [![Profile original cbds and bfo using optiprofiler, big, matcutest](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_bfo_big_matcutest.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_bfo_big_matcutest.yml) 
    - [![Profile original cbds and bfo using optiprofiler, big, s2mpj](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_bfo_big_s2mpj.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_bfo_big_s2mpj.yml)   
    - [![Profile original cbds and bfo using optiprofiler, large, matcutest](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_bfo_large_matcutest.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_bfo_large_matcutest.yml) 
    - [![Profile original cbds and bfo using optiprofiler, large, s2mpj](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_bfo_large_s2mpj.yml/badge.svg)](https://github.com/0thopt/bds/actions/workflows/profile_orig_cbds_bfo_large_s2mpj.yml)  
  

- [Tests](https://github.com/dfopt/bds/actions) at [dfopt/bds](https://github.com/dfopt/bds)

    - [![Profile original cbds and bfgs using optiprofiler, small, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_orig_cbds_bfgs_small_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_orig_cbds_bfgs_small_matcutest.yml)
    - [![Profile original cbds and bfgs using optiprofiler, small, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_orig_cbds_bfgs_small_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_orig_cbds_bfgs_small_s2mpj.yml)
    - [![Profile original cbds and bfgs using optiprofiler, big, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_orig_cbds_bfgs_big_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_orig_cbds_bfgs_big_matcutest.yml)
    - [![Profile original cbds and bfgs using optiprofiler, big, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_orig_cbds_bfgs_big_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_orig_cbds_bfgs_big_s2mpj.yml)
    - [![Profile original cbds and bfgs using optiprofiler, large, matcutest](https://github.com/dfopt/bds/actions/workflows/profile_orig_cbds_bfgs_large_matcutest.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_orig_cbds_bfgs_large_matcutest.yml)
    - [![Profile original cbds and bfgs using optiprofiler, large, s2mpj](https://github.com/dfopt/bds/actions/workflows/profile_orig_cbds_bfgs_large_s2mpj.yml/badge.svg)](https://github.com/dfopt/bds/actions/workflows/profile_orig_cbds_bfgs_large_s2mpj.yml)

- [Tests](https://github.com/gradient-free-opt/bds/actions) at [gradient-free-opt/bds](https://github.com/gradient-free-opt/bds)

    - [![Profile original cbds and simplex using optiprofiler, small, matcutest](https://github.com/gradient-free-opt/bds/actions/workflows/profile_orig_cbds_simplex_small_matcutest.yml/badge.svg)](https://github.com/gradient-free-opt/bds/actions/workflows/profile_orig_cbds_simplex_small_matcutest.yml)
    - [![Profile original cbds and simplex using optiprofiler, small, s2mpj](https://github.com/gradient-free-opt/bds/actions/workflows/profile_orig_cbds_simplex_small_s2mpj.yml/badge.svg)](https://github.com/gradient-free-opt/bds/actions/workflows/profile_orig_cbds_simplex_small_s2mpj.yml)
    - [![Profile original cbds and simplex using optiprofiler, big, matcutest](https://github.com/gradient-free-opt/bds/actions/workflows/profile_orig_cbds_simplex_big_matcutest.yml/badge.svg)](https://github.com/gradient-free-opt/bds/actions/workflows/profile_orig_cbds_simplex_big_matcutest.yml)
    - [![Profile original cbds and simplex using optiprofiler, big, s2mpj](https://github.com/gradient-free-opt/bds/actions/workflows/profile_orig_cbds_simplex_big_s2mpj.yml/badge.svg)](https://github.com/gradient-free-opt/bds/actions/workflows/profile_orig_cbds_simplex_big_s2mpj.yml)
    - [![Profile original cbds and simplex using optiprofiler, large, matcutest](https://github.com/gradient-free-opt/bds/actions/workflows/profile_orig_cbds_simplex_large_matcutest.yml/badge.svg)](https://github.com/gradient-free-opt/bds/actions/workflows/profile_orig_cbds_simplex_large_matcutest.yml)
    - [![Profile original cbds and simplex using optiprofiler, large, s2mpj](https://github.com/gradient-free-opt/bds/actions/workflows/profile_orig_cbds_simplex_large_s2mpj.yml/badge.svg)](https://github.com/gradient-free-opt/bds/actions/workflows/profile_orig_cbds_simplex_large_s2mpj.yml)
    - [![Profile cbds and pds using optiprofiler, big](https://github.com/gradient-free-opt/bds/actions/workflows/profile_cbds_pds_big.yml/badge.svg)](https://github.com/gradient-free-opt/bds/actions/workflows/profile_cbds_pds_big.yml)
    - [![Profile cbds and pds using optiprofiler, small](https://github.com/gradient-free-opt/bds/actions/workflows/profile_cbds_pds_small.yml/badge.svg)](https://github.com/gradient-free-opt/bds/actions/workflows/profile_cbds_pds_small.yml)


- [Tests](https://github.com/libblades/bds/actions) at [libblades/bds](https://github.com/libblades/bds)

    - [![Profile original cbds and nomad, small, matcutest](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_small_matcutest.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_small_matcutest.yml)
    - [![Profile original cbds and nomad, small, s2mpj](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_small_s2mpj.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_small_s2mpj.yml)
    - [![Profile original cbds and nomad, big, matcutest](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_big_matcutest.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_big_matcutest.yml)
    - [![Profile original cbds and nomad, big, s2mpj](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_big_s2mpj.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_big_s2mpj.yml)  
    - [![Profile original cbds and nomad, large, matcutest](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_large_matcutest.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_large_matcutest.yml)
    - [![Profile original cbds and nomad, large, s2mpj](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_large_s2mpj.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_large_s2mpj.yml) 

- [Tests](https://github.com/opt-lab/bds/actions) at [opt-lab/bds](https://github.com/opt-lab/bds)

    - [![Profile cbds with randomized orthogonal matrix input, small, s2mpj](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_randomized_orthogonal_small_s2mpj.yml/badge.svg)](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_randomized_orthogonal_small_s2mpj.yml)
    - [![Profile cbds with randomized orthogonal matrix input, big, s2mpj](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_randomized_orthogonal_big_s2mpj.yml/badge.svg)](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_randomized_orthogonal_big_s2mpj.yml)
    - [![Profile cbds with randomized orthogonal matrix input, large, s2mpj](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_randomized_orthogonal_large_s2mpj.yml/badge.svg)](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_randomized_orthogonal_large_s2mpj.yml)
    - [![Profile cbds with randomized gaussian matrix input, small, s2mpj](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_randomized_gaussian_small_s2mpj.yml/badge.svg)](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_randomized_gaussian_small_s2mpj.yml)
    - [![Profile cbds with randomized gaussian matrix input, big, s2mpj](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_randomized_gaussian_big_s2mpj.yml/badge.svg)](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_randomized_gaussian_big_s2mpj.yml)
    - [![Profile cbds with randomized gaussian matrix input, large, s2mpj](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_randomized_gaussian_large_s2mpj.yml/badge.svg)](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_randomized_gaussian_large_s2mpj.yml)
    - [![Profile cbds with different number of blocks, small, s2mpj](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_block_number_small_s2mpj.yml/badge.svg)](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_block_number_small_s2mpj.yml)
    - [![Profile cbds with different number of blocks, big, s2mpj](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_block_number_big_s2mpj.yml/badge.svg)](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_block_number_big_s2mpj.yml)
    - [![Profile cbds with different number of blocks, large, s2mpj](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_block_number_large_s2mpj.yml/badge.svg)](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_block_number_large_s2mpj.yml)
    - [![Profile cbds with direction set from x0, small, s2mpj](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_direction_set_from_x0_small_s2mpj.yml/badge.svg)](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_direction_set_from_x0_small_s2mpj.yml)
    - [![Profile cbds with direction set from x0, big, s2mpj](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_direction_set_from_x0_big_s2mpj.yml/badge.svg)](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_direction_set_from_x0_big_s2mpj.yml)
    - [![Profile cbds with direction set from x0, large, s2mpj](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_direction_set_from_x0_large_s2mpj.yml/badge.svg)](https://github.com/opt-lab/bds/actions/workflows/profile_cbds_direction_set_from_x0_large_s2mpj.yml)


- [Tests](https://github.com/optimlib/bds/actions) at [optimlib/bds](https://github.com/optimlib/bds)
 
    - [![Profile rbds with different number of batch_size, big](https://github.com/optimlib/bds/actions/workflows/profile_rbds_batch_size_big.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_rbds_batch_size_big.yml)
    - [![Profile rbds with different number of batch_size, small](https://github.com/optimlib/bds/actions/workflows/profile_rbds_batch_size_small.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_rbds_batch_size_small.yml)
    - [![Profile rbds with different replacement_delay, big](https://github.com/optimlib/bds/actions/workflows/profile_rbds_replacement_delay_big.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_rbds_replacement_delay_big.yml)
    - [![Profile rbds with different replacement_delay, small](https://github.com/optimlib/bds/actions/workflows/profile_rbds_replacement_delay_small.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_rbds_replacement_delay_small.yml)
    - [![Profile rbds with nsb n and rbds with nsb 1 and delay n-1, big](https://github.com/optimlib/bds/actions/workflows/profile_rbds_nsb_n_rbds_nsb_1_delay_n-1_big.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_rbds_nsb_n_rbds_nsb_1_delay_n-1_big.yml) 
    - [![Profile rbds with nsb n and rbds with nsb 1 and delay n-1, small](https://github.com/optimlib/bds/actions/workflows/profile_rbds_nsb_n_rbds_nsb_1_delay_n-1_small.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_rbds_nsb_n_rbds_nsb_1_delay_n-1_small.yml) 
    - [![Profile pbds and rbds with nsb n, big](https://github.com/optimlib/bds/actions/workflows/profile_pbds_rbds_nsb_n_big.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_pbds_rbds_nsb_n_big.yml) 
    - [![Profile pbds and rbds with nsb n, small](https://github.com/optimlib/bds/actions/workflows/profile_pbds_rbds_nsb_n_small.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_pbds_rbds_nsb_n_small.yml) 
    - [![Profile pbds and rbds with nsb 1 and delay n-1, big](https://github.com/optimlib/bds/actions/workflows/profile_pbds_rbds_nsb_1_delay_n-1_big.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_pbds_rbds_nsb_1_delay_n-1_big.yml)
    - [![Profile pbds and rbds with nsb 1 and delay n-1, small](https://github.com/optimlib/bds/actions/workflows/profile_pbds_rbds_nsb_1_delay_n-1_small.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_pbds_rbds_nsb_1_delay_n-1_small.yml)
    - [![Profile cbds and rbds with nsb n, big](https://github.com/optimlib/bds/actions/workflows/profile_cbds_rbds_nsb_n_big.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_cbds_rbds_nsb_n_big.yml) 
    - [![Profile cbds and rbds with nsb n, small](https://github.com/optimlib/bds/actions/workflows/profile_cbds_rbds_nsb_n_small.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_cbds_rbds_nsb_n_small.yml) 
    - [![Profile cbds and rbds with nsb 1 and delay n-1, big](https://github.com/optimlib/bds/actions/workflows/profile_cbds_rbds_nsb_1_delay_n-1_big.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_cbds_rbds_nsb_1_delay_n-1_big.yml)
    - [![Profile cbds and rbds with nsb 1 and delay n-1, small](https://github.com/optimlib/bds/actions/workflows/profile_cbds_rbds_nsb_1_delay_n-1_small.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_cbds_rbds_nsb_1_delay_n-1_small.yml)  
    - [![Profile rbds with one batch size and pds, big](https://github.com/optimlib/bds/actions/workflows/profile_rbds_batch_size_1_pds_big.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_rbds_batch_size_1_pds_big.yml)
    - [![Profile rbds with one batch size and pds, small](https://github.com/optimlib/bds/actions/workflows/profile_rbds_batch_size_1_pds_small.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_rbds_batch_size_1_pds_small.yml)
    - [![Profile rbds with one batch size and original ds, big](https://github.com/optimlib/bds/actions/workflows/profile_rbds_batch_size_1_ds_orig_big.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_rbds_batch_size_1_ds_orig_big.yml)
    - [![Profile rbds with one batch size and original ds, small](https://github.com/optimlib/bds/actions/workflows/profile_rbds_batch_size_1_ds_orig_small.yml/badge.svg)](https://github.com/optimlib/bds/actions/workflows/profile_rbds_batch_size_1_ds_orig_small.yml)

- [Tests](https://github.com/gradient-free-optimization/bds/actions) at [gradient-free-optimization/bds](https://github.com/gradient-free-optimization/bds)

    - [![Profile original cbds and original pads using optiprofiler, small, s2mpj](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_pads_small_s2mpj.yml/badge.svg)](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_pads_small_s2mpj.yml) 
    - [![Profile original cbds and original pads using optiprofiler, big, s2mpj](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_pads_big_s2mpj.yml/badge.svg)](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_pads_big_s2mpj.yml) 
    - [![Profile original cbds and original pads using optiprofiler, large, s2mpj](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_pads_large_s2mpj.yml/badge.svg)](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_pads_large_s2mpj.yml)
    - [![Profile original cbds and original rbds using optiprofiler, small, s2mpj](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_rbds_small_s2mpj.yml/badge.svg)](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_rbds_small_s2mpj.yml)  
    - [![Profile original cbds and original rbds using optiprofiler, big, s2mpj](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_rbds_big_s2mpj.yml/badge.svg)](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_rbds_big_s2mpj.yml) 
    - [![Profile original cbds and original rbds using optiprofiler, large, s2mpj](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_rbds_large_s2mpj.yml/badge.svg)](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_rbds_large_s2mpj.yml)
    - [![Profile original cbds and original pbds using optiprofiler, small, s2mpj](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_pbds_small_s2mpj.yml/badge.svg)](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_pbds_small_s2mpj.yml)  
    - [![Profile original cbds and original pbds using optiprofiler, big, s2mpj](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_pbds_big_s2mpj.yml/badge.svg)](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_pbds_big_s2mpj.yml) 
    - [![Profile original cbds and original pbds using optiprofiler, large, s2mpj](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_pbds_large_s2mpj.yml/badge.svg)](https://github.com/gradient-free-optimization/bds/actions/workflows/profile_orig_cbds_orig_pbds_large_s2mpj.yml)
 