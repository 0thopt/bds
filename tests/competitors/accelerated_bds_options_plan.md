# Accelerated BDS Options Plan

这个文件只保留当前结论和验收入口。早期把
`accelerated_bds_options.m` 逐步贴近 `bds.m` 的诊断细节已经不再作为
当前维护路线图。

## Current State

- `lean_evolved_bds.m` 是固定的 historical reference。
- `accelerated_bds_options.m` 是带 options 的实验 solver，不直接或间接调用
  `bds.m`。
- 三个 acceleration strategies 只在 `accelerated_bds_options.m` 中维护，尚未迁移进
  `src/bds.m`：
  - `use_productive_direction_memory`
  - `use_sweep_pattern_direction`
  - `use_momentum_extrapolation`
- 这三个 switches 在 `accelerated_bds_options.m` 中默认都是 `true`，从而保持与
  `lean_evolved_bds.m` 的 reference behavior 一致。将三项开关显式设为 `false`
  时，它应该与 `bds.m` 在相同显式参数下保持一致。
- switches 与 `Algorithm` 正交：`cbds/pbds/rbds/pads/ds` 都可以打开这些加速。
- acceleration 默认参数采用 accelerated BDS / accelerated-CBDS 校准：
  - `productive_direction_memory_size = min(n, 5)`
  - `momentum_decay = 0.6`

## Strict Acceptance

当前只维护一个验证入口：

```matlab
addpath('/Users/lihaitian/Work/bds/tests');
verify_bds_acceleration
```

它严格通过 `tests/private/iseqiv.m` 验证两件事：

```text
1. acceleration switches off:
   accelerated_bds_options.m == bds.m
   for Algorithm = cbds/pbds/rbds/pads/ds,
   with matching explicit options

2. acceleration switches on:
   accelerated_bds_options.m == lean_evolved_bds.m
   for default base algorithm and Algorithm = cbds
```

## Interface Principle

加速机制本身不绑定 `Algorithm`。但是严格复现 historical reference 只声明在
默认 sorted-CBDS base algorithm 下成立，也就是不显式给 `Algorithm`，或者给
`Algorithm = "cbds"`。

如果用户设置：

```matlab
options.Algorithm = "pbds";
options.use_productive_direction_memory = true;
options.use_sweep_pattern_direction = true;
options.use_momentum_extrapolation = true;
```

那么含义是 **accelerated PBDS**，可以运行，但不声称等价于
`lean_evolved_bds.m`。

## Naming

论文和 profile 脚本里统一使用：

```text
accelerated BDS
```

代码层面目前不需要再增加一批 `*_for_iseqiv.m` wrapper；新的验证入口已经把
必要 wrapper 收在 `verify_bds_acceleration.m` 的局部函数中。
