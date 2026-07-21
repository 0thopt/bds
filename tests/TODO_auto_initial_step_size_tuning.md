# BDS 的 automatic initial step size 调参

本文件是为 automatic initial step size rule 选择 coefficient 的执行 checklist。
相关工作属于 `bds` software repository。无论本文件目前存放在哪里，下文所有
code path 和 command 均应相对于该 repository 的根目录来理解。

## 状态

使用以下 status label。

- `[todo]`：尚未开始。
- `[progress]`：implementation 或实验正在进行。
- `[blocked]`：在指定 dependency 得到解决之前无法继续。
- `[done]`：已完成、已检查，并已链接到对应 output。

实验方案设计状态：`[done]`。

实验执行状态：`[todo]`。

尚未选定任何 coefficient pair。在本文件中的实验与检查完成之前，不得修改
released default 或 manuscript formula。

## 目标

为 cyclic BDS solver 的 `alpha_init = "auto"` rule 选择一个 coefficient pair。
在本研究期间，省略 `alpha_init` 仍然选择 unit initial steps。是否将完成后的
automatic rule 提升为 released default，是后续的 integration decision；只有在
coefficient study 和 combined solver checks 均通过后才能作出。所选 coefficient
pair 必须适用于 released software，而不能只是在某一张 performance profile 中
表现有利。

本研究必须回答以下问题。

1. BDS 应当使用 initial point 所指示 scale 的多大比例？
2. 基于 scale 的 initial step 应当设为 step tolerance 的多少倍？
3. 同一组 coefficient pair 在 `200*N` 和 `500*N` 两种 function evaluation
   budget 下是否都保持可靠？
4. 所选 rule 能否在不相对于当前 automatic rule 引入实质性 regression 的前提下，
   改进 unit initial steps？
5. 同一个 rule 能否用于 plain solver，以及结合 acceleration 和 termination 的
   final solver？

最终结果必须是一条有文档记录的 automatic rule 和一个 coefficient pair。不得为
`200*N` 和 `500*N` 采用不同的 coefficient，也不得引入任何依赖于 benchmark 的
runtime selection rule。

## 范围

主要研究对象是 cyclic BDS 的 default coordinate version。

- direction pair 为 `{e_i, -e_i}`，其中 `i = 1, ..., N`。
- 每个 coordinate pair 构成一个 block。
- 每个 block 都有自己的 initial step size。
- 数学上的 dimension 记为 `N`。MATLAB code 中可继续使用 `n` 表示 dimension。

coefficient study 首先针对 plain BDS。在 coefficient selection 期间禁用
acceleration 和 optional stopping tests。只有完成 plain study 后，才使用最终的
combined solver 检查所选 candidate。

以下任务不属于本研究的范围。

- 调整 acceleration 的 parameters。
- 调整 termination 的 parameters。
- 解释 large noise DS comparison。
- 选择 main paper budget。
- 完成与 external solvers 的比较。
- 为任意 noncoordinate directions 设计 automatic scale rule。

## Candidate rule（候选规则）

令 `epsilon_i` 表示 coordinate block `i` 的 step tolerance。对 positive
coefficients `c_x` 和 `c_tau`，定义

\[
  b_i(c_x)=
  \begin{cases}
    1, & x_i^0=0,\\
    c_x|x_i^0|, & x_i^0\ne0,
  \end{cases}
\]

以及

\[
  \alpha_0^i(c_x,c_\tau)
  =\max\{b_i(c_x),c_\tau\epsilon_i\}.
\]

因此，除非 `c_tau*epsilon_i > 1`，exact zero coordinates 采用 neutral unit
scale。nonzero coordinates 使用 initial point 中对应 entry magnitude 的一部分，
同时受与 step tolerance 关联的 lower bound 约束。

对 exact zero 作此区分是有意的。exact zero entry 被视为不提供可用的 positive
coordinate scale，因此该 rule 回退到 neutral unit step。每个 nonzero entry 都被
视为通过 initial point 有意提供的 scale signal，即使其 magnitude 很小也是如此。
因此，当 nonzero entry 趋近于零时，automatic rule 的 continuity 并非 design
requirement。tests 应记录并保留这一 semantic convention，而不应将该
discontinuity 视为 coefficient tuning 问题。

对于未来将多个 coordinate pairs 合并到同一 block `j` 中的 implementation，
自然的 extension 是

\[
  \alpha_0^j=\max_{i\in I_j}\alpha_0^i,
\]

其中，`I_j` 是 block `j` 中 coordinate pairs 的集合。该 extension 不属于
coefficient selection experiment。除非已知 direction set 由有序的 coordinate
pairs 构成，否则不得从任意 direction indices 推断 coordinate indices。

### `c_x` 的含义

- `c_x = 1` 是当前用于 nonzero coordinates 的 simple scale rule，也是本研究中
  可靠的 incumbent。
- 小于一的取值会使 first trial 相对于 `x0` 更加 local，它们是 incumbent 的
  challengers。
- 导师建议考察 `0.1` 至 `0.5` 附近的取值。
- 本研究保留 `1`，以确保当前 rule 始终作为 baseline 纳入比较。

### `c_tau` 的含义

coefficient `c_tau` 控制 lower bound 附近的 initial step 在降至
`StepTolerance` 以下之前还会经历多少次 unsuccessful contractions。若
contraction factor 为 `theta = 0.5`，且 initial step 等于
`c_tau*epsilon_i`，则使该 step 严格小于 `epsilon_i` 所需的最少 consecutive
contractions 次数，是满足下式的最小整数 `m`：

\[
  0.5^m c_\tau < 1.
\]

在整数 domain `1, ..., 10` 上，contraction-depth groups 为

