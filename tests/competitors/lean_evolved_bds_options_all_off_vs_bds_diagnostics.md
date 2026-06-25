# `lean_evolved_bds_options(all switches off)` vs `bds.m` diagnostics

本文只记录诊断结果，不修改 solver。目标是弄清楚：

```matlab
lean_evolved_bds_options(fun, x0, options_all_off)
```

在关闭 Lean Evolved BDS 的三个 acceleration switches 后，和 `bds.m` 还有哪些差异。

这里的 `options_all_off` 指：

```matlab
options.use_productive_direction_memory = false;
options.use_sweep_pattern_direction = false;
options.use_momentum_extrapolation = false;
```

## Summary

当前结论是：**all-off Lean is not yet strictly equivalent to `bds.m`**。

不过差异不是一类问题。初步可以分成三层：

1. **Default option mismatch**：最明显的是 `expand`。`bds.m` 默认 `expand = 1.8`，而 Lean reference 为了保持和 `lean_evolved_bds.m` 一致，plain 默认 `expand = 2.0`。
2. **Unsupported / unused BDS options**：`bds.m` 支持 `Algorithm`、`batch_size`、`block_visiting_pattern`、`replacement_delay`、function-value stopping、estimated-gradient stopping 等；all-off Lean 当前不完整支持。`direction_set` 已接入。
3. **Output contract mismatch**：即使数值轨迹完全一致，输出字段仍不同。这里的目标不是只让 all-off mode 对齐；`lean_evolved_bds_options.m` 一旦作为 options-enabled solver，就应该始终采用 BDS-style output contract，和 acceleration switches 的开关状态无关。

## Diagnostic Setup

诊断使用两个入口：

```matlab
bds_for_iseqiv(fun, x0, options)
lean_evolved_bds_options_bds_compatible_for_iseqiv(fun, x0, options)
```

注意：这里没有调用 `iseqiv.m` 本身，因为 `iseqiv.m` 在失败时会进入 `keyboard`，不适合批量收集差异。诊断脚本复刻了 `verify_lean_evolved_bds_options.m` 中的 toy problem 和 `iseqiv`-like option generation，只做 comparison and logging。

维度与随机设置：

```text
dims = 1:5
ir = 0:20
seeds = [12345, 23456, 34567]
total cases = 315
```

## Confirmed Issues

### 1. Default `expand` differs

**Symptom.** 在简单二次函数上，只用默认 options 时两者轨迹不同：

```text
default | BDS f 1.996e-13 exit 3 nf 171
        | Lean f 0.000e+00 exit 3 nf 95
        | xdiff 4.468e-07, fhist_len 171/95
```

固定相同 `expand` 后，轨迹可以完全一致：

```text
expand_2   | BDS nf 95  | Lean nf 95  | xdiff 0 | fhist_tail 0
expand_1p8 | BDS nf 171 | Lean nf 171 | xdiff 0 | fhist_tail 0
```

**Likely cause.**

```text
bds.m default:        expand = get_default_constant("expand") = 1.8
Lean reference path:  expand = 2.0
```

这是一个真实的 default contract 差异。Lean 当前保留 `expand=2.0` 是为了默认全开时严格等价于 `lean_evolved_bds.m`。

### 2. Output fields differ even when trajectory matches

**Symptom.** 在 `expand` 显式对齐后，简单二次函数的 numerical trajectory 可完全一致，但 output fields 仍不同：

```text
fields_same = 0
```

例子：

```text
BDS fields:
funcCount, xhist, invalid_points, fhist, message

Lean all-off fields:
funcCount, alpha_all, fbase, xbase, iterations, xhist, invalid_points, fhist
```

**Correct target.** 这个问题不应该依赖三个 acceleration switches 的状态。只要调用的是 `lean_evolved_bds_options.m`，它的 output contract 都应该向 `bds.m` 对齐：

```text
Always BDS-style output contract for lean_evolved_bds_options.m.
No all-off-only special casing.
```

**Likely cause.** 当前 `lean_evolved_bds_options.m` 仍保留 Lean-specific diagnostics；`bds.m` 有 `message` 和可选 block/alpha/gradient histories。

