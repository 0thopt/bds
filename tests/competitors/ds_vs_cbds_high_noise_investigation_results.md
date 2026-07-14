# DS vs CBDS under High Noise: Investigation Results

## Scope and Current Status

本文件记录 `ds_vs_cbds_high_noise_investigation_plan.md` 的执行结果。主范围为：

- S2MPJ unconstrained problems;
- dimensions `6-50`;
- budget `200n`;
- `ds-baseline-200n` vs `cbds-baseline-200n`;
- all acceleration switches off;
- primary noise levels `1e-1` and `1e-2`;
- `plain` as the control feature.

Aggregate experiments and the problem-level ranking are recorded below. Representative-problem
selection and mechanism case studies remain separate later stages of the investigation.

## Configuration Audit

Both solvers enter through the same function, `accelerated_bds_options.m`. Their profiler wrappers
explicitly set:

- `MaxFunctionEvaluations = 200n`;
- `StepTolerance = 1e-6`;
- `use_productive_direction_memory = false`;
- `use_sweep_pattern_direction = false`;
- `use_momentum_extrapolation = false`.

The remaining common defaults are:

| Setting | Value for both solvers |
| --- | --- |
| direction set | \(\{e_1,-e_1,\ldots,e_n,-e_n\}\) |
| initial step | `1` |
| `expand` | `2` |
| `shrink` | `0.5` |
| `forcing_function` | `@(alpha) alpha^2` |
| `reduction_factor` | `[0, eps, eps]` |
| inner polling | `opportunistic` |
| inner cycling | move the successful direction to the front (`cycling_inner = 1`) |
| optional function-value stop | off |
| optional estimated-gradient stop | off |
| output criterion | the point returned by the solver; histories retain every evaluated point |

The algorithmic difference is the grouping of the same coordinate directions and the resulting
step-size state:

| Property | DS | CBDS |
| --- | --- | --- |
| number of blocks | `1` | `n` |
| directions per block | `2n` | `2` |
| step sizes | one shared step | one step per coordinate block |
| maximum base updates per outer iteration | one | up to `n` sequential updates |
| contraction event | only after all `2n` directions fail | independently after the two directions of a block fail |

Thus, block grouping is not an uncontrolled configuration difference. It is the defining mechanism
being compared. No other solver setting differs.

One naming point matters throughout this report: `BDS` means unaccelerated `CBDS baseline`, not
accelerated BDS.

## OptiProfiler Noise and Seed Audit

For the MATLAB `noisy` feature, the defaults are `distribution = 'gaussian'`,
`noise_type = 'mixed'`, and `noise_mode = 'random'`. At the \(k\)-th evaluation of \(x\), the
solver receives

\[
\widetilde f_k(x)
= f(x)+\max\{1,|f(x)|\}\sigma\xi_k,
\qquad \xi_k\sim\mathcal N(0,1).
\]

The conditional noise standard deviation is therefore

\[
\sigma_{\mathrm{noise}}(x)=\sigma\max\{1,|f(x)|\}.
\]

At `sigma = 1e-1`, a point with \(|f(x)|>1\) is observed with a standard deviation equal to ten
percent of its objective magnitude. Consequently, an absolute decrease cannot be interpreted
without normalizing it by the local noise scale.

With the experiment-level seed fixed at zero, OptiProfiler uses

\[
\mathrm{seed}_{r}=211r
\]

for run \(r\). It constructs a fresh `FeaturedProblem` for every solver-run pair, so DS and CBDS
receive the same run seed. However, the noise generator also hashes the original function value,
the evaluation point, and the evaluation count. Since the solvers visit different points in a
different order, they do not receive pointwise common random numbers. The correct description is
`paired run seeds`, not `common random numbers`.

Repeated evaluation of the same point is not assigned a fixed noise value because the evaluation
count is part of the random-stream construction. A full rerun with the same solver, feature, and
seed is reproducible.

## What OptiProfiler Scores

