# DS vs CBDS under High Noise: Investigation Plan

## Research Question

我们观察到的主要现象不是十个精度水平取平均后的 solver ranking，而是：在与噪声强度相匹配的
practical tolerance 上，cyclic block direct search (`CBDS`) 前期效率很高，但 profile 较早进入
plateau；classical direct search (`DS`) 前期较慢，却可能在较大预算下继续解决新问题并最终反超。
本调查要回答：

> Why is CBDS much more efficient early, why does its solved coverage plateau,
> and why can DS continue making progress and eventually overtake it at
> noise-matched practical tolerances?

最终结论必须同时具备三层证据：

1. **Aggregate evidence**：区分 early efficiency 与 eventual coverage，并把反超分解到具体
   problem-runs。
2. **Trajectory evidence**：代表问题上的 evaluation history 能显示两种算法的行为差异。
3. **Structural evidence**：行为差异可以结合目标函数表达式和结构解释，而不是只描述曲线。

## Status Dashboard

| Stage | Task | Status | Required output |
| --- | --- | --- | --- |
| 0 | Fix scope, terminology, and decision rules | Completed | 本文件 |
| 1 | Verify solver equivalence except for `Algorithm` | Completed | Configuration audit |
| 2 | Verify the exact OptiProfiler noise model and seed semantics | Completed | Noise-model note |
| 3 | Run or recover the aggregate DS-vs-CBDS experiment | Completed | Pairwise profiles and raw results |
| 4 | Rank problem-level contributions to the performance gap | Completed | Ranked problem table |
| 5 | Select representative problems and counterexamples | Completed | Case-study shortlist |
| 6 | Perform paired replay with complete histories | Pending | Replay dataset |
| 7 | Measure false decisions and step-size dynamics | Pending | Mechanism statistics |
| 8 | Analyze the objective functions of selected problems | Pending | Function-structure case studies |
| 9 | Test the proposed mechanism with minimal interventions | Pending | Mechanism-validation results |
| 10 | Check rotated high-noise problems as external validation | Pending | Rotation sensitivity note |
| 11 | Write the evidence-backed conclusion | Pending | Final investigation report |

状态只在对应 deliverable 已生成并检查后改为 `Completed`。一个实验成功启动不能算作该
stage 已完成。

## Primary Scope

主调查严格固定为：

- Problem library: `S2MPJ`
- Problem type: unconstrained
- Dimension range: `6-50`
- Function-evaluation budget: `200n`
- Solvers: `ds-baseline-200n` and `cbds-baseline-200n`
- Acceleration switches: all off
- Main features: `noisy_1e-1` and `noisy_1e-2`
- Control feature: `plain`
- Noisy runs in aggregate screening: `n_runs = 5`
- Plain runs in aggregate screening: `n_runs = 1`
- Step tolerance: `1e-6`

## Primary Tolerances and Estimands

主分析只研究不低于噪声强度的 practical tolerances：

\[
\mathcal T(\sigma)=\{\tau\in\{10^{-1},\ldots,10^{-10}\}:\tau\geq\sigma\}.
\]

因此 primary `(sigma, tau)` pairs 固定为：

| Noise level `sigma` | Primary `tau` values |
| --- | --- |
| `1e-1` | `1e-1` |
| `1e-2` | `1e-1`, `1e-2` |

这里的 `tau >= sigma` 是预先固定的 `noise-matched practical tolerance rule`。OptiProfiler 的
relative progress tolerance `tau` 与 mixed-noise parameter `sigma` 不是同一个物理量，因此不把
`tau = sigma` 宣称为严格的 statistical noise floor。

每个 primary pair 的主要 estimands 按以下顺序报告：

1. **Eventual coverage**：在 `200n` 内达到该 `tau` 的 problem-run fraction；
2. **Solved-set decomposition**：`both solved`, `DS-only`, `CBDS-only`, `neither`；
3. **Early efficiency**：双方都 solved 时的 time-to-target ratio，以及 performance profile 左端；
4. **Sustained crossing**：DS 曲线从哪一点开始持续高于 CBDS；
5. **Profile plateau**：data profile 中 solved coverage 何时基本停止增加；
6. **Per-problem stability**：五次 runs 中上述分类是否稳定。