这是 output contract 差异，不一定代表算法轨迹不同。

### 3. Done - Nonzero `reduction_factor` changes behavior

**Symptom.** 在简单二次函数上设置：

```matlab
options.expand = 1.8;
options.reduction_factor = [0.1, 0.2, 0.3];
```

结果：

```text
reduction_factor_nonzero
BDS  f 1.013e-13 exit 3 nf 128
Lean f 1.996e-13 exit 3 nf 171
xdiff 1.285e-07, fhist_len 128/171
```

**Likely cause.** `bds.m` uses `reduction_factor` in outer-loop update rules:

```text
update_base condition
alpha expansion condition
alpha shrink condition
```

All-off Lean currently hard-codes a simpler rule around:

```matlab
is_expand = sub_fopt + eps * alpha^2 < fbase
```

and base update is effectively `sub_fopt < fbase`.

**Resolution.** `lean_evolved_bds_options.m` now normalizes `forcing_function` and
`reduction_factor` as explicit common options. The block loop passes both into
`inner_direct_search` and uses BDS-style outer update formulas for `update_base`,
step expansion, and step shrinkage.

**Verification.** With all Lean acceleration switches off and explicit common
options

```matlab
options.expand = 1.8;
options.shrink = 0.5;
options.forcing_function = @(a) a^2;
options.reduction_factor = [0.1, 0.2, 0.3];
```

the simple quadratic smoke test gives:

```text
explicit common dx=0 df=0 exit=3/3 nf=128/128 fhist=0
```

### 4. `Algorithm = "ds"` is not mirrored

**Symptom.**

```text
algorithm_ds
BDS  f 2.280e-13 exit 3 nf 139
Lean f 1.996e-13 exit 3 nf 171
xdiff 9.243e-07, fhist_len 139/171
```

**Likely cause.** In `bds.m`, `Algorithm = "ds"` changes defaults:

```text
num_blocks = 1
batch_size = 1
```

Lean all-off currently does not implement the full `Algorithm` priority layer from `set_options.m`.

### 5. Done - Custom `direction_set` is mirrored

**Symptom.**

```text
custom_direction_set
BDS  f 1.092e-12 exit 3 nf 192
Lean f 1.996e-13 exit 3 nf 171
xdiff 1.471e-06, fhist_len 192/171
```

**Original likely cause.** `bds.m` constructs polling directions using:

```matlab
D = get_direction_set(n, options);
```

Lean all-off used to construct coordinate directions directly:

```matlab
D(:, 1:2:end) = eye(n);
D(:, 2:2:end) = -eye(n);
```

**Resolution.** `lean_evolved_bds_options.m` now constructs the base polling
directions in the same BDS-style way:

```matlab
D = get_direction_set(n, options);
```

The Lean-only directions remain separate and dynamic:

```text
productive direction memory
sweep-level pattern direction
momentum extrapolation
```

**Verification.** `verify_lean_evolved_bds_options.m` includes an explicit
rotated `direction_set` smoke check. With all three Lean acceleration switches
off and explicit common options, `bds.m` and `lean_evolved_bds_options.m` agree
exactly on `x/f/exit/nf/fhist` for that rotated two-dimensional case.

### 6. Unsupported BDS outer-loop options can error in Lean

**Symptom.**

```text
unsupported_batch_size
BDS  returns normally
Lean error:
lean_evolved_bds_options:UnsupportedOuterOption
```

**Likely cause.** This is intentional at the moment:

```matlab
unsupported = {'batch_size', 'block_visiting_pattern', 'replacement_delay'};
```

Lean all-off deliberately rejects these until the corresponding BDS outer-loop behavior is implemented.

## Batch Statistics

### Base comparison

This uses the current defaults. In particular, Lean all-off still has its Lean default `expand = 2.0`, while `bds.m` defaults to `expand = 1.8`.

```text
total = 315
both_return = 315
bds_error = 0
lean_error = 0
numeric_exact_ignoring_fields = 66 / 315
field_same = 0 / 315
x_or_f_diff = 226
exit_or_nf_diff = 184
fhist_diff = 249
```