`FeaturedProblem.fun` returns the noisy value to the solver but separately evaluates and stores the
original objective at every visited point. Its `fun_hist` therefore contains true objective values.
OptiProfiler's history-based profiles and default solver score are computed from these true
histories. The output-based profiles likewise evaluate the returned point with the original
objective.

This rules out the simplest alternative explanation:

> A higher DS score cannot be caused solely by reporting a more negative noise realization as the
> final objective value.

Noise can still change the search trajectory through acceptance and step-size decisions, but the
profile evaluates the quality of the points reached using the noise-free objective.

## Aggregate Pairwise Experiment

The exact Stage 3 experiment was recovered rather than rerun. It compares only
`ds-baseline-200n` and `cbds-baseline-200n` on 122 S2MPJ unconstrained problems of dimensions
`6-50`. The acceleration switches are off, the budget is `200n`, the step tolerance is `1e-6`,
and the experiment seed is zero.

OptiProfiler 默认 score 是从 `tau = 1e-1` 到 `1e-10` 的十张 history-based performance
profiles 的归一化面积平均值：

| Feature | Runs per problem | DS all-tau score | CBDS all-tau score | DS minus CBDS |
| --- | ---: | ---: | ---: | ---: |
| `plain` | 1 | 0.341577 | 1.000000 | -0.658423 |
| `noisy_1e-2` | 5 | 0.678490 | 1.000000 | -0.321510 |
| `noisy_1e-1` | 5 | 0.973611 | 1.000000 | -0.026389 |

这些分数只保留为 `all-tau diagnostic`。它们混合了低于噪声强度、并非本调查主要关心的精度，
因此不再用于回答主研究问题，也不用于挑选 case studies。

## Noise-Matched Practical Tolerances

主分析预先固定为 `tau >= sigma`：

- `noisy_1e-1`: only `tau = 1e-1`;
- `noisy_1e-2`: `tau = 1e-1` and `tau = 1e-2`.

这里的 `tau` 是 OptiProfiler relative progress tolerance，并不与 mixed-noise parameter
`sigma` 完全同量纲。因此 `tau >= sigma` 应称为 `noise-matched practical tolerance rule`，而
不是严格的 statistical noise floor。

### Primary profile decomposition

| Noise | tau | Profile score DS/CBDS | Coverage at rho=1 DS/CBDS | Final coverage DS/CBDS | Both | DS-only | CBDS-only |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `1e-1` | `1e-1` | 0.975582 / 1.000000 | 0.411475 / 0.662295 | **0.890164 / 0.719672** | 372 | 171 | 67 |
| `1e-2` | `1e-1` | 0.690725 / 1.000000 | 0.219672 / 0.839344 | **0.944262 / 0.883607** | 505 | 71 | 34 |
| `1e-2` | `1e-2` | 0.693538 / 1.000000 | 0.249180 / 0.801639 | 0.793443 / **0.824590** | 377 | 107 | 126 |

`rho = 1` 表示 solver 在该 problem-run 上与 pair 中最快达到目标的 evaluation count 相同。
`Final coverage` 表示在 `200n` 内达到该 `tau` 的 problem-run fraction。每个 noisy pair 包含
`122 x 5 = 610` 个 problem-runs；在本次数据的三个 primary pairs 中都没有
`neither solved`。

最重要的结果是 `sigma = tau = 1e-1`：

- 单图 profile-area score 仍然是 CBDS 略高 (`1.000000` vs `0.975582`)；
- CBDS 在 `rho = 1` 时已解决 `404/610` runs，而 DS 只有 `251/610`；
- 但最终 DS 解决 `543/610`，CBDS 只解决 `439/610`；
- DS 在 performance ratio `rho = 13` 后持续高于 CBDS；
- 净 coverage 优势来自 `171 DS-only - 67 CBDS-only = 104` runs。

所以单图 score 与曲线末端 ordering 并不矛盾。CBDS 的巨大左端优势提高了整条曲线的面积，
而 DS 在较大 ratio 下继续增加 solved coverage，最终曲线高出 `0.170492`。