Performance profile 和 data profile 承担不同角色：performance profile 衡量相对最快 solver 的
evaluation ratio；data profile 衡量随 normalized absolute budget 增加的 solved coverage。因而
performance profile 变平不能直接解释为 objective trajectory 停止下降；`CBDS stops optimizing`
必须由 data profile 和逐问题 history 共同支持。

单个 relevant `tau` 的 profile-area score 作为 secondary summary。OptiProfiler 默认把
`tau = 1e-1,...,1e-10` 十张 history-based performance profiles 的面积平均后得到的 solver score
只作为 `all-tau diagnostic`，不再用于回答主研究问题，也不用于 case selection。

`linearly_transformed_noisy_1e-1` and
`linearly_transformed_noisy_1e-2` 属于 secondary validation。它们不能与未旋转结果混合
统计，也不能在主机制尚未明确时取代主调查。

`500n`、其他 problem libraries 和其他噪声强度不属于主范围。只有当 `200n` 结果提出
一个无法区分的替代解释时，才把它们作为 targeted sensitivity checks。

## Solver Definitions and Fairness Audit

这项调查中的 `BDS` 特指 `CBDS baseline`，不是 accelerated BDS。两个 solver 均通过
`accelerated_bds_options.m` 运行，三个 acceleration switches 全部关闭：

| Setting | DS | CBDS |
| --- | --- | --- |
| `Algorithm` | `ds` | `cbds` |
| `use_productive_direction_memory` | `false` | `false` |
| `use_sweep_pattern_direction` | `false` | `false` |
| `use_momentum_extrapolation` | `false` | `false` |
| `MaxFunctionEvaluations` | `200n` | `200n` |
| `StepTolerance` | `1e-6` | `1e-6` |

在运行主实验前，必须生成 configuration audit，逐项比较：

- initial point and initial objective evaluation;
- direction set and direction ordering;
- initial step sizes;
- `expand`, `shrink`, and forcing-function parameters;
- polling and cycling rules;
- stopping criteria and target handling;
- random seed and random-stream construction;
- output-point convention;
- all options not determined by `Algorithm`.

除了 `Algorithm` 引起的必要行为差异，不允许存在其他未记录的配置差异。如果默认值随
`Algorithm` 改变，必须把这些差异列出来，并判断它们属于算法定义还是 experimental
confounder。

## Exact Noise Model

当前 OptiProfiler MATLAB 的 `noisy` feature 默认采用：

- `distribution = 'gaussian'`;
- `noise_type = 'mixed'`;
- `noise_mode = 'random'`.

因此 solver 在第 (k) 次评价 (x) 时观察到

\[
\widetilde f_k(x)
= f(x) + \max\{1, |f(x)|\}\,\sigma\,\xi_k,
\qquad \xi_k \sim \mathcal N(0,1),
\]

其中主实验取 \(\sigma\in\{10^{-1},10^{-2}\}\)。条件标准差为

\[
\operatorname{std}[\widetilde f_k(x)-f(x)\mid x]
= \max\{1,|f(x)|\}\sigma.
\]

这个尺度依赖非常重要。对一次 trial step \(x\to x^+\)，定义真实信号与局部噪声比：

\[
\Delta f_{\mathrm{true}} = f(x)-f(x^+),
\qquad
\mathrm{SNR}_{\mathrm{step}}
= \frac{|\Delta f_{\mathrm{true}}|}
{\sigma\max\{1,|f(x)|,|f(x^+)|\}}.
\]

只有 `SNR_step` 与算法决策一起分析，才能判断一个 block-level decrease 是否容易被噪声
淹没。

Stage 2 还必须通过源码确认：