Representative first failure:

```text
n=1, ir=0, seed=12345
BDS  f -1.975e-03 exit 1 nf 25
Lean f -1.762e-03 exit 1 nf 25
xdiff 1.931e-02, fdiff 2.130e-04
fhist_tail 1.535e+00, fhist_len 25/25
```

### Force `expand = 1.8`

This forces the main default mismatch to agree with `bds.m`.

```text
total = 315
both_return = 315
bds_error = 0
lean_error = 0
numeric_exact_ignoring_fields = 90 / 315
field_same = 0 / 315
x_or_f_diff = 122
exit_or_nf_diff = 102
fhist_diff = 225
```

Important observation:

```text
ir = 0: 15 / 15 cases are numerically exact after forcing expand = 1.8.
```

So the basic default coordinate-block path is already close once `expand` is aligned. The remaining failures come mostly from randomized options and tough/problem variants that exercise BDS features Lean all-off has not fully mirrored.

## Per-`ir` Snapshot With `expand = 1.8`

Columns:

```text
ir total bds_error lean_error numeric_exact numeric_diff
```

```text
ir=00 15 0 0 15 0
ir=01 15 0 0 4 11
ir=02 15 0 0 3 12
ir=03 15 0 0 3 12
ir=04 15 0 0 1 14
ir=05 15 0 0 7 8
ir=06 15 0 0 7 8
ir=07 15 0 0 10 5
ir=08 15 0 0 3 12
ir=09 15 0 0 5 10
ir=10 15 0 0 5 10
ir=11 15 0 0 3 12
ir=12 15 0 0 1 14
ir=13 15 0 0 2 13
ir=14 15 0 0 2 13
ir=15 15 0 0 4 11
ir=16 15 0 0 3 12
ir=17 15 0 0 3 12
ir=18 15 0 0 1 14
ir=19 15 0 0 5 10
ir=20 15 0 0 3 12
```

## Initial Priority List For Discussion

建议后续逐条讨论，而不是一次性修改：

1. **Done - Output contract**: `lean_evolved_bds_options.m` 的 output 已改成始终保持 BDS-style output contract，和三个 acceleration switches 的状态无关。默认返回 `funcCount/fhist/message`；`output_xhist/output_alpha_hist/output_block_hist/output_grad_hist` 分别控制对应 histories，包括 step-size history `alpha_hist`。
2. **Done - Default `expand` conflict**: 默认值可以不同。Lean 默认仍保持 `expand = 2.0` 以维持 default all-on vs `lean_evolved_bds.m` 的 strict equivalence；但显式传入 `options.expand` 时，该值会支配算法行为。
3. **Done - Outer update rule**: `reduction_factor` / `forcing_function` 已纳入 options layer，外层 `update_base`、step expansion、step shrinkage 已使用 BDS-style formulas。
4. **Done - BDS direction set**: 已引入 `get_direction_set`，Lean 支持显式 `options.direction_set`。
5. **BDS option layer**: 是否引入 `Algorithm` priority logic，并开始考虑 `batch_size / block_visiting_pattern / replacement_delay`?
6. **Function-value / estimated-gradient stopping**: 这些是 BDS solver-level stopping criteria，是否属于 all-off equivalence 的目标范围?

当前最保守的推进方式是：每次只选一条，改完后同时跑两类验证。注意：如果 output contract 改成 BDS-style，那么 default all-on vs `lean_evolved_bds.m` 就不应再用“output fields 完全一致”作为 acceptance criterion；应把 algorithmic equivalence 和 output contract 分开验证。

```text
1. default all-on vs lean_evolved_bds.m: algorithmic equivalence
   Compare xopt, fopt, exitflag, funcCount, and history values as needed,
   but do not require Lean-reference output fieldnames.

2. lean_evolved_bds_options.m output contract:
   BDS-style fields should be returned regardless of acceleration switch states.
   Verified by `verify_lean_evolved_bds_options`.

3. all-off vs bds.m:
   diagnostic/iseqiv subset, with output contract comparison enabled when
   the numerical trajectory is expected to match.
```