### Early efficiency among both-solved runs

| Noise | tau | DS faster | CBDS faster | Ties | Median T_DS/T_CBDS |
| --- | ---: | ---: | ---: | ---: | ---: |
| `1e-1` | `1e-1` | 35 | 292 | 45 | 4.15969 |
| `1e-2` | `1e-1` | 27 | 442 | 36 | 8.92405 |
| `1e-2` | `1e-2` | 14 | 332 | 31 | 7.60000 |

因此当前 observation 不是无条件的 DS dominance，而是清晰的 trade-off：

> CBDS wins early efficiency on runs that both solvers solve, while DS can win
> eventual coverage at coarser noise-matched tolerances.

### Data-profile plateau

Performance profile 使用相对 fastest-solver ratio，不能单独证明 solver 在实际预算中停止推进。
Data profile 使用 normalized budget `beta = evaluations/(n+1)`，更适合量化 plateau：

| Noise | tau | beta | DS coverage | CBDS coverage |
| --- | ---: | ---: | ---: | ---: |
| `1e-1` | `1e-1` | 32 | 0.563934 | 0.716393 |
| `1e-1` | `1e-1` | 64 | **0.726230** | 0.716393 |
| `1e-1` | `1e-1` | 100 | **0.865574** | 0.718033 |
| `1e-1` | `1e-1` | 200 | **0.890164** | 0.719672 |
| `1e-2` | `1e-1` | 100 | 0.867213 | 0.880328 |
| `1e-2` | `1e-1` | 150 | **0.932787** | 0.881967 |
| `1e-2` | `1e-1` | 200 | **0.944262** | 0.883607 |
| `1e-2` | `1e-2` | 200 | 0.793443 | **0.824590** |

在 `sigma = tau = 1e-1` 下，CBDS 在 `beta = 24.27` 时已经达到最终 coverage 的一个百分点
以内，DS 要到 `beta = 128.49`。DS 在 `beta = 58.75` 后持续反超。对于
`sigma = 1e-2, tau = 1e-1`，对应的持续反超点为 `beta = 105.69`。但在更严格的
`sigma = tau = 1e-2` 上没有反超，CBDS 最终仍多解决 19 个 runs。

Plain control 也没有发生反超：在 `tau = 1e-1` 上 CBDS 最终解决 `120/122`，DS 为
`107/122`；在 `tau = 1e-2` 上分别为 `118/122` 和 `85/122`。因此 late-stage DS coverage
不是 DS 在无噪声下的一般性质，而是与 noisy trajectories 相互作用后出现的现象。

上述 profile plateau 的严格含义是“随着允许预算增加，不再出现新的 solved problem-runs”。
它尚不能推出每条 objective trajectory 都停止下降。后续 replay 必须检查 CBDS 是否发生
coordinate-wise step contraction/freezing，以及未 solved runs 是否仍有真实但不足以跨过
threshold 的进展。

机器可读的 pair summary、budget coverage、problem-run classification 和 problem-level
stability tables 位于 `analysis/noise_matched_profiles`。它们由
`analyze_ds_vs_cbds_noise_matched_profiles.m` 从 raw histories 重建。

### Data integrity audit

- All three features use the same 122 problem names and dimensions, with no missing problems.
- The stored arrays contain one run for `plain` and five runs for each noisy feature.
- All 2,684 solver-runs succeeded; there are zero abnormal terminations, output fallbacks, and
  missing evaluation counts.
- Every history is nonempty, and no solver exceeds the `200n` evaluation budget.
- The histories contain 575 nonfinite trial values, confined to `OSBORNEB`, `SCHMVETT`, and
  `YATP1LS`; all best-evaluated and returned-point true values remain finite.
- The same explicit 42-problem exclusion list is applied to every feature and is preserved in each
  `options_user.mat` and `report.txt` file.
- The manifest scores agree with scores independently recomputed from `fun_histories` to within
  `2e-10`.