- `{1}`：一次 contraction；
- `{2, 3}`：两次 contractions；
- `{4, 5, 6, 7}`：三次 contractions；
- `{8, 9, 10}`：四次 contractions。

取值 `{1, 2, 5, 10}` 是为 general benchmark 预先选定的四个 groups 各自的
representative。选定最终取值时，必须记录这一解释以及使用这些 representatives
的理由。将 `c_tau = 1` 视为 incumbent；取值 `{2, 5, 10}` 是 challengers，
而不是具有同等优先级的备选值。

## Candidate values（候选取值）

预先声明的 coefficient values 为

\[
  c_x\in\{0.1,0.2,0.5,1.0\}
\]

以及

\[
  c_\tau\in\{1,2,3,4,5,6,7,8,9,10\}.
\]

这些 `c_x` values 用于一轮预先设定的 coarse sensitivity screen：`0.1` 和
`0.5` 覆盖导师建议 range 的两端，`0.2` 表示该 range 内的一个 local scale，
`1` 则是当前 automatic rule。不得仅仅为了找出视觉上最好的 curve 而运行 dense
`c_x` grid。

将 `c_x = 1` 视为 incumbent。`{0.1, 0.2, 0.5}` 中的某个取值，只有在
`200*N` 和 `500*N` 两个 checkpoint 上分别相对于 incumbent 显示出明确、稳定且
实质性的优势时，才能晋级。在每个 checkpoint 内，改进方向必须在主要 accuracy
levels 和 problem-level paired comparisons 上大体一致，solved fraction 不得出现
实质性下降，并且改进不能仅由少数 problems 驱动，也不能伴随集中出现的严重
regression。只在一个 checkpoint 获胜、在任一 checkpoint 打平，或仅显示视觉上的
优势，都不足以作为替换 incumbent 的证据。

如果没有 challenger 达到 threshold，则在后续研究中设定 `c_x = 1`。如果恰有一个
challenger 达到 threshold，则在 `c_tau` cross 中同时保留该 challenger 和
`c_x = 1`。如果多个 challengers 满足全部 advancement criterion，则将它们全部
记录为 finalists，并推迟 tie-breaking decision，直至审查其实际 evidence。不得
预先强加 ranking formula、扩展 parameter grid，也不得根据单张有利的 profile
选择其中一个。

只有当一个具有预先声明的 neighborhood 的 interior challenger 晋级时，才进行至多
一轮 local confirmation，且新增取值不得超过两个。使用以下 neighborhoods：

- 在 `0.2` 附近测试 `0.15` 和 `0.3`；
- 在 `0.5` 附近测试 `0.3` 和 `0.7`；
- 当任一 endpoint 在 screen 中领先时，不得扩展至 `0.1` 以下或 `1` 以上。

local round 用于检查单个晋级 challenger 的优势在较宽 neighborhood 内是否稳定；
它不是寻找 numerical optimum 的 recursive search。附近取值只有在相同 advancement
rule 下也于两个 budget checkpoint 明确击败 incumbent 时，才能晋级。如果多个
coarse 或 local values 满足所有 criterion，则将它们记录为 finalists 并推迟比较，
而不是强行选出唯一 winner。若没有 coarse value 击败 incumbent，则不得运行 local
round；在该 confirmation round 之后，也不得再次细化 grid。

全部十个整数 `c_tau` values 都进入低成本 activation audit 和 deterministic
controlled tests，而只有预先选定的 representatives `{1, 2, 5, 10}` 进入 general
benchmark。该 representative set 在本研究中固定；查看结果后，不得将其扩展为更密的
benchmark grid。任何尚未解释的 effect 都应使用 controlled tests 进行记录和解释，
而不是通过额外的 benchmark tuning 继续追查。

对于每个保留的 `c_x`，在相同 `c_x` 下将每个 `c_tau` challenger 与
`c_tau = 1` 直接比较。challenger 只有在 `200*N` 和 `500*N` 两个 checkpoint
上分别表现出明确、稳定且实质性的优势，并满足与 `c_x` 相同的 accuracy-level
consistency、problem-level evidence 和 material regression requirements 时，才能
替换 `1`。只在一个 checkpoint
获胜、在任一 checkpoint 打平或产生 mixed evidence 时，都保留 `c_tau = 1`。如果
tolerance lower bound 在 general benchmark 上实际上没有激活，则保留
`c_tau = 1`，而不是从 numerical noise 中推断 winner。

如果同一 `c_x` 下有多个 `c_tau` challengers 满足全部 advancement criterion，
则将它们全部记录为 finalists，并推迟 tie-breaking，直至审查实际 evidence。不得
添加 a priori ranking rule，也不得仅仅为了强行得到唯一取值而扩展 benchmark grid。

controlled tests 用于确认 correctness、揭示 premature termination 或 wasted
contractions，并解释 benchmark result。它们可以淘汰不安全的 challenger，但在缺少
所要求的 two-checkpoint benchmark advantage 时，不能仅凭 controlled tests 选择
大于 `c_tau = 1` 的取值。

coefficient pair `(c_x, c_tau) = (1, 1)` 是当前 simple rule，必须出现在每一项用于
decision 的 comparison 中。

## 当前 implementation 的差异

必须明确解决这些差异。不得假定现有对 `alpha_init = "auto"` 的所有用法都采用
相同 rule。

### Released BDS

`src/private/set_options.m` 当前通过 `get_auto_alpha_init` helper 计算 coordinate
scales。其 effective rule 为

\[
  \alpha_0^i=
  \begin{cases}
    \max\{1,\epsilon_i\}, & x_i^0=0,\\
    \max\{|x_i^0|,\epsilon_i\}, & x_i^0\ne0.
  \end{cases}
\]

