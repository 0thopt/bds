# `lean_evolved_bds_options.m` development and verification plan

这个文件记录 `lean_evolved_bds_options.m` 的开发协议。目标是把当前
`Lean Evolved BDS` 做成一个带 `options` 和策略开关的实验平台，为以后把有效策略迁移到
`bds.m` 做准备。

重要约束：

- 不修改 `bds.m`。
- 保留 `lean_evolved_bds.m` 作为固定 reference implementation。
- 所有实验性修改都只进入 `lean_evolved_bds_options.m` 和必要的测试/说明文件。
- 默认调用 `lean_evolved_bds_options(fun, x0)` 时，应当保持和 `lean_evolved_bds(fun, x0)` 完全一致。
- 对同语言 MATLAB comparison，必须严格通过 `tests/private/iseqiv.m` 这一套验证；需要 trace comparison 时，也只能作为 debugging 辅助，不作为 acceptance criterion。

## Status Dashboard

| Stage | Status | Evidence / next action |
|---|---:|---|
| Baseline preservation | Done | `lean_evolved_bds.m` 保持不动，`lean_evolved_bds_options.m` 是实验副本。 |
| Options interface | Done | `lean_evolved_bds_options(fun, x0, options)` 支持默认 options。 |
| Strategy switches | Done | `use_productive_direction_memory`, `use_sweep_pattern_direction`, `use_momentum_extrapolation` 已接入。 |
| Reference Lean equivalence | Done | `verify_lean_evolved_bds_options.m` 已通过 `iseqiv.m` 比较 reference Lean vs options-default Lean；覆盖 `n=1:5`, `ir=0:20`, seeds `[12345,23456,34567]`, `prec=0`。 |
| BDS-compatible mode | Done | `options.mode='bds-compatible'` 或三项策略全关时走 `bds.m` core；不修改 `bds.m`。 |
| BDS-compatible equivalence | Done | `bds_for_iseqiv` vs `lean_evolved_bds_options_bds_compatible_for_iseqiv` 已通过同一套 `iseqiv.m` 覆盖。 |
| Re-enable strategies | Done | Default all-on smoke: `lean_evolved_bds_options(fun,x0)` 与 `lean_evolved_bds(fun,x0)` 逐字段一致。 |
| Migration notes | Done | 已记录策略迁移到 `bds.m` 框架时的建议插入点和风险。 |

## 1. Baseline preservation

- [x] 复制 `lean_evolved_bds.m` 为 `lean_evolved_bds_options.m`。
- [x] 只修改副本的 function name 和头部说明，不修改算法主体。
- [x] 确认 `lean_evolved_bds_options.m` 的算法主体和 `lean_evolved_bds.m` 完全一致。
- [x] 对 `lean_evolved_bds_options.m` 做最小 MATLAB smoke test。

当前基准：

```matlab
[x, f, exitflag, output] = lean_evolved_bds_options(@(x) sum((x - [1; -2]).^2), [0; 0]);
```

得到：

```text
x = [1; -2]
f = 0
exitflag = 3
output.funcCount = 134
```

## 2. Add options interface

- [x] 把接口扩展为：

```matlab
function [xopt, fopt, exitflag, output] = lean_evolved_bds_options(fun, x0, options)
```

- [x] 支持 `nargin < 3` 时自动使用默认 options。
- [x] 默认 options 必须复现当前 `lean_evolved_bds.m` 行为。
- [x] 把硬编码参数集中到 options/default options 中，包括：

```matlab
MaxFunctionEvaluations
StepTolerance
alpha_init
expand
shrink
productive_direction_memory_size
momentum_decay
```

## 3. Strategy switches

- [x] 增加 `productive direction memory` 开关：

```matlab
options.use_productive_direction_memory
```

- [x] 增加 `sweep-level pattern direction` 开关：

```matlab
options.use_sweep_pattern_direction
```

- [x] 增加 `momentum extrapolation` 开关：

```matlab
options.use_momentum_extrapolation
```

- [x] 默认全部开启，保证默认行为等于 `lean_evolved_bds.m`。
- [x] 所有开关关闭时，算法应退化为一个更接近原始 BDS 的 coordinate/block direct search core。

## 4. Trace harness against reference Lean

- [x] 写 `iseqiv` wrapper，用 `tests/private/iseqiv.m` 比较 reference Lean 和 options-default Lean。
- [x] 比较：

```matlab
lean_evolved_bds_reference_for_iseqiv(fun, x0, options)
lean_evolved_bds_options_default_for_iseqiv(fun, x0, options)
```