The complete experiment directory is
`tests/testdata/ds_vs_cbds_high_noise_primary_20260712_165527`. It contains the raw
`data_for_loading.mat` files, options, reports, logs, individual and detailed profiles, and named
performance-profile summaries for all three features. The merged summary orders the features as
`plain`, `noisy_1e-2`, and `noisy_1e-1`.

### Stored-data boundary

OptiProfiler stores the true objective history, returned-point true value, evaluation count,
success/abnormal flags, solver names, feature, and run axis. The run seeds are reconstructible from
the audited rule `seed_r = 211r`. However, its aggregate MAT format does not store the returned
point coordinates or solver-specific exitflag text. Those quantities cannot be recovered from the
aggregate files and will instead be captured by the instrumented paired replays in Stage 6. This
format limitation does not affect the Stage 3 profile scores or the Stage 4 decomposition based on
true objective histories.

## Problem-Level Ranking

Stage 4 ranks all 122 problems separately for the three primary `(sigma, tau)` pairs. The ranking
does not use the ten-`tau` average score. At the run level it records:

- relevant-`tau` first-hitting time and `both / DS-only / CBDS-only / neither` classification;
- `DS faster / CBDS faster / tie` among `both solved` runs;
- best evaluated true value and returned-point true value for both solvers;
- evaluation gap, true-value gap, robust IQR across runs, and comparison with the plain control.

The aggregate MAT files do not store the noisy values observed by the solver, so `best observed
noisy value` cannot be reconstructed in Stage 4. This limitation is explicit rather than replacing
that quantity with the true history; noisy decision values will be captured by the instrumented
replay.

### Coverage concentration

| Noise | tau | Net DS run coverage | Problems net DS/CBDS/zero | Stable DS/CBDS candidate pools | Top-five share of positive DS coverage |
| --- | ---: | ---: | ---: | ---: | ---: |
| `1e-1` | `1e-1` | **+104** | 49/20/53 | 29/6 | 0.171 |
| `1e-2` | `1e-1` | **+37** | 18/7/97 | 14/5 | 0.385 |
| `1e-2` | `1e-2` | **-19** | 25/26/71 | 21/23 | 0.260 |

Here a stable candidate has `abs(DS-only - CBDS-only) >= 3` over five runs. At
`sigma = tau = 1e-1`, the five largest positive contributors account for only 17.1% of all positive
DS coverage contributions. The late DS advantage is therefore distributed across many problems,
not generated by one or two outliers. The same statement is weaker but still holds for
`sigma = 1e-2, tau = 1e-1`, where the top five account for 38.5%.

The provisional family accounting gives another useful boundary:

| Noise | tau | Other | Unknown/unbounded screening flag | Least-squares/residual screening flag |
| --- | ---: | ---: | ---: | ---: |
| `1e-1` | `1e-1` | +70 | +41 | -7 |
| `1e-2` | `1e-1` | +20 | +25 | -8 |
| `1e-2` | `1e-2` | +19 | +23 | **-61** |

Entries are net DS run-coverage contributions. The name-based family labels are screening aids, not
authoritative mathematical classifications. Nevertheless, they identify a concrete Stage 5/8
priority: the loss of the overall DS advantage at `sigma = tau = 1e-2` is concentrated in the
least-squares/residual candidate family and must be checked against the actual objective formulas.

### Why the reversal disappears at `sigma = tau = 1e-2`

Holding `sigma = 1e-2` fixed and tightening `tau` from `1e-1` to `1e-2` gives an exact paired
problem-run decomposition:

| Classification transition | Runs | Problems | Change in net DS coverage |
| --- | ---: | ---: | ---: |
| `both -> both` | 377 | 86 | 0 |
| `both -> CBDS-only` | **92** | 24 | **-92** |
| `both -> DS-only` | 36 | 14 | +36 |
| `CBDS-only -> CBDS-only` | 34 | 12 | 0 |
| `DS-only -> DS-only` | 71 | 19 | 0 |