该 implementation 通过重复 assignment 和 `max` operations 表达这一 rule。最终的
production implementation 应直接表述其 mathematical intent。

### Accelerated experimental solver 中的差异

`tests/competitors/private/set_accelerated_bds_options.m` 当前使用另一条 rule。
它计算 `x0` 中 nonzero entries 的 ratio，保留 magnitude 较大且彼此 comparable
的 scales；当该
ratio 超过 threshold 时，对较大 entries 应用 `1 + log(abs(x0_i))`。这不是此处
正在调参的 rule。

### Manuscript 中的描述

当前 manuscript 描述的是 accelerated experimental solver 使用的
ratio-and-logarithm rule，因此与 `src/private/set_options.m` 中的 simple rule
不一致。

### 现有 profile wrappers

`tests/profile_optiprofiler.m` 包含 `bds_scaled` 等 wrappers，它们设置
`expand = 2` 和 `shrink = 0.5`。`src/private/get_default_constant.m` 中的 released
default 当前在 noiseless problems 上使用 `expand = 1.8`。在没有明确设置全部 base
options 的情况下，不得复用现有 wrapper。

## 实验原则

### 调参期间不要更改 released default

首先在 test code 中实现 candidate formula。对于每个 problem，在 test wrapper 中
计算 numeric vector `alpha_init`，并将该 vector 传给 `bds`。这样在比较 candidates
期间，
`src/private/set_options.m` 保持不变。

只有选定一个 coefficient pair 后，才能修改 production helper 和公开文档。在此之前，省略
`alpha_init` 时的 released behavior 仍为 unit initial steps；
`alpha_init = "auto"` 是显式 opt-in behavior。完成本研究本身并不构成更改
default 的授权。

### 仅更改 initial step size

参与同一 comparison 的每个 candidate，除 `alpha_init` 外的所有 option 都必须使用相同的
显式值。至少应记录并固定以下 option：

- `Algorithm`,
- `MaxFunctionEvaluations`,
- `StepTolerance`,
- `direction_set`,
- `num_blocks`,
- `batch_size`,
- `block_visiting_pattern`,
- `expand`,
- `shrink`,
- `forcing_function`,
- `reduction_factor`,
- `polling_inner`,
- `cycling_inner`,
- `seed`,
- `use_function_value_stop`，以及
- `use_estimated_gradient_stop`.

将 plain、noiseless 调参配置冻结为当前 released BDS behavior；在预先规定的
analysis 和 candidates 之间，只有 budget 和 numeric `alpha_init` vector 可以变化：

- `Algorithm = "cbds"`，其 effective configuration 为 `direction_set =
  eye(N)`、`num_blocks = N`、`batch_size = N` 和
  `block_visiting_pattern = "sorted"`；
- `StepTolerance = 1e-6`、`expand = 1.8` 和 `shrink = 0.5`；
- `is_noisy = false`、`forcing_function = @(alpha) alpha^2`、
  `reduction_factor = [0, eps, eps]`、`polling_inner = "opportunistic"` 和
  `cycling_inner = 1`；
- `ftarget = -Inf`、`use_function_value_stop = false` 和
  `use_estimated_gradient_stop = false`；以及
- BDS `seed = 0`，由本实验固定以确保可复现性。released seed default 是
  `"shuffle"`；不得把实验使用的 seed 描述为 released default。

传入 `Algorithm = "cbds"`，不要同时传入由它派生的 block fields，但应在
manifest 中记录所有 effective values。不要从旧的 profile wrapper 继承
`expand = 2`。

### 统一 problem、target 与 randomness

- 所有 candidates 使用完全相同且顺序一致的 problem list。
- 使用每个 problem 所提供的同一个 initial point。
- 所有 candidates 使用相同的 transformation 和 random seed。
- 绘制 profile 图之前，先保存 raw history。
- 每个 target value 都必须由同一 stage、同一 analysis budget 下所有 candidates 和
  baseline 组成的同一个 common pool 计算得到。
- 对于 `200*N` 分析，将每条已保存的 history 截断至 `200*N` 次 evaluation，
  并由这些截断后的 history 计算 common target。对于 `500*N` 分析，则由完整
  history 单独计算另一组 common target。由 `500*N` history 计算出的 target
  不得复用于 `200*N` 分析。
- 如果 candidates 分不同 batch 运行，应合并 raw result，并使用 common target
  重新计算 profile。不得通过比较 target value 各自独立计算的 PDF 来排序 candidates。

### 可复现性 manifest

每次完整运行都必须保存一个 manifest，其中包括：

- BDS git commit，
- profile tool 的 commit 或 version，
- MATLAB version，
- operating system，
- 日期和时间，
- 完整的 problem list，
- dimension limits，
- feature 和 transformation identifiers，
- budget，
- 所有 BDS option，
- coefficient pairs，
- solver label，
- 所有 random seed，以及
- 启动本次运行所使用的 command。

使用 `.mat` 或 JSON 等 machine-readable format，并附上一份简短的
human-readable text summary。仅有 PDF 不能作为可接受的实验记录。

## Baseline 设置

每当比较 shortlist 时，都应包含以下 baseline：

1. `unit`：`alpha_init = ones(N, 1)`。
2. `simple-current`：candidate pair `(1, 1)`。
3. `ctau-incumbent`：对于 `c_tau` 比较中使用的每个保留的 `c_x`，采用
   `(c_x, 1)`。
4. `simple-candidate`：shortlist 中的每个 coefficient pair。

选定 shortlist 后，加入当前的 ratio-and-logarithm rule，并将其作为名为
`historical-log-rule` 的 diagnostic baseline。在替换 accelerated solver 中的
automatic rule 之前，需要进行这一 diagnostic comparison，但不得将其混入
initial coefficient screen。