- 每个 run 的 seed 如何生成；
- 两个 solver 是否使用相同 run seeds；
- 随机噪声由 evaluation count、evaluation point 还是二者共同决定；
- 同一 solver 重跑是否 bitwise reproducible；
- OptiProfiler 保存的 history 是 noisy values、true values，还是同时保存二者。

在这些问题确认前，不使用 `common random numbers` 这个表述。

## Stage 3: Aggregate Pairwise Experiment

运行严格 pairwise 的 profiles：

1. `ds-baseline-200n` vs `cbds-baseline-200n`, `plain`, `n_runs = 1`;
2. `ds-baseline-200n` vs `cbds-baseline-200n`, `noisy_1e-2`, `n_runs = 5`;
3. `ds-baseline-200n` vs `cbds-baseline-200n`, `noisy_1e-1`, `n_runs = 5`.

这一步为 relevant-tolerance profile analysis 和逐问题筛选提供原始结果。必须保存：

- summary and detailed profiles;
- problem names and dimensions;
- solver, feature, run index, and seed;
- evaluation histories used by OptiProfiler;
- final reported point and value;
- termination reason and function-evaluation count;
- errors, invalid evaluations, and excluded problems.

如果现有结果包含以上信息且配置完全匹配，可以复用；否则重跑。不能仅从 PDF 反推逐问题
结论。

## Stage 4: Noise-Matched Profile and Problem-Level Decomposition

只对三个 primary `(sigma, tau)` pairs 做主分解；`plain` 在 `tau=1e-1` 和 `tau=1e-2` 上作为
control。对每个 problem-run，至少计算：

- best noisy value within `200n`, if the aggregate result format stores it; otherwise record the
  data boundary explicitly and recover it during instrumented replay;
- true value at the returned point;
- best true value among all evaluated points;
- evaluations needed to reach the selected `tau`;
- `both solved / DS-only / CBDS-only / neither` status;
- DS-CBDS difference for each quantity.

每个 primary pair 首先报告 profile-level decomposition：

- profile-area score at that `tau`, but not the ten-`tau` average;
- coverage at `rho = 1` and final coverage in the performance profile;
- solved fractions over a fixed normalized-budget grid in the data profile;
- first sustained crossing in both profiles;
- the budget at which each solver is within one percentage point of its final coverage;
- the last budget at which each profile gains another solved case.

随后生成 ranked problem table：

| Field | Meaning |
| --- | --- |
| `problem`, `n` | Problem identity and dimension |
| `both / DS-only / CBDS-only / neither` | Coverage classification over five runs |
| `DS faster / CBDS faster / ties` | Time-to-target ordering among `both solved` runs |
| `median true gap` | Median difference in returned-point true values |
| `median budget gap` | Median evaluation difference at each tolerance |
| `variability` | Interquartile range and robust spread across runs |
| `coverage contribution` | Contribution to the final DS-CBDS solved-count gap |
| `rank reversal` | Whether the ordering differs from `plain` |

同时报告 win/loss/tie counts，而不是只报告均值。默认 tie threshold 应由 profile tolerance
或清楚记录的 numerical threshold 定义，不能事后为了强化结论调整。

为了判断反超来自哪里，优先按照 `DS-only minus CBDS-only` 和 five-run stability 排名。可以保留
leave-one-problem-out profile recomputation，但它是 secondary evidence，不能覆盖 solved-set
decomposition。

## Stage 5: Representative-Problem Selection

从 ranked table 中选择约 `6-9` 个问题，至少覆盖三类：

- `late DS-only`: CBDS 前期推进更快，但最终只有 DS 达到 relevant `tau`；
- `both solved, CBDS faster`: 两者都达到目标且 CBDS 明显更快，用于解释 early efficiency；
- `CBDS-only counterexample`: 最终只有 CBDS 达到目标，用于限制结论。

优先级依次为：

1. five-run ordering is stable;
2. the solved-set classification is stable at the relevant `tau`;
3. the problem materially affects the eventual-coverage gap;
4. the mathematical objective is identifiable and interpretable;
5. the case covers a structure not already represented.