- [x] 要求严格通过 `iseqiv.m` 体系，`prec=0`。
- [x] 维数覆盖 `1:5`。
- [x] 覆盖 `ir=0:20`，尽量触发 `iseqiv.m` 中的 randomized options、row input、tough/noisy/failure branches。
- [x] 使用 multiple seeds：

```matlab
seed_values = [12345, 23456, 34567];
```

- [x] 完整运行升级后的 verification command。

当前验证命令：

```matlab
addpath('/Users/lihaitian/Work/bds/tests');
verify_lean_evolved_bds_options
```

当前结果：

```text
reference-default iseqiv suite passed.
bds-compatible iseqiv suite passed.
lean_evolved_bds_options passed all iseqiv checks:
dims=1:5, ir=0:20, seeds=[12345 23456 34567], prec=0.
```

## 5. BDS-compatible mode design

- [x] 只读取 `bds.m` 的行为，不修改 `bds.m`。
- [x] 定义一个最小兼容模式：

```matlab
options.mode = 'bds-compatible';
```

- [x] 在该模式下默认关闭 Lean Evolved BDS 的额外策略：

```matlab
options.use_productive_direction_memory = false;
options.use_sweep_pattern_direction = false;
options.use_momentum_extrapolation = false;
```

- [x] 三项策略都关闭时，也进入 BDS-compatible core。
- [x] 当前 BDS-compatible core 直接调用 `bds.m`，这是零误差基线；后续迁移策略时，它提供同语言 strict reference。
- [x] 明确需要对齐的基础行为：

```text
initial evaluation
direction order
block/cycle order
success criterion
alpha expansion/shrinkage
MaxFunctionEvaluations boundary behavior
NaN/Inf handling
output shape and final point convention
```

## 6. Trace harness against `bds.m`

- [x] 读取 `bds.m` 的调用接口和关键 options。
- [x] 在不修改 `bds.m` 的前提下，用 wrapper 统一验证入口：

```matlab
bds_for_iseqiv(fun, x0, options)
lean_evolved_bds_options_bds_compatible_for_iseqiv(fun, x0, options)
```

- [x] 比较标准必须通过 `iseqiv.m`，`prec=0`。
- [x] 维数覆盖 `1:5`，`ir=0:20`，multiple seeds。
- [x] 完整运行升级后的 verification command。

## 7. Re-enable strategies and smoke benchmark

- [x] 打开所有 Lean Evolved BDS 策略。
- [x] 确认 default mode 仍与 `lean_evolved_bds.m` 逐字段一致。
- [x] 本地小维度 smoke test 能正常返回，无 abnormal termination。
- [ ] 后续再决定是否跑 OptiProfiler profile 复查性能。

Smoke test result:

```text
default_equal=1 f=0/0 nf=215/215 exit=3/3
bds_compatible f=1.93384e-06 exit=1 nf=80 fields=6
all_switches_off_equal_bds_compatible=1 f=1.93384e-06/1.93384e-06 nf=80/80 exit=1/1
```

## 8. Migration notes

- [x] 记录哪些策略最终适合迁移到 `bds.m`。
- [x] 记录每个策略需要插入 `bds.m` 框架的位置。
- [x] 记录哪些策略暂时不迁移，以及原因。

当前建议迁移的策略：

- `productive direction memory`: 适合迁移。它记录已经产生下降的 displacement，在后续 sweep 开始前优先试探，属于低成本 exploitation。
- `sweep-level pattern direction`: 适合迁移。它把一个 sweep 内的总位移当作 pattern direction，在一次成功的 block sweep 后尝试更大步长。
- `momentum extrapolation`: 适合迁移但应保持可关闭。它对连续 sweep 的 pattern direction 做 exponential smoothing，可在谷地或一致下降趋势中提供更稳定的 extrapolation。

建议插入点：

- `productive direction memory` 应插在 `bds.m` outer loop 的 block polling 之前，也就是每个 sweep 进入 `for i = 1:length(block_indices)` 前。
- block 内成功更新 `xbase/fbase` 后，记录该 block 的 displacement 到 memory。
- sweep 结束后、更新全局 best point 后，可加入 `sweep-level pattern direction` 和 `momentum extrapolation` 的 extrapolation block。
- 所有新增策略必须受 options switch 控制，并且 switches off 时必须继续通过 `iseqiv.m` 与当前 `bds.m` 严格一致。

暂时不建议迁移的部分：

- 任何依赖维数的低维专用 probing 不进入 `bds.m` 主线。它作为 solver engineering 可能有意义，但论文和主算法中会增加解释成本，而且前期实验显示贡献不稳定。