label 必须无歧义地编码 coefficients。例如：

```text
auto-cx-0p3-ctau-5
```

在记录正式决策之前，不得使用 `new`、`best` 或 `final` 之类的 label。

## Test set 与 budget

### 主要 benchmark

将 primary benchmark 冻结为现有已审计的 snapshot：122 个 dimension 介于 `6`
和 `50` 之间的 unconstrained S2MPJ problems，以及现有的 42-problem exclusion
list。
problem names 的顺序及其 dimension 应在首次运行时冻结为 snapshot，并将这一顺序完全一致的
snapshot 复制到每次运行的 manifest 中，而不是动态接受后续 library version 中发生变化的
problem set。primary coefficient screen 为
noiseless，每个 problem 只运行一次。

### Transformation 检查

在相同 problems 的 linearly transformed version 上检查 shortlist 中的 candidates。
使用 OptiProfiler 的 `linearly_transformed` feature，并设置 profile
`seed = 0`、`n_runs = 5`、`rotated = true` 和 `condition_factor = 0`。因此，
该 stage 使用五个固定的 pure orthogonal rotations，不附加 axis scaling。所有
candidates 都使用相同的五个 transformed instances。其目的在于 validation，而不是
进行第二轮独立 tuning pass。

### Evaluation budget

每个 solver/problem/configuration combination 只运行一次，function evaluation
上限为 `500*N`，并保存完整 raw history。随后在两个 budget checkpoint 上分析
该次运行：

- `200*N`：每条 history 仅使用前 `200*N` 次 evaluation；以及
- `500*N`：使用完整 history。

每个 checkpoint 都有自己的一组 common targets，这些 targets 由截至该 checkpoint
时可用的 candidates 和 baseline histories 计算得到。因此，`200*N` 结果是由保存的
history prefix 重建出的真正 `200*N` benchmark，而不是读取一个由 `500*N` 数据
计算 target 的 profile 在 `200*N` 处的值。该重建仅改变 postprocessing，不会
重新运行 solver。使用两个 checkpoints 共同选出一个 coefficient pair。

### Accuracy level

至少检查：

\[
  \tau\in\{10^{-1},10^{-2},10^{-3},10^{-4}\}.
\]

不得根据单一 accuracy level 选择 coefficient。在 raw analysis 中保留更细的 standard
accuracy grid，以便暴露出乎预期的较差 high-accuracy behavior。

## Profile 类型与辅助 metric

### History-based profile 分析

在 plain BDS tuning 中，history-based profile 是主要 evidence。它衡量每个 candidate
首次生成达到 common target accuracy 的点有多快。

### Output-based profile 分析

同时检查 `500*N` 实际运行结束时的 returned point。由于 additional stopping tests
处于关闭状态，大多数运行会耗尽全部 budget，因此 output-based profile 主要揭示
最终 solved fraction，而不是有意义的 timing difference。一次 `500*N` 运行无法
提供 solver 若在 `200*N` 时终止所得到的 returned point 或 termination status；对于
`200*N` checkpoint，应使用截断后的 history，而不是 output-based profile。不要将
相同的 output cost 解读为 early efficiency 相同的证据。

将 selected rule 插入 combined solver 后，按照 full solver study 的要求，重新生成两个
checkpoint 上的 history-based profile，以及 `500*N` 实际运行结束时的
output-based profile。

### Problem-level data 记录

对每个 candidate，应保留足够的 data，以计算：

- 每个 accuracy 下 solved problem 的数量与 solved fraction，
- 首次到达 target point 所需的 evaluation 次数，
- jointly solved problem 上的 paired evaluation ratio，
- 最终 true objective value，
- returned point status，
- initial step vector，
- tolerance lower bound 生效的 coordinate 数量，以及
- termination reason。

Profile 图只是 summary。应同时依据 profile 和 paired problem-level data 作出决策。

## 必做的 activation audit

在进行昂贵的运行之前，先确定在默认 `StepTolerance` 下，`c_tau` 是否会影响
primary benchmark。

此 audit 仅用于描述，不是 runtime rule 的一部分。其目的是说明 benchmark
是否包含足够多的 active cases，从而能够解释固定 coefficient pairs 之间观察到的
差异。不得根据 problem、benchmark、budget 或 activation rate 动态选择
coefficients。最终发布的结果仍然是一个固定 pair。

对于每个 problem 和每个 `c_x`，记录

- `x0` 中 exact zero entries 的数量；
- 满足 `c_x*abs(x0_i) < c_tau*epsilon_i` 的 nonzero entries 数量；以及
- tolerance lower bound 改变 initial step 的 coordinate blocks 比例。

当 `StepTolerance = 1e-6` 且 `c_tau <= 10` 时，zero coordinate 的 step 为
1，因此 `c_tau` 不影响该 coordinate。如果几乎没有 nonzero coordinate
激活 tolerance lower bound，S2MPJ profiles 就无法识别 `c_tau`。在这种情况下，
任何 challenger 都无法建立所要求的 general benchmark 优势，因此保留
`c_tau = 1`。下面的 controlled tests 仅用于验证 correctness 并解释为何缺乏
sensitivity。不要声称一个 generic profile 选出了一个在几乎所有 problem 上都未
激活的 coefficient。

## Controlled tests 的设计

在运行 profiles 之前，创建能够隔离预期行为的 deterministic tests。任何
correctness failure 都会使 candidate 失去资格。这些 constructed cases 上的
performance 不能使 `c_tau > 1` 晋级；选择更大的 tolerance coefficient，仍要求
它在相同 `c_x` 下，相比 `c_tau = 1` 在两个 checkpoint 的 general benchmark
中具有优势。