Thus the net DS coverage changes by `-92 + 36 = -56`, exactly taking the gap from `+37` to `-19`.
The 71 coarse-tolerance DS-only runs do not disappear, and the 34 CBDS-only runs remain CBDS-only.
The reversal disappears because the stricter target splits the former `both solved` set
asymmetrically: substantially more runs become newly `CBDS-only` than newly `DS-only`.

This sharpens the research question. The replay must explain both why DS preserves coarse-target
coverage on its existing DS-only cases and why CBDS retains substantially more refinement capacity
inside the former both-solved set when the target is tightened.

### Ranked candidate pools

The leading stable DS late-coverage candidates include `GENHUMPS`, `EG2`, `FLETCHBV`, `INDEF`, and
several `CURLY` problems. Stable CBDS coverage counterexamples include `MSQRTALS`, `MSQRTBLS`,
`SBRYBND`, and `TOINTPSP`. Strong `both solved, CBDS faster` candidates include `ERRINROS`,
`ERRINRSM`, `COOLHANSLS`, and `VIBRBEAM`.

These are candidate pools, not the Stage 5 shortlist. Problems with uncertain boundedness or
duplicated family structure must not dominate the replay set. Stage 5 will select approximately
6-9 cases only after checking five-run stability, cross-pair usefulness, and whether the objective
definition is identifiable and structurally informative.

The complete Stage 4 report and machine-readable tables are under
`analysis/noise_matched_problem_ranking`. The central files are:

- `noise_matched_problem_ranking.md`;
- `noise_matched_ranked_problems.csv`;
- `noise_matched_problem_run_metrics.csv`;
- `noise_matched_family_coverage_summary.csv`;
- `noise_matched_classification_transitions.csv`.

## Representative-Problem Shortlist

Stage 5 fixes a nine-problem shortlist. It is intentionally not the nine largest DS contributors:
the set must jointly explain the early-efficiency/late-coverage trade-off, the disappearance of the
aggregate reversal at `sigma = tau = 1e-2`, and important counterexamples.

Status below is `both / DS-only / CBDS-only / neither` over five runs:

| Problem | n | Primary role | `sigma=.1,tau=.1` | `sigma=.01,tau=.1` | `sigma=.01,tau=.01` |
| --- | ---: | --- | ---: | ---: | ---: |
| `FMINSRF2` | 16 | late DS coverage after early CBDS progress | 1/4/0/0 | 5/0/0/0 | 0/5/0/0 |
| `FLETCHCR` | 10 | late DS coverage with one CBDS counterrun | 0/4/1/0 | 0/4/1/0 | 0/4/1/0 |
| `GENHUMPS` | 10 | early DS-only positive control | 0/5/0/0 | 0/5/0/0 | 0/5/0/0 |
| `COOLHANSLS` | 9 | stable both-solved CBDS early efficiency | 5/0/0/0 | 5/0/0/0 | 5/0/0/0 |
| `EXTROSNB` | 10 | strict-target CBDS refinement | 5/0/0/0 | 5/0/0/0 | 0/0/5/0 |
| `DIXON3DQ` | 10 | opposite strict-target DS persistence | 5/0/0/0 | 5/0/0/0 | 0/5/0/0 |
| `HILBERTB` | 10 | high-noise DS-only, lower-noise CBDS recovery | 1/4/0/0 | 5/0/0/0 | 5/0/0/0 |
| `MSQRTALS` | 25 | stable dense least-squares CBDS counterexample | 0/0/5/0 | 0/0/5/0 | 0/0/5/0 |
| `SBRYBND` | 10 | stable banded least-squares CBDS counterexample | 0/0/5/0 | 0/0/5/0 | 0/0/5/0 |

### Why this set is diagnostic

- `FMINSRF2` and `FLETCHCR` are genuine late DS cases: at high noise their median DS-only hitting
  budgets are approximately `beta = 68.2` and `67.4`, respectively. On the same true-history
  screening, CBDS is ahead at `beta = 24`, while DS continues making substantial later progress.