不能只挑最终 noisy value 最漂亮的问题，也不能排除与初始 hypothesis 冲突的反例。

## Stage 6: Paired Replay and Instrumentation

对 shortlisted problems 单独重放。每个 problem-feature combination 建议至少 `20 runs`；若
置信区间仍然宽，再增加到 `30 runs`。所有 replay 仍使用 `200n` budget。

solver 看到的 objective 必须保持原实验不变，但同时用不反馈给 solver 的 oracle 记录
原始目标函数值。每次 evaluation 至少保存：

- evaluation index and iteration index;
- block index, direction index, and polling order;
- trial point and current base point;
- noisy trial/base values used for the decision;
- true trial/base values from the oracle;
- accepted/rejected decision;
- step sizes before and after the decision;
- expansion or contraction event;
- whether the base point changed;
- termination state.

Replay 的核心输出不是任意最终精度，而是 relevant `tau` 的 first-hitting time、是否在 `200n`
内命中、命中前后的 step-size state，以及 CBDS profile plateau 之前和之后的 decision dynamics。

Oracle evaluations 只用于诊断，不计入 solver 的 `200n` budget，也绝不能改变 solver state。
首先用一个小问题验证 instrumentation 不会改变原始 noisy history 和返回值。

## Stage 7: Mechanism Metrics

对于以 noisy comparison 接受 trial point 的决策，定义：

- **False acceptance**:
  \(\widetilde f(x^+) < \widetilde f(x)\)，但 \(f(x^+) \geq f(x)\)；
- **False rejection**:
  \(\widetilde f(x^+) \geq \widetilde f(x)\)，但 \(f(x^+) < f(x)\).

若 solver 使用 sufficient-decrease condition，则上述 noisy inequality 必须替换为源码中的
实际 acceptance test；true counterpart 使用同一 threshold。分析至少包括：

- false-acceptance and false-rejection rates;
- true objective damage caused by false acceptances;
- true improvement lost through false rejections;
- number of base-point updates per iteration;
- consecutive misleading updates within one CBDS iteration;
- expansion/contraction counts and timing;
- per-block success rates and step-size trajectories;
- distribution of `SNR_step` for accepted and rejected trials;
- fraction of budget spent after the best true point was already found;
- gap between best noisy, returned true, and best evaluated true values.

另外必须直接解释 early-efficiency/eventual-coverage trade-off：

- why CBDS reaches the relevant target much faster on `both solved` runs;
- why some CBDS runs never cross the same target despite unused or later budget;
- whether individual CBDS block steps contract or freeze while DS retains a shared coarse step;
- whether DS's late coverage comes from steady true progress or a few noise-induced lucky decisions.

主要 hypothesis 是：

> CBDS is front-loaded but may be fragile under high noise: independent
> block-level decisions and step-size updates can produce rapid early progress,
> yet may contract or freeze some coordinate steps before the relevant target is
> reached. DS pays more for a full poll and is initially slower, but its shared
> step contracts only after a complete polling failure, potentially preserving
> coarse exploration and increasing late-stage solved coverage.

这只是待检验 hypothesis。至少同时检查以下替代解释：

- DS simply samples more distinct directions or points within `200n`;
- the apparent plateau is only a performance-ratio artifact and disappears in data profiles;
- CBDS spends more evaluations revisiting locally unproductive coordinates;
- the difference comes from stopping or returned-point conventions;
- DS benefits mainly from extreme negative noise rather than better true points;
- a small number of problem families dominates the profile;
- the initial-step or direction-order defaults differ between algorithms.

## Stage 8: Objective-Function Analysis

对每个 case-study problem，必须找到 S2MPJ/CUTEst 的 authoritative definition，而不是根据
问题名称猜测结构。记录原始引用、变量维数和实际实验实例使用的参数。

每个案例使用统一模板：

1. **Objective expression**：写出目标函数，必要时写 residual form
   \(f(x)=\sum_i r_i(x)^2\)。