### Formula tests 项目

- `[todo]` 验证对于普通 finite inputs，`(1, 1)` 能复现当前的 simple rule。
- `[todo]` 验证 sign invariance。将 `x0` 替换为 `-x0` 不得改变 initial steps。
- `[todo]` 验证 exact zero coordinates 得到
  `max(1, c_tau*StepTolerance)`。
- `[todo]` 直接验证有意采用的 zero convention：将 exact zero 替换为足够小的
  nonzero value，可能使 initial step 从 neutral unit scale 变为 tolerance lower
  bound。
- `[todo]` 验证在 tolerance lower bound 激活时，small nonzero coordinates
  得到该 lower bound。
- `[todo]` 验证在 lower bound 未激活时，large coordinates 得到
  `c_x*abs(x0_i)`。
- `[todo]` 验证 scalar 和 coordinate-sized `StepTolerance` inputs 得到预期结果。
- `[todo]` 验证对于所有支持的 finite inputs，返回的所有 initial steps 都是
  finite positive values。
- `[todo]` 验证 test wrapper 传入的 numeric `alpha_init` vector 不会被 option
  processing 改变。

一个明确的 test case 应包括

```text
x0 = [0; 2; -3; 1e-8]
StepTolerance = 1e-6
c_x = 0.5
c_tau = 5
expected alpha_init = [1; 1; 1.5; 5e-6]
```

### 对 StepTolerance 敏感的问题

构造一个小型 deterministic suite，其中 initial points 包含

- exact zeros；
- 小于 `StepTolerance` 的 nonzero entries；
- 位于 `StepTolerance` 与 `10*StepTolerance` 之间的 nonzero entries；
- 接近 1 的 entries；
- 数值较大且彼此相近的 entries；以及
- 相差多个 orders of magnitude 的 entries。

使用 minimizers 已知的 simple objectives，并记录完整 step history。这些 tests
应说明：在 step tolerance 终止某个 coordinate search 之前，`c_tau` 如何改变
contractions 的次数。

### Floating-point scale 问题

保留这样的 controlled examples：unit displacement 与 large coordinate 相加时会
丢失。验证每个待考察 candidate 都能在预期 coordinate 上生成 distinct trial
point，并验证减小 `c_x` 不会重新引入这种 lost movement。

## 分阶段实验方案

### T0：冻结 base configuration

- `[todo]` 在 manifest 中记录上文规定的固定 plain、noiseless、released BDS
  options。
- `[todo]` 记录：当前省略 `alpha_init` 表示 unit steps；本研究中的每个
  candidate 都是显式的 `alpha_init = "auto"` candidate，并通过 test code 中的
  numeric vector 实现。
- `[todo]` 验证 effective options 包括 `expand = 1.8`、`shrink = 0.5`、
  `StepTolerance = 1e-6`，且两个 optional stopping tests 均被禁用。
- `[todo]` 加载严格保持既定顺序的 122-problem S2MPJ snapshot，并在运行前验证
  其 names 和 dimensions。
- `[todo]` 记录 BDS seed `0` 和 transformed-feature protocol
  (`seed = 0`, `n_runs = 5`, `rotated = true`, `condition_factor = 0`)。
- `[todo]` 在运行任何 benchmark 前记录 commits。

输出：run manifest 中的 `base_configuration`，以及 result summary 中一份
human-readable copy。

### T1：实现仅供测试的 candidate helper

- `[todo]` 在一个 test helper 中实现该 formula。
- `[todo]` 保持该 helper 独立于 production private helper。
- `[todo]` 添加一个 wrapper，将 numeric `alpha_init` vector 传给 `bds`。
- `[todo]` 将 budget 和所有 base options 作为显式 arguments 或 manifest fields。
- `[todo]` 添加由 `c_x` 和 `c_tau` 派生、无歧义的 solver labels。
- `[todo]` 如果 parameterized runner 可以避免，就不要在
  `tests/profile_optiprofiler.m` 中为每个 coefficient pair 添加一个 switch case。

建议的 artifact names：

```text
tests/private/auto_alpha_init_candidate.m
tests/run_auto_alpha_init_tuning.m
tests/analyze_auto_alpha_init_tuning.m
```

这些 names 是建议，而非要求。如果使用不同 names，请在本文件中记录。

### T2：运行 unit tests 和 smoke tests

- `[todo]` 完成上面的每个 formula test。
- `[todo]` 对 `c_tau` 的所有取值运行 controlled tolerance suite。
- `[todo]` 对四个粗粒度 `c_x` 值运行一小组 S2MPJ problems。
- `[todo]` 验证改变 coefficients 只会改变 `alpha_init`。
- `[todo]` 验证 deterministic reruns 产生完全相同的 raw histories。
- `[todo]` 检查 result directories 和 manifests 是否完整。

T2 通过前，不得开始完整 screening。

### T3：执行 parameter activation audit

- `[todo]` 在完整 primary problem list 上运行必做的 activation audit。
- `[todo]` 按 problem、dimension 和 coefficient 汇总 activation。
- `[todo]` 判断 generic profiles 是否包含足够多的 active cases，以支持
  `c_tau` comparison。如果不够，则记录保留 incumbent `c_tau = 1`；controlled
  tests 仅用于解释为何缺乏 sensitivity。

输出：一张 activation counts table 和一个简短 conclusion。

### T4：粗筛 `c_x`

固定 `c_tau = 1`，在 plain S2MPJ problems 上比较四个粗粒度取值
`c_x \in \{0.1, 0.2, 0.5, 1\}`。每个 candidate 只运行一次到 `500*N`，并同时使用
其 `200*N` history prefix 和完整 `500*N` history 进行 screening。

