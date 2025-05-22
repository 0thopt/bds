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

- [Tests](https://github.com/libblades/bds/actions) at [libblades/bds](https://github.com/libblades/bds)

    - [![Profile cbds and nomad, small](https://github.com/libblades/bds/actions/workflows/profile_cbds_nomad_small.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_cbds_nomad_small.yml)
    - [![Profile original cbds and nomad, small](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_small.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_small.yml)
    - [![Profile cbds and nomad, big](https://github.com/libblades/bds/actions/workflows/profile_cbds_nomad_big.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_cbds_nomad_big.yml)
    - [![Profile original cbds and nomad, big](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_big.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_orig_cbds_nomad_big.yml)
    - [![Profile original cbds with forcing function of quadratic vs cubic, small](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_cubic_small.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_cubic_small.yml)
    - [![Profile original cbds with forcing function of quadratic vs cubic, big](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_cubic_big.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_cubic_big.yml)
    - [![Profile original cbds with forcing function of quadratic vs quartic, small](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_quartic_small.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_quartic_small.yml)
    - [![Profile original cbds with forcing function of quadratic vs quartic, big](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_quartic_small.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_quartic_small.yml)
    - [![Profile original cbds with forcing function of quadratic vs quintic, small](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_quintic_small.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_quintic_small.yml)
    - [![Profile original cbds with forcing function of quadratic vs quintic, big](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_quintic_big.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_quintic_big.yml)
    - [![Profile original cbds with forcing function of quadratic vs sextic, small](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_sextic_small.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_sextic_small.yml)
    - [![Profile original cbds with forcing function of quadratic vs sextic, big](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_sextic_big.yml/badge.svg)](https://github.com/libblades/bds/actions/workflows/profile_quadratic_vs_sextic_big.yml)