2. **Structural properties**：分析 separability、cross-coordinate coupling、conditioning、
   scaling、valley geometry、symmetry 和 active variable groups。
3. **Block-level signal**：估计单个 CBDS block move 产生的典型 true decrease，并与
   \(\sigma\max(1,|f|)\) 比较。
4. **Observed trajectory**：指出 DS 与 CBDS 在何处开始分化，包括 false decisions 和
   step-size changes。
5. **Mechanism link**：解释为什么该函数结构会放大或削弱算法差异。
6. **Counterfactual prediction**：根据解释预言改变噪声、分块或坐标变换后会发生什么。

每个主要 claim 都应形成以下证据链：

> Function structure -> step-level signal -> noisy decisions -> step-size/base-point dynamics -> final performance.

## Stage 9: Minimal Mechanism Tests

只有在 Stages 6-8 指向明确机制后，才运行最小干预实验。候选测试包括：

- replace noisy acceptance by oracle true acceptance for diagnosis only;
- freeze step-size adaptation while retaining the original polling sequence;
- compare one full DS poll with one complete CBDS block cycle from the same base point;
- vary `num_blocks` while keeping the direction set and budget fixed;
- replay stored trial points under many independent noise realizations;
- compare best evaluated true point with the solver's normal returned point.

每次只改变一个 mechanism。若某项干预让 DS-CBDS gap 消失或反转，它才构成较强的因果
证据；一次完整 solver redesign 不属于本调查。

## Stage 10: Rotation as External Validation

主机制明确后，再检查：

- `linearly_transformed_noisy_1e-1`;
- `linearly_transformed_noisy_1e-2`.

仍采用 `S2MPJ`, dimensions `6-50`, budget `200n`, `n_runs = 5`，并应用同一个
`tau >= sigma` rule。结果单独报告，用于判断：

- observed mechanism 是否依赖原坐标系中的 separability；
- rotation 是否改变 block-level signal distribution；
- DS 的高噪声优势是否在变量耦合增强后扩大或消失。

旋转实验是 out-of-sample mechanism check，不用于重新挑选最有利案例。

## Decision Rules for the Final Conclusion

只有满足以下条件，才能写出“DS 在 relevant practical tolerance 上具有更高 late-stage
coverage”的 strong claim：

1. eventual-coverage 优势在至少一个 primary `(sigma, tau)` pair 上由多个问题支持，而非单一
   outlier；
2. run-level uncertainty 不足以解释总体差距；
3. DS-only cases 的 true histories 确实跨过该 `tau` threshold；
4. 代表问题上存在可重复的 decision-dynamics 差异；
5. 该差异能由目标函数结构和 noise scale 联合解释；
6. 至少一个 minimal intervention 支持 proposed mechanism；
7. 反例和不支持结论的问题被明确报告。

即使满足这些条件，也要把结论限定为 trade-off，而不能写成无条件的 solver dominance：若
CBDS 在 `both solved` runs 中显著更快，就必须同时报告 `CBDS wins early efficiency`。

若 DS 只在 noisy reported values 上占优，而 true values 不占优，结论应改为：

> DS interacts with the benchmark noise realization in a way that improves the
> reported noisy profile, but the evidence does not show better underlying optimization.

若总体差距主要由少数问题贡献，则结论必须限定到相应 problem structures，不能推广为
generic noise robustness。

## Deliverables

调查最终至少产生：

- configuration and noise-seed audit;
- aggregate pairwise summary PDFs;
- noise-matched profile summary, crossing, plateau, and coverage tables;
- machine-readable per-problem/per-run table;
- ranked contribution table;
- representative-problem shortlist with selection reasons;
- instrumented replay dataset and analysis plots;
- objective-expression case studies;
- mechanism-validation experiments;
- final report separating observations, supported explanations, and unresolved questions.

所有 scripts、tables 和 figures 应放在独立的 investigation namespace 下，不覆盖现有
OptiProfiler results，也不修改 `src/bds.m`。