- `[todo]` 为所有 candidates 和 unit baseline 生成 raw histories。
- `[todo]` 分别根据完整 candidate pool 的 `200*N` prefixes 和完整 `500*N`
  histories 计算各自的 common targets。
- `[todo]` 在两个 checkpoints 和所要求的 accuracies 下生成 history-based
  profiles。
- `[todo]` 生成 paired evaluation counts 的 problem-level table。
- `[todo]` 将每个 challenger 与 `c_x = 1` incumbent 直接比较。
- `[todo]` 淘汰以下任一 challenger：未能在两个 checkpoints 都明确击败
  incumbent；在任一 checkpoint 的 solved fraction 出现实质下降；或在一个可识别的
  problem class 中出现集中且严重的 regression。
- `[todo]` 找出所有在两个 checkpoints 分别都相对 incumbent 具有清晰、稳定且
  实质优势的粗粒度值；其 accuracy-level 和 problem-level evidence 应在总体上保持
  一致。
- `[todo]` 如果恰有一个粗粒度 challenger 晋级，则运行一次预先声明的 local
  confirmation round，最多加入两个额外值；对这些值也先执行相同 formula checks
  和 smoke checks。
- `[todo]` 如果多个 candidates 满足所有晋级标准，则将它们记录为 finalists，并在
  审阅实际 evidence 后再决定 tie-breaking；不要扩展 grid，也不要根据一个 profile
  强行排名。
- `[todo]` local confirmation 后，不得递归细化 `c_x` grid。

如果没有 challenger 明确击败 incumbent，则只保留 `c_x = 1`。如果有一个
challenger 晋级，供后续与 `c_tau` 交叉比较的 `c_x` shortlist 包含该 challenger
和 `c_x = 1`。多个合格 candidates 继续作为 finalists，等待基于 evidence 的讨论；
它们的存在并不授权扩大 search。

### T5：粗筛 `c_tau`

对 `c_tau` 的全部十个取值使用 activation audit 和 controlled tolerance suite。
在 general benchmark 中，只比较预选的 representatives `{1, 2, 5, 10}` 与已保留的
`c_x` values。activation audit 决定如何解释这些 benchmark results；它不决定是否
运行这四个预选 representatives。

- `[todo]` 对每个保留的 `c_x`，将 `{2, 5, 10}` 与相同 `c_x` 下的
  `c_tau = 1` incumbent 直接比较。
- `[todo]` 要求 challenger 在 `200*N` 和 `500*N` 两个 checkpoints 上分别都
  相对 `c_tau = 1` 展现清晰、稳定且实质的优势。
- `[todo]` 当 evidence 无法区分二者、在两个 budgets 间表现混合，或 tolerance lower
  bound 实际上未激活时，保留 `c_tau = 1`。
- `[todo]` 如果多个 `c_tau` challengers 满足所有标准，则将它们记录为
  finalists，并在审阅实际 evidence 后再决定 tie-breaking；不要扩展 grid，也不要
  强加 a priori ranking。
- `[todo]` 记录在 tolerance 附近观察到的 contractions 次数。
- `[todo]` 检查是否发生 premature step tolerance termination。
- `[todo]` 检查较大的值是否会在 optimization progress 已停滞后浪费 evaluations。
- `[todo]` 在 general benchmark 中，用 `{1, 2, 5, 10}` 代表四个
  contraction-depth groups。

controlled tests 可以淘汰不安全的 challenger，并解释观察到的差异，但不能独立
选出大于 `c_tau = 1` 的值。不要从 numerical noise 中得出 tuning conclusion，
不要扩展到四个固定 representatives 之外，也不要仅为寻找视觉上最好的 curve 而运行
完整 integer grid。

### T6：在两个 budgets 下比较 shortlist

对保留的 `c_x` 和 `c_tau` values 做交叉组合。对于尚无结果的每个 configuration，
将 primary benchmark 运行一次到 `500*N`。在 `200*N` 和 `500*N` 两个
checkpoints 上分析已保存的 histories。

- `[todo]` 分别根据 `200*N` history prefixes 和完整 `500*N` histories 重新计算
  各自的 common targets。
- `[todo]` 检查 history-based profiles。
- `[todo]` 检查 `500*N` 时的 returned point 和 final solved fraction。
- `[todo]` 比较 problem-level paired costs。
- `[todo]` 找出 ranking 在两个 budgets 间发生实质反转的 candidates。
- `[todo]` 拒绝 budget-specific defaults。

如果结果揭示了分阶段设计无法解决的 material interaction，则记录一个具体的
follow-up hypothesis。不要恢复 T4 中已淘汰的 `c_x` challenger，也不要退回 dense
two-parameter grid。如果仍有多个 candidates 合格，则保留它们作为 finalists，直到
讨论其实际 evidence。

### T7：在 transformed problems 上验证

- `[todo]` 在 linearly transformed problems 上将 shortlist 运行一次到 `500*N`，
  并在两个 checkpoints 上分析已保存的 histories。
- `[todo]` 分别根据 `200*N` prefixes 和完整 `500*N` histories 计算各自的
  common targets。
- `[todo]` 使用固定且已记录的 transformation seeds。
- `[todo]` 检查在 plain problems 上选出的 coefficient 是否在 transformation 后
  造成 material loss。
- `[todo]` 将此阶段视为 validation。不要仅针对 transformed problems 重新 tuning。

### T8：选择 provisional pair

使用下文 decision rules，并记录

- selected pair；
- rejected finalists；
- main evidence；
- 出现 regressions 的所有 problem classes；
- 对 budget 的 sensitivity；
- 对 transformations 的 sensitivity；以及
- tolerance coefficient 是否有实质性 activation。

