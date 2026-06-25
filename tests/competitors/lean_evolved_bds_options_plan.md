# `lean_evolved_bds_options.m` development and verification plan

这个文件记录 `lean_evolved_bds_options.m` 的开发协议。目标是把当前
`Lean Evolved BDS` 做成一个带 `options` 和策略开关的实验平台，为以后把有效策略迁移到
`bds.m` 做准备。

重要约束：

- 不修改 `bds.m`。
- `lean_evolved_bds_options.m` 绝对不允许直接或间接调用 `bds.m`；可以复用 BDS private helpers。
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
| Solver-level stopping | Done | 支持 BDS-style `options.ftarget`，默认 `-inf`，并用 `get_exitflag("FTARGET_REACHED")` 返回。 |
| BDS-style block partitioning | Done | 支持 `options.num_blocks` 和 `options.grouped_direction_indices`，通过 `divide_direction_set.m` 生成 block；默认 `num_blocks=n` 与原始 Lean 完全一致。 |
| BDS-style options normalization | Done | 已抽到 `private/set_lean_evolved_bds_options.m`；按 BDS `set_options.m` 的已支持字段处理顺序归一化，未调用完整 `set_options.m`，未引入 unsupported outer-loop options。 |
| Explicit common options | Done | `expand/shrink/forcing_function/reduction_factor` 显式输入时支配外层更新；Lean defaults 可与 BDS defaults 不同。 |
| Reference Lean equivalence | Done | `verify_lean_evolved_bds_options.m` 已通过 `iseqiv.m` 比较 reference Lean vs options-default Lean；覆盖 `n=1:10`, `ir=0:20`, seeds `[12345,23456,34567]`, `prec=0`。 |
| BDS inner direct search reuse | Done | Block polling 现在直接调用 `tests/competitors/private/inner_direct_search.m`，即 `src/private/inner_direct_search.m` 的 symlink。 |
| BDS-style direction set | Done | 支持 `options.direction_set`，通过 `get_direction_set.m` 生成 base polling directions；Lean-only extra directions 仍动态生成，不并入 base direction set。 |
| BDS-style output/history | Done | Default Lean path 输出 `funcCount/fhist/message`；`output_xhist/output_alpha_hist/output_block_hist/output_grad_hist` 分别控制对应 histories，和 acceleration switches 解耦。 |
| No direct BDS call | Done | `lean_evolved_bds_options.m` 不调用 `bds.m`；只复用 BDS private helper。 |
| All-off BDS equivalence | Pending | 三项策略全关时不再绕到 `bds.m`；是否严格等价需要后续真实验证。 |
| Re-enable strategies | Done | Default all-on smoke: `lean_evolved_bds_options(fun,x0)` 与 `lean_evolved_bds(fun,x0)` 在 `iseqiv.m` strict sense 下等价。 |
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
- [x] 维数覆盖 `1:10`。
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
reference-default-algorithmic iseqiv suite passed.
lean_evolved_bds_options passed all iseqiv checks:
default all-on algorithmic behavior vs reference Lean, dims=1:10, ir=0:20,
seeds=[12345 23456 34567], prec=0;
BDS-style output contract and explicit direction_set smoke checks passed.
```

## 5. No direct BDS call

- [x] `lean_evolved_bds_options.m` 不再提供 `options.mode='bds-compatible'` 路由。
- [x] 三项策略全关时也不允许调用 `bds.m`。
- [x] 删除 `run_bds_compatible_core`、`ensure_bds_on_path`、`strip_lean_options_for_bds` 等 helper。
- [x] 保留对 BDS private helper 的复用，包括：

```matlab
eval_fun
inner_direct_search
get_exitflag
isrealscalar
```

- [ ] 三项策略全关时与 `bds.m` 是否完全一致尚未证明；后续要真实比较并逐项修外层行为，而不是绕到 `bds.m`。
- [ ] 后续需要对齐的基础行为：

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
- [ ] 在不修改 `bds.m`、且不从 `lean_evolved_bds_options.m` 调用 `bds.m` 的前提下，用 wrapper 统一验证入口：

```matlab
bds_for_iseqiv(fun, x0, options)
lean_evolved_bds_options_bds_compatible_for_iseqiv(fun, x0, options)
```

- [ ] 比较标准必须通过 `iseqiv.m`，`prec=0`。
- [ ] 维数覆盖 `1:5`，`ir=0:20`，multiple seeds。
- [ ] 完整运行 all-off vs BDS verification command。

## 7. Re-enable strategies and smoke benchmark

- [x] 打开所有 Lean Evolved BDS 策略。
- [x] 确认 default mode 仍与 `lean_evolved_bds.m` 在 `iseqiv.m` strict sense 下等价。
- [x] 本地小维度 smoke test 能正常返回，无 abnormal termination。
- [ ] 后续再决定是否跑 OptiProfiler profile 复查性能。

Smoke test result:

```text
default_equal=1 f=0/0 nf=215/215 exit=3/3
```

## 8. BDS inner search and history reuse

- [x] `lean_evolved_bds_options.m` 不再定义 local `inner_direct_search`。
- [x] Block polling 直接调用 `tests/competitors/private/inner_direct_search.m`，不再经过 `call_bds_inner_direct_search` wrapper。
- [x] Block loop 内按 BDS 风格直接设置 inner-search options，其中 `ftarget` 来自 `options.ftarget`，默认值为 `-inf`:

```matlab
suboptions.ftarget = ftarget;
suboptions.forcing_function = forcing_function;
suboptions.reduction_factor = reduction_factor;
suboptions.polling_inner = "opportunistic";
suboptions.cycling_inner = 1;
```

- [x] `expand`、`shrink`、`forcing_function`、`reduction_factor` 均来自 normalized options。
- [x] 外层 `update_base`、step expansion、step shrinkage 使用 BDS-style formulas:

```matlab
update_base = sub_fopt + reduction_factor(1) * forcing_function(alpha) < fbase;
expand step if sub_fopt + reduction_factor(3) * forcing_function(alpha) < fbase;
shrink step if sub_fopt + reduction_factor(2) * forcing_function(alpha) >= fbase;
```

- [x] Initial point、productive direction memory、extra extrapolation、sweep pattern、momentum probing 都按 `bds.m` 风格直接记录 `fhist/xhist/invalid_points`。
- [x] 删除通用 bookkeeping helper：`init_history`、`evaluate_and_record`、`append_inner_direct_search_history`、`best_recorded_point`。
- [x] 保留 Lean-only strategy helpers：`try_extrapolation`、`remember_direction`、`insert_memory_front`。
- [x] Initial point、BDS inner polling、productive direction memory、extra extrapolation、sweep pattern、momentum probing 都支持 `ftarget` 停止。
- [x] `output.funcCount`、`output.fhist`、`output.message` 默认输出。
- [x] `options.output_xhist=true` 时输出 `xhist/invalid_points`。
- [x] `options.output_alpha_hist=true` 时输出 `alpha_hist`，即 step-size history。
- [x] `options.output_block_hist=true` 时输出 `blocks_hist`。
- [x] `options.output_grad_hist=true` 时输出 `grad_hist/grad_xhist/grad_iter`；当前 Lean core 不估计梯度，所以这些字段为空，但输出契约与 BDS 对齐。

## 9. BDS-style block partitioning and direction set

- [x] 默认 base polling direction set 从硬编码 coordinate directions 改成：

```matlab
D = get_direction_set(n, options);
```

- [x] `options.direction_set` 支持显式输入；默认仍为 `eye(n)`，所以 default all-on path 和原始 Lean 完全一致。
- [x] Lean-only extra directions 不并入 `D`，而是在 outer loop 中继续动态生成：

```text
productive direction memory
sweep-level pattern direction
momentum extrapolation
```

- [x] 默认 block partition 从硬编码 coordinate blocks 改成：

```matlab
options.num_blocks = n;
grouped_direction_indices = divide_direction_set(n, options.num_blocks, options);
```

- [x] 支持 `options.num_blocks`，并让 `StepTolerance`、`alpha_init`、`alpha_all` 都按 `num_blocks` 解释。
- [x] 支持 BDS-style `options.grouped_direction_indices`。输入仍是 dimension indices，例如 `{[1 3], [2 4]}`；实际 polling direction indices 由 `divide_direction_set.m` 转成 `[d_i, -d_i]` 成对分组。
- [x] 暂不引入 `batch_size`、`block_visiting_pattern`、`replacement_delay`；当前外层仍是 sorted full sweep。
- [x] MATLAB smoke test 覆盖：

```text
default all-on vs lean_evolved_bds.m
num_blocks = 2
custom grouped_direction_indices = {[1 3], [2 4]}
explicit rotated direction_set
```

- [x] Acceptance test 仍严格通过 `iseqiv.m`:

```text
reference-default-algorithmic iseqiv suite passed.
lean_evolved_bds_options passed all iseqiv checks:
default all-on algorithmic behavior vs reference Lean, dims=1:10, ir=0:20,
seeds=[12345 23456 34567], prec=0;
BDS-style output contract and explicit direction_set smoke checks passed.
```

## 10. BDS-style options normalization

- [x] 把原来主文件里的 `default_options` 和相关 normalization helper 抽到：

```matlab
tests/competitors/private/set_lean_evolved_bds_options.m
```

- [x] 主文件现在只保留算法主体，通过以下调用取得已归一化 options：

```matlab
options = set_lean_evolved_bds_options(options, n, x0);
```

- [x] `set_lean_evolved_bds_options.m` 按 BDS `set_options.m` 的结构处理已支持字段：

```text
MaxFunctionEvaluations
num_blocks / grouped_direction_indices
direction_set
ftarget
StepTolerance
alpha_init
is_noisy / expand / shrink
forcing_function
reduction_factor
output_xhist
output_alpha_hist
output_block_hist
output_grad_hist
Lean-only strategy options
```

- [x] 保留 Lean reference 所需默认值，例如 `MaxFunctionEvaluations = 200*n` 和 plain `expand = 2.0`，以维持默认全开 strict equivalence。
- [x] 新增 `private/get_lean_evolved_bds_default_constant.m`，让 Lean defaults 与 BDS `get_default_constant.m` 解耦；显式传入的 common options 仍然优先。
- [x] `StepTolerance` 和 `alpha_init` 按 `num_blocks` 展开；`alpha_init = "auto"` 支持默认 coordinate-block 情况。
- [x] 加入 BDS-style `output_xhist` 和 `output_alpha_hist` memory guard。
- [x] 明确拒绝暂不支持的 BDS outer-loop options：

```matlab
batch_size
block_visiting_pattern
replacement_delay
```

- [x] 未直接调用 `bds.m`，也未整段调用 BDS `set_options.m`。
- [x] MATLAB smoke test 覆盖 default equivalence、custom block grouping、unsupported `batch_size` rejection。
- [x] MATLAB smoke test 覆盖 explicit common options：all-off Lean vs `bds.m` 在 `expand=1.8`、`reduction_factor=[0.1,0.2,0.3]`、`forcing_function=@(a)a^2` 时 `x/f/exit/nf/fhist` 完全一致。
- [x] Acceptance test 仍严格通过 `iseqiv.m`:

```text
reference-default-algorithmic iseqiv suite passed.
lean_evolved_bds_options passed all iseqiv checks:
default all-on algorithmic behavior vs reference Lean, dims=1:10, ir=0:20,
seeds=[12345 23456 34567], prec=0;
BDS-style output contract and explicit direction_set smoke checks passed.
```

## 11. Migration notes

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