- `GENHUMPS` is deliberately different: it is stable DS-only but reaches the coarse target around
  `beta = 4.27`. It prevents the investigation from incorrectly treating every DS-only result as
  evidence for late-stage persistence.
- `COOLHANSLS` isolates early efficiency on a non-Rosenbrock matrix-equation problem: both solvers
  solve every run, and CBDS is faster in every run with median `T_DS/T_CBDS` between `53.9` and
  `129.2` across the primary pairs.
- `EXTROSNB` and `DIXON3DQ` form the key strict-target contrast. At
  `sigma = 1e-2, tau = 1e-1`, both are `both solved` with CBDS faster. Tightening to `tau = 1e-2`
  makes `EXTROSNB` five-run CBDS-only but `DIXON3DQ` five-run DS-only.
- `HILBERTB` checks the noise-level explanation directly: four high-noise runs are DS-only, whereas
  at lower noise all five runs are both solved and CBDS is `13.8--49.3` times faster.
- `MSQRTALS` and `SBRYBND` prevent overgeneralization. Both are CBDS-only in all 15 primary
  problem-runs, but one has dense matrix coupling and the other sparse banded residual coupling.
- `FLETCHCR` and `EXTROSNB` are both Rosenbrock-type coupled objectives but have opposite coverage
  ordering. A mechanism stated only in terms of a family name will therefore be inadequate.

The trajectory quantities used here are screening diagnostics from stored best-so-far true
histories, not mechanism proof. In particular, early normalized progress cannot establish false
rejection, coordinate freezing, or shared-step persistence; those require the Stage 6 traces.

### Source verification and exclusions

All nine selected problems were loaded through the local OptiProfiler `s2mpj_load` implementation.
Their actual dimensions, unconstrained status, S2MPJ classifications, finite initial objective
values, and both MATLAB and Python source files were verified. Full objective-expression analysis
remains Stage 8.

`INDEF`, `INDEFM`, `CURLY*`, `SCURLY*`, and `FLETCHBV` are not used as primary replay cases even
though some rank highly: their boundedness/solution interpretation or family duplication would
complicate the main mechanism test. `MSQRTBLS` duplicates `MSQRTALS` closely, and only one is kept.
`ERRINROS/ERRINRSM` are strong early-efficiency candidates, but `COOLHANSLS` adds a more distinct
matrix-equation structure while `EXTROSNB` already supplies a CBDS-positive Rosenbrock-type case.

### Stage 6 handoff

The targeted replay matrix contains both noise levels for all nine problems, for 18
problem-feature combinations. Thirteen form Tier 1. Each combination starts with 20 paired runs and
increases to 30 only if classification or mechanism uncertainty remains large. The solver trajectory
is run once per `(problem, sigma, run)`; relevant `tau` values are applied afterward to the same
true history.

Stage 6 uses the normal noisy acceptance decisions and first proves exact trace equivalence with the
formal solver. Oracle true-acceptance is a causal intervention and remains deferred to Stage 9.

The Stage 5 report and machine-readable handoff are under
`analysis/noise_matched_problem_ranking/stage5_case_selection`:

- `stage5_representative_problem_shortlist.md`;
- `stage5_representative_problem_shortlist.csv`;
- `stage5_case_evidence_matrix.csv`;
- `stage6_targeted_replay_matrix.csv`.

## Instrumentation Validation

`trace_ds_cbds_baseline.m` reproduces only the baseline DS/CBDS path used in this investigation and
records noisy and true values for every decision. Before using it for mechanism analysis, its
normal noisy-decision mode is compared with the formal solver using identical `FeaturedProblem`
objects.

The validation checks exact equality of:

- every evaluated point (`xhist`);
- every noisy value seen by the solver;
- every true value stored by OptiProfiler;
- block and direction order;
- step-size history;
- returned point and returned noisy value.

The initial cross-structure checks passed exactly, including `ARWHEAD` and `EXTROSNB` at high noise
for both DS and CBDS. Mechanism statistics are accepted only for cases that pass this strict replay
check.