activation result 是解释 comparison 的 evidence，而不是针对不同 problems 或
budgets 定义不同 coefficient pairs 的理由。

在 combined solver check 通过之前，将该 pair 标记为 provisional。

### T9：检查 combined solver

在 acceleration 和 termination mechanisms 冻结后，比较

- 使用 unit initial steps 的 combined solver；
- 使用 `(1, 1)` 的 combined solver；
- 使用 provisional pair 的 combined solver；以及
- 使用 historical ratio-and-logarithm rule 的 combined solver。

每个 configuration 只运行一次到 `500*N`。在 `200*N` 和 `500*N` checkpoints
上使用分别计算 common targets 的 history-based profiles，并且只针对 `500*N` 的
actual returned points 使用 output-based profiles。此阶段检查 plain result 的
transfer，不是新的 unrestricted tuning pass。

- `[todo]` 确认 provisional pair 仍有竞争力。
- `[todo]` 检查与 acceleration 的 interactions。
- `[todo]` 检查与 early termination 的 interactions。
- `[todo]` 确认同一 pair 适用于 production `alpha_init = "auto"` rule。省略
  `alpha_init` 是否应调用该 rule，仍属于独立的 T10 release decision。

如果 provisional pair 失败，则记录该 failure，并带着具体 hypothesis 回到 T6。不要
根据一张有利的 figure 选择 replacement。

### T10：集成并 audit production rule

- `[todo]` 重写 production helper，使代码与 selected mathematical formula 直接
  一致。
- `[todo]` 明确决定：省略 `alpha_init` 应继续表示 unit steps，还是应调用已完成的
  automatic rule。只有在 provisional pair 通过 combined solver check 后，才能作出
  此 release decision；重写 helper 时不要隐式改变 default。
- `[todo]` 决定 `c_x` 和 `c_tau` 是 fixed internal constants，还是 documented user
  options。除非 users 明确需要改变它们，否则优先使用 fixed constants。
- `[todo]` 删除重复或 obsolete automatic step rules。
- `[todo]` 让 released solver 和 accelerated implementation 使用同一个 helper，
  或使用 provably equivalent logic。
- `[todo]` 为 final formula 和 coefficients 添加 regression tests。
- `[todo]` 运行 ordinary BDS test suite。
- `[todo]` 在禁用 acceleration 时运行 acceleration equivalence tests。
- `[todo]` 运行最终的 combined solver tests。
- `[todo]` 请求针对 final helper 和 tests 的 focused human review。

### T11：同步 manuscript

仅在 T10 完成后：

- `[todo]` 用 released formula 替换 manuscript formula。
- `[todo]` 说明 selected coefficient values。
- `[todo]` 解释 zero coordinate convention。
- `[todo]` 简要解释 tolerance multiplier 的作用。
- `[todo]` 重新生成 internal initial step size comparison。
- `[todo]` 确保所有 external solver comparisons 使用 selected rule。
- `[todo]` 更新 numerical experiment plan 和 S6 status。

paper 应报告 selected rule 和 focused evidence，无需展示完整 parameter search。

## 决策规则（Decision Rules）

最终 decision 必须依据以下规则写出，而不是选择视觉上最好的 curve。

1. Correctness 是强制要求。任何违反 formula tests 或产生无效 initial
   steps 的 candidate 都必须淘汰。
2. Robustness 优先于某一张 profile 上的小幅收益。避免选择在任一 budget
   下造成 final solved fraction 实质下降的 candidate。
3. 使用 paired problem-level evidence，判断收益与损失是否广泛存在，还是
   仅由少数 problems 驱动。
4. 要求 candidate 在主要 accuracy levels 上保持一致。
5. `c_x` challenger 必须在 `200*N` 和 `500*N` 两个 checkpoint 上分别对
   `c_x = 1` 展现清晰、稳定且实质的优势。只在一个 checkpoint 获胜，或在
   任一 checkpoint 打平，均不满足晋级条件。
6. 使用 transformed problems 进行 regression check。
7. 将 `c_x = 1` 视为 incumbent。其他 `c_x` 必须展现稳定且实质的优势才能
   替换它；若实际等价，则保留 incumbent。
8. 如果多个 candidates 满足全部 advancement criteria，将它们全部保留为
   finalists，并在查看实际 evidence 后再进行 tie-breaking。不得仅为强行选出
   一个 winner 而扩大 grid 或预设 a priori ranking。
9. 将 `c_tau = 1` 视为 incumbent。在相同 `c_x` 下，更大的取值必须在两个
   budget checkpoint 上分别明确优于它；出现 tie、mixed budget result 或
   inactive lower bound 时，均保留 `c_tau = 1`。
10. Controlled tests 可以淘汰不安全的 `c_tau`，但如果没有满足要求的
    benchmark advantage，不能仅凭 controlled tests 选择更大的取值。
11. 除非在查看最终结果前已经固定 weights 及其解释，否则不得使用 weighted
    aggregate score。
12. 记录 random transformations 或其他 randomized features 带来的
    uncertainty。不得将 run variation 范围内的小差异解释为 ranking。

在本研究中，任一 budget checkpoint 的 solved fraction 下降超过一个百分点，
即构成 material regression。即使 solved fraction 不变，如果 jointly solved
problem set 中相当大比例的 paired costs 持续上升，同样构成 material regression。
这些 criteria 在查看 screening results 前即已固定，之后不得放宽。

## 必需输出（Required Outputs）

完成本研究时必须提供：

- test helper 和 runner；
- formula unit tests；
- controlled tolerance suite；
- activation audit；
- raw run data；
- reproducibility manifests；
- 分别对应 `200*N` prefixes 和 `500*N` histories 的 common target tables；
- history-based profiles；
- output diagnostics；
- paired problem-level tables；
- `200*N` 和 `500*N` 的结果；
- transformed problem validation；
- combined solver transfer check；
- 书面的 coefficient decision；以及
- 最终 production patch 和 regression tests。

建议的 result directory stamp：

```text
auto_alpha_init_tuning_<stage>_<budget>_<feature>_<timestamp>
```

建议的 summary file：

```text
DECISION_auto_initial_step_size.md
```

## 决策记录（Decision Record）

随着研究推进填写本节。

### 固定的 screening protocols

`c_x` screening：

- 将 `c_x = 1` 视为 incumbent，并在整个 `c_x` screen 中始终保留。
- challenger 只有在 `200*N` 和 `500*N` 上分别对 incumbent 展现清晰、稳定且
  实质的优势，才能晋级；只赢一个 checkpoint 或在任一 checkpoint 打平都不能
  晋级。
- 任一 checkpoint 的 solved fraction 下降超过一个百分点即为 material
  regression，并淘汰该 challenger。
- 如果没有 challenger 晋级，则只使用 `c_x = 1`；如果恰有一个晋级，则将它与
  incumbent 一起保留；如果多个 challenger 晋级，则全部记录为 finalists，并在
  查看实际 evidence 后再进行 tie-breaking。
- 对晋级的 interior challenger 最多运行一次预先声明的 local confirmation
  round；不得进行 recursive refinement。
- 出现多个 finalists 不构成扩大 grid 或预设 a priori ranking 的理由。

`c_tau` coverage：

- 在 activation audit 和 deterministic controlled tests 中使用全部整数
  `1, ..., 10`。
- general benchmark 只使用固定 representatives `{1, 2, 5, 10}`；查看结果后
  不得扩大该集合。
- 将 `c_tau = 1` 视为 incumbent。对每个保留的 `c_x`，`{2, 5, 10}` 只有在
  `200*N` 和 `500*N` 上分别明确优于它，才能替换它。
- 出现 tie、mixed budget result 或 effectively inactive tolerance lower
  bound 时，保留 `c_tau = 1`。
- Controlled tests 可以淘汰不安全的 challenger 并解释结果，但不能独立选择更大的
  `c_tau`。
- 如果多个 challengers 满足全部 criteria，则全部记录为 finalists，并在查看实际
  evidence 后再进行 tie-breaking；不得为了强行得到唯一选择而扩大 grid。

Budget 与 target protocol：

- 每个 solver/problem/configuration combination 只运行一次，直到 `500*N`。
- 使用每条已保存 history 的前 `200*N` 次 evaluations 重建 `200*N` benchmark。
- 从完整的 `200*N` history prefixes pool 计算 `200*N` common targets；另行从
  完整的 `500*N` histories 计算 `500*N` common targets。
- `200*N` analysis 不得使用由 `500*N` data 计算的 targets。
- 两个 checkpoint 都使用 history-based evidence；returned-point/output
  evidence 只用于 `500*N` runs 的实际终点。

### 基础 configuration

- BDS commit：尚未记录。
- profile tool commit 或 version：尚未记录。
- MATLAB version：尚未记录。
- problem list：固定为已完成 audit 的 122-problem S2MPJ snapshot，类型为
  unconstrained，dimensions 为 `6` 至 `50`，并使用现有的 42-problem
  exclusion list；必须将准确且有序的 names 复制到 run manifest。
- Algorithm：`cbds`；effective coordinate basis 为 `eye(N)`，共 `N` 个
  blocks，batch size 为 `N`，采用 sorted visiting。
- Step tolerance：固定为 `1e-6`。
- Expansion factor：固定为 released noiseless default `1.8`。
- Contraction factor：固定为 released noiseless default `0.5`。
- Noisy flag：固定为 `false`。
- Forcing function：固定为 `@(alpha) alpha^2`。
- Reduction factor：固定为 `[0, eps, eps]`。
- Inner polling 和 cycling：分别固定为 `"opportunistic"` 和 `1`。
- Objective target：固定为 `-Inf`。
- Optional function-value stop 和 estimated-gradient stop：disabled。
- BDS seed：固定 experimental value `0`。
- Plain feature：每个 problem 运行一次。
- Transformed feature：固定 profile seed `0`，运行五次，使用 pure
  orthogonal rotation，`condition_factor = 0`。

### Screening 结果

- Activation audit：尚未运行。
- `c_x` incumbent：`1`。
- 满足条件的 `c_x` challengers/finalists：尚未选择。
- `c_tau` incumbent：`1`。
- 每个 `c_x` 下满足条件的 `c_tau` challengers/finalists：尚未选择。
- Result paths：无。

### Finalists 记录

尚未选择 finalists。

### 暂定 decision（Provisional Decision）

尚未选择 provisional coefficient pair。

### Combined solver check 状态

尚未运行。

### 最终 decision（Final Decision）

尚未选择 final coefficient pair。

## 完成 criteria（Completion Criteria）

只有满足以下全部条件，才能将本 TODO 标记为 `[done]`：

- 已选择一个 coefficient pair，并提供书面 rationale。
- 已检查两个 budgets。
- 已量化 `c_tau` 的 activation。
- Controlled edge cases 和 floating-point scale cases 已通过。
- 已保留 raw data 和 manifests。
- 每次 `200*N` 和 `500*N` cross-candidate comparison 都使用了由相应
  history horizon 计算的独立 common targets。
- selected pair 已通过 transformed problem validation。
- selected pair 已通过 combined solver check。
- released implementation 和 accelerated implementation 使用同一 rule。
- production code 已有聚焦的 regression tests 和 human review。
- manuscript formula 与 numerical experiment 已同步。
