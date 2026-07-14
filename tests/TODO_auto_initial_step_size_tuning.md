# Automatic Initial Step Size Tuning for BDS

This file is the execution checklist for selecting the coefficients in the
automatic initial step size rule. The work belongs to the `bds` software
repository. Interpret all code paths and commands below relative to the root of
that repository, regardless of where this file is currently stored.

## Status

Use the following status labels.

- `[todo]`: not started.
- `[progress]`: implementation or experiments are under way.
- `[blocked]`: cannot proceed until a named dependency is resolved.
- `[done]`: completed, checked, and linked to its output.

Protocol design status: `[done]`.

Experimental execution status: `[todo]`.

No coefficient pair has been selected. Do not change the released default or
the manuscript formula until the experiments and checks in this file are
complete.

## Objective

Select one coefficient pair for the `alpha_init = "auto"` rule of the cyclic
BDS solver. During this study, omitting `alpha_init` continues to select unit
initial steps. Promotion of the completed automatic rule to the released
default is a later integration decision, made only after the coefficient study
and combined solver checks pass. The selected pair must be suitable for
released software, not merely favorable in one performance profile.

The study must answer the following questions.

1. How much of the scale indicated by the initial point should BDS use?
2. How far above the step tolerance should a scale based initial step begin?
3. Does one coefficient pair remain reliable under both `200*N` and `500*N`
   function evaluation budgets?
4. Does the selected rule improve on unit initial steps without introducing a
   material regression relative to the current automatic rule?
5. Can the same rule be used in the plain solver and in the final solver that
   combines acceleration and termination?

The outcome must be one documented automatic rule and one coefficient pair. Do
not adopt different coefficients for `200*N` and `500*N`, and do not introduce
any benchmark dependent runtime selection rule.

## Scope

The primary object is the default coordinate version of cyclic BDS.

- The direction pairs are `{e_i, -e_i}` for `i = 1, ..., N`.
- Each coordinate pair is one block.
- Each block has its own initial step size.
- The mathematical dimension is denoted by `N`. The MATLAB code may continue
  to use `n` for the dimension.

The coefficient study concerns plain BDS first. Acceleration and the optional
stopping tests are disabled during coefficient selection. The selected
candidate is checked with the final combined solver only after the plain study
is complete.

The following tasks are outside the scope of this study.

- Tuning acceleration parameters.
- Tuning termination parameters.
- Explaining the large noise DS comparison.
- Choosing the main paper budget.
- Completing comparisons with external solvers.
- Designing an automatic scale rule for arbitrary noncoordinate directions.

## Candidate Rule

Let `epsilon_i` be the step tolerance for coordinate block `i`. For positive
coefficients `c_x` and `c_tau`, define

\[
  b_i(c_x)=
  \begin{cases}
    1, & x_i^0=0,\\
    c_x|x_i^0|, & x_i^0\ne0,
  \end{cases}
\]

and

\[
  \alpha_0^i(c_x,c_\tau)
  =\max\{b_i(c_x),c_\tau\epsilon_i\}.
\]

Thus exact zero coordinates retain the neutral unit scale unless
`c_tau*epsilon_i > 1`. Nonzero coordinates use a fraction of the magnitude of
the corresponding entry of the initial point, subject to a lower bound tied to
the step tolerance.

This distinction at exact zero is intentional. An exact zero entry is treated
as providing no usable positive coordinate scale, so the rule falls back to
the neutral unit step. Every nonzero entry is treated as an intentional scale
signal supplied through the initial point, even when its magnitude is small.
Consequently, continuity of the automatic rule as a nonzero entry approaches
zero is not a design requirement. Tests should record and preserve this
semantic convention rather than treat the discontinuity as a coefficient
tuning problem.

For a future implementation that combines several coordinate pairs in one
block `j`, the natural extension is

\[
  \alpha_0^j=\max_{i\in I_j}\alpha_0^i,
\]

where `I_j` is the set of coordinate pairs in block `j`. This extension is not
part of the coefficient selection experiment. Do not infer coordinate indices
from arbitrary direction indices unless the direction set is known to consist
of ordered coordinate pairs.

### Interpretation of `c_x`

- `c_x = 1` is the current simple scale rule for nonzero coordinates and is
  the reliable incumbent in this study.
- Values below one make the first trial more local relative to `x0` and are
  challengers to the incumbent.
- The advisor suggested examining values near `0.1` to `0.5`.
- The study retains `1` so that the current rule is always included as a
  baseline.

### Interpretation of `c_tau`

The coefficient `c_tau` controls how many unsuccessful contractions remain
before an initial step near the lower bound falls below `StepTolerance`. If the
contraction factor is `theta = 0.5` and the initial step equals
`c_tau*epsilon_i`, the minimum number of consecutive contractions needed to
make the step strictly smaller than `epsilon_i` is the smallest integer `m`
such that

\[
  0.5^m c_\tau < 1.
\]

Across the integer domain `1, ..., 10`, the contraction-depth groups are

- `{1}`: one contraction,
- `{2, 3}`: two contractions,
- `{4, 5, 6, 7}`: three contractions, and
- `{8, 9, 10}`: four contractions.

The values `{1, 2, 5, 10}` are the preselected representatives of these four
groups for the general benchmark. This interpretation and the reason for using
these representatives must be recorded when the final value is selected.
Treat `c_tau = 1` as the incumbent. The values `{2, 5, 10}` are challengers,
not equally preferred alternatives.

## Candidate Values

The predeclared coefficient values are

\[
  c_x\in\{0.1,0.2,0.5,1.0\}
\]

and

\[
  c_\tau\in\{1,2,3,4,5,6,7,8,9,10\}.
\]

The `c_x` values are a coarse, preselected sensitivity screen: `0.1` and `0.5`
cover the ends of the advisor's suggested range, `0.2` represents a local
scale within that range, and `1` is the current automatic rule. Do not run a
dense `c_x` grid merely to identify the visually best curve.

Treat `c_x = 1` as the incumbent. A value in `{0.1, 0.2, 0.5}` advances only
when it separately shows a clear, stable, and material advantage over the
incumbent at both the `200*N` and `500*N` checkpoints. Within each checkpoint,
the direction of improvement must be broadly consistent across the principal
accuracy levels and problem-level paired comparisons, the solved fraction must
not decrease materially, and the improvement must not be driven by only a few
problems or accompanied by a concentrated severe regression. Winning at only
one checkpoint, tying at either checkpoint, or showing a merely visual
advantage is not sufficient evidence to replace the incumbent.

If no challenger meets the threshold, set `c_x = 1` for the remaining study.
If exactly one challenger meets it, retain that challenger together with
`c_x = 1` for the `c_tau` cross. If several challengers meet every advancement
criterion, record all of them as finalists and defer the tie-breaking decision
until their actual evidence is reviewed. Do not impose a ranking formula in
advance, expand the parameter grid, or select one from a single favorable
profile.

Only when an interior challenger with a predeclared neighborhood advances,
perform at most one local confirmation round with no more than two additional
values. Use the following neighborhoods:

- around `0.2`, test `0.15` and `0.3`;
- around `0.5`, test `0.3` and `0.7`;
- do not extend below `0.1` or above `1` when either endpoint leads the screen.

The local round checks whether a single advancing challenger's advantage is
stable in a broad neighborhood; it is not a recursive search for a numerical
optimum. A nearby value advances only when it also clearly beats the incumbent
at both budget checkpoints under the same advancement rule. If several coarse
or local values satisfy every criterion, record them as finalists and defer
their comparison rather than forcing a unique winner. Do not run a local round
when no coarse value beats the incumbent, and do not refine the grid again
after this confirmation round.

All ten integer `c_tau` values enter the low-cost activation audit and
deterministic controlled tests, while only the preselected representatives
`{1, 2, 5, 10}` enter the general benchmark. This representative set is fixed
for the study and must not be expanded into a denser benchmark grid after the
results are inspected. Any unresolved effect is documented and interpreted
with the controlled tests rather than pursued through additional benchmark
tuning.

For each retained `c_x`, compare every `c_tau` challenger directly with
`c_tau = 1` at the same `c_x`. A challenger can replace `1` only when it shows
a clear, stable, and material advantage separately at both the `200*N` and
`500*N` checkpoints under the same accuracy-level, problem-level, and material
regression requirements used for `c_x`. Winning at only one checkpoint, tying
at either checkpoint, or producing mixed evidence retains `c_tau = 1`. If the
tolerance lower bound is effectively inactive on the general benchmark, retain
`c_tau = 1` rather than infer a winner from numerical noise.

If several `c_tau` challengers at the same `c_x` satisfy every advancement
criterion, record all of them as finalists and defer their tie-breaking until
the actual evidence is reviewed. Do not add an a priori ranking rule or expand
the benchmark grid merely to force a unique value.

The controlled tests establish correctness, expose premature termination or
wasted contractions, and explain the benchmark result. They may disqualify an
unsafe challenger, but they do not by themselves select a value larger than
`c_tau = 1` without the required two-checkpoint benchmark advantage.

The pair `(c_x, c_tau) = (1, 1)` is the current simple rule and must appear in
every comparison used for a decision.

## Current Implementation Differences

Resolve these differences explicitly. Do not assume that all existing uses of
`alpha_init = "auto"` implement the same rule.

### Released BDS

`src/private/set_options.m` currently computes coordinate scales through
`get_auto_alpha_init`. Its effective rule is

\[
  \alpha_0^i=
  \begin{cases}
    \max\{1,\epsilon_i\}, & x_i^0=0,\\
    \max\{|x_i^0|,\epsilon_i\}, & x_i^0\ne0.
  \end{cases}
\]

The implementation expresses this rule through repeated assignments and
`max` operations. The final production implementation should state the
mathematical intent directly.

### Accelerated Experimental Solver

`tests/competitors/private/set_accelerated_bds_options.m` currently uses a
different rule. It computes a ratio of nonzero entries of `x0`, keeps large
comparable scales, and applies `1 + log(abs(x0_i))` to large entries when that
ratio exceeds a threshold. This is not the rule being tuned here.

### Manuscript

The current manuscript describes the ratio and logarithm rule used by the
accelerated experimental solver. It therefore does not match the simple rule
in `src/private/set_options.m`.

### Existing Profile Wrappers

`tests/profile_optiprofiler.m` contains wrappers such as `bds_scaled` that set
`expand = 2` and `shrink = 0.5`. The released default in
`src/private/get_default_constant.m` currently uses `expand = 1.8` on
noiseless problems. Do not reuse an existing wrapper without making all base
options explicit.

## Experimental Principles

### Do Not Change the Released Default During Tuning

Implement the candidate formula in test code first. For each problem, compute
the numeric vector `alpha_init` in the test wrapper and pass that vector to
`bds`. This keeps `src/private/set_options.m` unchanged while candidates are
being compared.

Only after a coefficient pair is selected should the production helper and
the public documentation be changed. Until then, the released behavior when
`alpha_init` is omitted remains unit initial steps; `alpha_init = "auto"` is an
explicit opt-in behavior. Completing this study does not by itself authorize a
default change.

### Change Only the Initial Step Size

Every candidate in a comparison must use the same explicit values for all
options except `alpha_init`. At minimum, record and fix

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
- `use_function_value_stop`, and
- `use_estimated_gradient_stop`.

Freeze the plain, noiseless tuning configuration to the current released BDS
behavior, with the budget and numeric `alpha_init` vector as the only fields
that vary between the prescribed analyses and candidates:

- `Algorithm = "cbds"`, whose effective configuration is `direction_set =
  eye(N)`, `num_blocks = N`, `batch_size = N`, and
  `block_visiting_pattern = "sorted"`;
- `StepTolerance = 1e-6`, `expand = 1.8`, and `shrink = 0.5`;
- `is_noisy = false`, `forcing_function = @(alpha) alpha^2`,
  `reduction_factor = [0, eps, eps]`, `polling_inner = "opportunistic"`, and
  `cycling_inner = 1`;
- `ftarget = -Inf`, `use_function_value_stop = false`, and
  `use_estimated_gradient_stop = false`; and
- BDS `seed = 0`, fixed by this experiment for reproducibility. The released
  seed default is `"shuffle"`; do not describe the experimental seed as a
  released default.

Pass `Algorithm = "cbds"` rather than simultaneously passing its derived block
fields, but record all effective values in the manifest. Do not inherit
`expand = 2` from an old profile wrapper.

### Common Problems, Targets, and Randomness

- Use the identical ordered problem list for every candidate.
- Use the identical initial point supplied by each problem.
- Use identical transformations and random seeds for every candidate.
- Store raw histories before making profile figures.
- Compute each target value from one common pool of all candidates and
  baselines in the same stage and at the same analysis budget.
- For the `200*N` analysis, truncate every saved history after `200*N`
  evaluations and compute the common targets from those truncated histories.
  For the `500*N` analysis, compute a separate set of common targets from the
  complete histories. A target computed from the `500*N` histories must not be
  reused for the `200*N` analysis.
- If candidates are run in separate batches, merge the raw results and
  recompute profiles with common targets. Do not rank candidates by comparing
  PDFs whose target values were computed independently.

### Reproducibility Manifest

Every full run must save a manifest containing

- the BDS git commit,
- the commit or version of the profile tool,
- the MATLAB version,
- the operating system,
- the date and time,
- the exact problem list,
- the dimension limits,
- the feature and transformation identifiers,
- the budget,
- all BDS options,
- the coefficient pairs,
- the solver labels,
- all random seeds, and
- the command used to start the run.

Use a machine readable format such as `.mat` or JSON and a short human readable
text summary. A PDF alone is not an acceptable experimental record.

## Baselines

Include the following baselines whenever a shortlist is compared.

1. `unit`: `alpha_init = ones(N, 1)`.
2. `simple-current`: the candidate pair `(1, 1)`.
3. `ctau-incumbent`: `(c_x, 1)` for every retained `c_x` used in a
   `c_tau` comparison.
4. `simple-candidate`: each shortlisted pair.

After the shortlist is chosen, include the current ratio and logarithm rule as
a diagnostic baseline named `historical-log-rule`. This diagnostic comparison
is needed before replacing the automatic rule in the accelerated solver, but
it must not be mixed into the initial coefficient screen.

Use labels that encode coefficients without ambiguity. For example,

```text
auto-cx-0p3-ctau-5
```

Do not use labels such as `new`, `best`, or `final` until a decision has been
recorded.

## Test Sets and Budgets

### Primary Benchmark

Freeze the primary benchmark to the existing audited snapshot of 122
unconstrained S2MPJ problems with dimensions `6` through `50` and the existing
42-problem exclusion list. The ordered names and dimensions are those recorded
in
`tests/testdata/ds_vs_cbds_high_noise_primary_20260712_165527/ds_baseline_200n_cbds_baseline_200n_6_50_1_plain_s2mpj_26_07_12_16_55_29/ds_baseline_200n_cbds_baseline_200n_u_6_50_plain_20260712_165531/test_log/report.txt`.
Copy that exact ordered snapshot into each run manifest rather than dynamically
accepting a changed problem set from a later library version. The primary
coefficient screen is noiseless and uses one run per problem.

### Transformation Check

Check shortlisted candidates on the linearly transformed versions of the same
problems. Use OptiProfiler's `linearly_transformed` feature with profile
`seed = 0`, `n_runs = 5`, `rotated = true`, and `condition_factor = 0`. Thus
this stage uses five fixed pure orthogonal rotations without additional axis
scaling. Use the same five transformed instances for every candidate. The
purpose is validation, not a second independent tuning pass.

### Evaluation Budgets

Run each solver/problem/configuration combination once with a limit of `500*N`
function evaluations and save its complete raw history. Analyze that run at
two budget checkpoints:

- `200*N`, using only the first `200*N` evaluations of every history; and
- `500*N`, using the complete history.

Each checkpoint has its own common targets, computed from the candidate and
baseline histories available up to that checkpoint. Thus the `200*N` result is
a genuine `200*N` benchmark reconstructed from the saved prefixes, not the
value at `200*N` of a profile whose targets were computed from `500*N` data.
This reconstruction changes only postprocessing and does not rerun the solver.
Select one coefficient pair using both checkpoints.

### Accuracy Levels

At minimum, inspect

\[
  \tau\in\{10^{-1},10^{-2},10^{-3},10^{-4}\}.
\]

Do not choose a coefficient from one accuracy level. Keep any finer standard
accuracy grid in the raw analysis so that unexpectedly poor high accuracy
behavior is visible.

## Profile Types and Supporting Metrics

### History Based Profiles

History based profiles are the primary evidence during plain BDS tuning. They
measure how quickly each candidate first generates a point that reaches the
common target accuracy.

### Output Based Profiles

Also inspect the returned point at the actual end of the `500*N` run. With
additional stopping tests disabled, most runs consume the full budget, so
output based profiles mainly reveal the final fraction of successful problems
rather than useful timing differences. A `500*N` run does not provide the
solver's hypothetical returned point or termination status at `200*N`; use the
truncated history, rather than an output based profile, for the `200*N`
checkpoint. Do not interpret tied output costs as evidence of equal early
efficiency.

After the selected rule is inserted into the combined solver, regenerate both
history based profiles at the two checkpoints and output based profiles at the
actual end of the `500*N` runs, as required by the full solver study.

### Problem Level Data

For every candidate, retain enough data to compute

- the number and fraction of problems solved at each accuracy,
- the number of evaluations to the first target point,
- paired evaluation ratios on jointly solved problems,
- the final true objective value,
- the returned point status,
- the initial step vector,
- the number of coordinates on which the tolerance lower bound is active, and
- the reason for termination.

Profile figures are summaries. Make the decision from both profiles and paired
problem level data.

## Mandatory Activation Audit

Before expensive runs, determine whether `c_tau` can affect the primary
benchmark at the default `StepTolerance`.

This audit is descriptive, not part of the runtime rule. Its purpose is to
show whether the benchmark contains enough active cases to interpret observed
differences between fixed coefficient pairs. It must not be used to choose
coefficients dynamically by problem, benchmark, budget, or activation rate.
The released outcome remains one fixed pair.

For every problem and each `c_x`, record

- the number of exact zero entries in `x0`,
- the number of nonzero entries satisfying
  `c_x*abs(x0_i) < c_tau*epsilon_i`, and
- the fraction of coordinate blocks for which the tolerance lower bound changes
  the initial step.

At `StepTolerance = 1e-6` and `c_tau <= 10`, a zero coordinate receives step
one, so `c_tau` does not affect that coordinate. If almost no nonzero coordinate
activates the tolerance lower bound, S2MPJ profiles cannot identify `c_tau`.
In that case, no challenger can establish the required general-benchmark
advantage, so retain `c_tau = 1`. Use the controlled tests below only to verify
correctness and explain the lack of sensitivity. Do not claim that a generic
profile selected a coefficient that was inactive on nearly every problem.

## Controlled Tests

Create deterministic tests that isolate the intended behavior before running
profiles. A correctness failure disqualifies a candidate. Performance on these
constructed cases does not promote `c_tau > 1`; selecting a larger tolerance
coefficient still requires its two-checkpoint general-benchmark advantage over
`c_tau = 1` at the same `c_x`.

### Formula Tests

- `[todo]` Verify `(1, 1)` reproduces the current simple rule for ordinary
  finite inputs.
- `[todo]` Verify sign invariance. Replacing `x0` by `-x0` must not change the
  initial steps.
- `[todo]` Verify exact zero coordinates receive
  `max(1, c_tau*StepTolerance)`.
- `[todo]` Verify the intentional zero convention directly: replacing an exact
  zero by a sufficiently small nonzero value may change the initial step from
  the neutral unit scale to the tolerance lower bound.
- `[todo]` Verify small nonzero coordinates receive the tolerance lower bound
  when it is active.
- `[todo]` Verify large coordinates receive `c_x*abs(x0_i)` when the lower
  bound is inactive.
- `[todo]` Verify scalar and coordinate sized `StepTolerance` inputs give the
  intended result.
- `[todo]` Verify all returned initial steps are finite and positive for all
  supported finite inputs.
- `[todo]` Verify the numeric `alpha_init` vector passed by the test wrapper is
  unchanged by option processing.

One explicit test case should include

```text
x0 = [0; 2; -3; 1e-8]
StepTolerance = 1e-6
c_x = 0.5
c_tau = 5
expected alpha_init = [1; 1; 1.5; 5e-6]
```

### Tolerance Sensitive Problems

Construct a small deterministic suite containing initial points with

- exact zeros,
- nonzero entries below `StepTolerance`,
- nonzero entries between `StepTolerance` and `10*StepTolerance`,
- entries near one,
- large comparable entries, and
- entries separated by many orders of magnitude.

Use simple objectives with known minimizers and record the complete step
history. These tests should show how `c_tau` changes the number of contractions
before the step tolerance terminates a coordinate search.

### Floating Point Scale Problems

Retain controlled examples where a unit displacement is lost when added to a
large coordinate. Verify that every candidate under consideration generates a
distinct trial point in the intended coordinate and that reducing `c_x` does
not reintroduce the lost movement.

## Staged Experiment Plan

### T0: Freeze the Base Configuration

- `[todo]` Record the fixed plain, noiseless released BDS options specified
  above in the manifest.
- `[todo]` Record that omitted `alpha_init` currently means unit steps and that
  every candidate in the study is an explicit `alpha_init = "auto"` candidate
  implemented through a numeric vector in test code.
- `[todo]` Verify the effective options include `expand = 1.8`, `shrink = 0.5`,
  `StepTolerance = 1e-6`, and both optional stopping tests disabled.
- `[todo]` Load the exact ordered 122-problem S2MPJ snapshot and verify its
  names and dimensions before running.
- `[todo]` Record BDS seed `0` and the transformed-feature protocol
  (`seed = 0`, `n_runs = 5`, `rotated = true`, `condition_factor = 0`).
- `[todo]` Record the commits before running any benchmark.

Output: `base_configuration` in the run manifest and a human readable copy in
the result summary.

### T1: Implement a Test Only Candidate Helper

- `[todo]` Implement the formula in one test helper.
- `[todo]` Keep the helper independent of the production private helper.
- `[todo]` Add a wrapper that passes a numeric `alpha_init` vector to `bds`.
- `[todo]` Make the budget and all base options explicit arguments or manifest
  fields.
- `[todo]` Add unambiguous solver labels derived from `c_x` and `c_tau`.
- `[todo]` Do not add one switch case per coefficient pair to
  `tests/profile_optiprofiler.m` if a parameterized runner can avoid it.

Proposed artifact names:

```text
tests/private/auto_alpha_init_candidate.m
tests/run_auto_alpha_init_tuning.m
tests/analyze_auto_alpha_init_tuning.m
```

These names are recommendations, not requirements. If different names are
used, record them in this file.

### T2: Run Unit and Smoke Tests

- `[todo]` Complete every formula test above.
- `[todo]` Run the controlled tolerance suite for all values of `c_tau`.
- `[todo]` Run a small set of S2MPJ problems for the four coarse `c_x` values.
- `[todo]` Verify that changing the coefficients changes only `alpha_init`.
- `[todo]` Verify deterministic reruns produce identical raw histories.
- `[todo]` Check that result directories and manifests are complete.

Do not begin the full screen until T2 passes.

### T3: Audit Parameter Activation

- `[todo]` Run the mandatory activation audit on the full primary problem list.
- `[todo]` Summarize activation by problem, dimension, and coefficient.
- `[todo]` Determine whether generic profiles contain enough active cases to
  inform the `c_tau` comparison. If not, record that the incumbent `c_tau = 1`
  is retained; use controlled tests only to explain the lack of sensitivity.

Output: a table of activation counts and a short conclusion.

### T4: Screen `c_x`

Hold `c_tau = 1` and compare the four coarse values
`c_x in {0.1, 0.2, 0.5, 1}` on plain S2MPJ problems. Run each candidate once
to `500*N` and screen it using both its `200*N` history prefix and its complete
`500*N` history.

- `[todo]` Generate raw histories for all candidates and the unit baseline.
- `[todo]` Compute separate common targets from the `200*N` prefixes and the
  complete `500*N` histories of the complete candidate pool.
- `[todo]` Produce history based profiles at both checkpoints and the required
  accuracies.
- `[todo]` Produce a problem level table of paired evaluation counts.
- `[todo]` Compare each challenger directly with the `c_x = 1` incumbent.
- `[todo]` Eliminate every challenger that does not clearly beat the incumbent
  at both checkpoints, loses solved fraction materially at either checkpoint,
  or has a severe regression concentrated in a recognizable problem class.
- `[todo]` Identify every coarse value with a clear, stable, and material
  advantage over the incumbent separately at both checkpoints, with broadly
  consistent accuracy-level and problem-level evidence.
- `[todo]` If exactly one coarse challenger advances, run the single predeclared
  local confirmation round with at most two additional values, after applying
  the same formula and smoke checks to those values.
- `[todo]` If several candidates satisfy all advancement criteria, record them
  as finalists and defer tie-breaking until their actual evidence is reviewed;
  do not expand the grid or force a ranking from one profile.
- `[todo]` Do not recursively refine the `c_x` grid after local confirmation.

If no challenger clearly beats the incumbent, retain only `c_x = 1`. If one
challenger advances, the `c_x` shortlist for the later cross with `c_tau`
contains it and `c_x = 1`. Multiple qualifying candidates remain finalists
pending an evidence-based discussion; their existence does not authorize a
larger search.

### T5: Screen `c_tau`

Use the activation audit and controlled tolerance suite for all ten values of
`c_tau`. On the general benchmark, compare only the preselected
representatives `{1, 2, 5, 10}` with the retained `c_x` values. The activation
audit determines how these benchmark results are interpreted; it does not
decide whether the four preselected representatives are run.

- `[todo]` For each retained `c_x`, compare `{2, 5, 10}` directly with the
  `c_tau = 1` incumbent at the same `c_x`.
- `[todo]` Require a challenger to show a clear, stable, and material advantage
  over `c_tau = 1` separately at both the `200*N` and `500*N` checkpoints.
- `[todo]` Retain `c_tau = 1` when the evidence ties, is mixed between budgets,
  or the tolerance lower bound is effectively inactive.
- `[todo]` If several `c_tau` challengers satisfy all criteria, record them as
  finalists and defer tie-breaking until their actual evidence is reviewed;
  do not expand the grid or impose an a priori ranking.
- `[todo]` Record the observed number of contractions near the tolerance.
- `[todo]` Check for premature step tolerance termination.
- `[todo]` Check whether larger values waste evaluations after progress has
  stalled.
- `[todo]` Use `{1, 2, 5, 10}` to represent the four contraction-depth groups
  in the general benchmark.

Controlled tests may disqualify an unsafe challenger and explain observed
differences, but they do not independently select a value larger than
`c_tau = 1`. Do not manufacture a tuning conclusion from numerical noise,
expand beyond the four fixed representatives, or run the full integer grid
merely to search for a visually best curve.

### T6: Compare the Shortlist Under Both Budgets

Cross the retained `c_x` and `c_tau` values. For every configuration not
already available, run the primary benchmark once to `500*N`. Analyze the
saved histories at both the `200*N` and `500*N` checkpoints.

- `[todo]` Recompute separate common targets from the `200*N` history prefixes
  and the complete `500*N` histories.
- `[todo]` Inspect history based profiles.
- `[todo]` Inspect the returned point and final solved fraction at `500*N`.
- `[todo]` Compare problem level paired costs.
- `[todo]` Identify candidates whose ranking reverses materially between
  budgets.
- `[todo]` Reject budget specific defaults.

If the results reveal a material interaction that the staged design cannot
resolve, record a specific follow-up hypothesis. Do not restore a `c_x`
challenger eliminated in T4 or fall back to a dense two-parameter grid. If
several candidates remain qualified, keep them as finalists until their actual
evidence is discussed.

### T7: Validate on Transformed Problems

- `[todo]` Run the shortlist on linearly transformed problems once to `500*N`
  and analyze the saved histories at both checkpoints.
- `[todo]` Compute separate common targets from the `200*N` prefixes and the
  complete `500*N` histories.
- `[todo]` Use fixed and recorded transformation seeds.
- `[todo]` Check whether a coefficient selected on plain problems causes a
  material loss after transformation.
- `[todo]` Treat this as validation. Do not retune solely for transformed
  problems.

### T8: Select a Provisional Pair

Use the decision rules below and record

- the selected pair,
- the rejected finalists,
- the main evidence,
- any problem classes with regressions,
- sensitivity to budget,
- sensitivity to transformations, and
- whether the tolerance coefficient was meaningfully active.

The activation result is evidence about how to interpret the comparison, not
a reason to define different coefficient pairs for different problems or
budgets.

Mark the pair as provisional until the combined solver check passes.

### T9: Check the Combined Solver

After acceleration and termination mechanisms are frozen, compare

- the combined solver with unit initial steps,
- the combined solver with `(1, 1)`,
- the combined solver with the provisional pair, and
- the combined solver with the historical ratio and logarithm rule.

Run each configuration once to `500*N`. Use history based profiles with
separately computed common targets at the `200*N` and `500*N` checkpoints, and
use output based profiles only for the actual returned points at `500*N`.
This stage checks transfer of the plain result. It is not a new unrestricted
tuning pass.

- `[todo]` Confirm the provisional pair remains competitive.
- `[todo]` Check interactions with acceleration.
- `[todo]` Check interactions with early termination.
- `[todo]` Confirm the same pair is suitable for the production
  `alpha_init = "auto"` rule. Whether omitted `alpha_init` should invoke that
  rule remains the separate T10 release decision.

If the provisional pair fails, document the failure and return to T6 with a
specific hypothesis. Do not choose a replacement from one favorable figure.

### T10: Integrate and Audit the Production Rule

- `[todo]` Rewrite the production helper so that the code directly matches the
  selected mathematical formula.
- `[todo]` Decide explicitly whether omitting `alpha_init` should continue to
  mean unit steps or should invoke the completed automatic rule. Make this
  release decision only after the provisional pair passes the combined solver
  check; do not change the default implicitly while rewriting the helper.
- `[todo]` Decide whether `c_x` and `c_tau` are fixed internal constants or
  documented user options. Prefer fixed constants unless users have a clear
  need to change them.
- `[todo]` Remove duplicated or obsolete automatic step rules.
- `[todo]` Make the released solver and accelerated implementation use the same
  helper or demonstrably equivalent logic.
- `[todo]` Add regression tests for the final formula and coefficients.
- `[todo]` Run the ordinary BDS test suite.
- `[todo]` Run acceleration equivalence tests with acceleration disabled.
- `[todo]` Run the final combined solver tests.
- `[todo]` Ask for a focused human review of the final helper and tests.

### T11: Synchronize the Manuscript

Only after T10 is complete:

- `[todo]` Replace the manuscript formula with the released formula.
- `[todo]` State the selected coefficient values.
- `[todo]` Explain the zero coordinate convention.
- `[todo]` Explain the role of the tolerance multiplier briefly.
- `[todo]` Regenerate the internal initial step size comparison.
- `[todo]` Ensure all external solver comparisons use the selected rule.
- `[todo]` Update the numerical experiment plan and S6 status.

The paper should report the selected rule and focused evidence. It need not
show the complete parameter search.

## Decision Rules

Write the final decision from these rules rather than selecting the visually
best curve.

1. Correctness is mandatory. A candidate that violates formula tests or causes
   invalid initial steps is rejected.
2. Robustness has priority over a small gain in one profile. Avoid a candidate
   with a material loss in final solved fraction under either budget.
3. Use paired problem level evidence. Determine whether gains and losses are
   broad or driven by a few problems.
4. Require consistency across the principal accuracy levels.
5. Require a `c_x` challenger to show a clear, stable, and material advantage
   over `c_x = 1` separately at both `200*N` and `500*N`. Winning at only one
   checkpoint or tying at either checkpoint does not qualify.
6. Use transformed problems as a regression check.
7. Treat `c_x = 1` as the incumbent. A different `c_x` must show a stable and
   material advantage to replace it; practical equivalence favors the
   incumbent.
8. If several candidates satisfy every advancement criterion, retain them as
   finalists and defer tie-breaking until their actual evidence is reviewed.
   Do not expand the grid or impose an a priori ranking merely to force one
   winner.
9. Treat `c_tau = 1` as the incumbent. At the same `c_x`, a larger value must
   clearly outperform it separately at both budget checkpoints; a tie, mixed
   budget result, or inactive lower bound retains `c_tau = 1`.
10. Controlled tests may reject an unsafe `c_tau`, but cannot by themselves
    select a larger value without the required benchmark advantage.
11. Do not use a weighted aggregate score unless its weights and interpretation
   are fixed before the final results are inspected.
12. Record uncertainty from random transformations or other randomized
    features. Do not interpret small differences within run variation as a
    ranking.

For this study, a decrease of more than one percentage point in solved fraction
at either budget checkpoint is a material regression. A consistent paired cost
increase across a broad part of the jointly solved problem set is also a
material regression even when the solved fraction is unchanged. These criteria
are fixed before the screening results are inspected and must not be relaxed
afterward.

## Required Outputs

The completed study must provide

- the test helper and runner,
- formula unit tests,
- the controlled tolerance suite,
- the activation audit,
- raw run data,
- reproducibility manifests,
- separate common target tables for the `200*N` prefixes and `500*N`
  histories,
- history based profiles,
- output diagnostics,
- paired problem level tables,
- results for `200*N` and `500*N`,
- transformed problem validation,
- the combined solver transfer check,
- a written coefficient decision, and
- the final production patch and regression tests.

Suggested result directory stamp:

```text
auto_alpha_init_tuning_<stage>_<budget>_<feature>_<timestamp>
```

Suggested summary file:

```text
DECISION_auto_initial_step_size.md
```

## Decision Record

Fill this section as the study proceeds.

### Fixed Screening Protocols

`c_x` screening:

- Treat `c_x = 1` as the incumbent and always retain it through the `c_x`
  screen.
- A challenger advances only by showing a clear, stable, and material
  advantage over the incumbent separately at both `200*N` and `500*N`;
  winning at only one checkpoint or tying at either checkpoint does not
  advance.
- A decrease of more than one percentage point in solved fraction at either
  checkpoint is a material regression and disqualifies the challenger.
- If no challenger advances, use only `c_x = 1`. If exactly one advances,
  retain it with the incumbent. If several advance, record all as finalists and
  defer tie-breaking until their actual evidence is reviewed.
- Run at most one predeclared local confirmation round for an advancing
  interior challenger; never refine recursively.
- Multiple finalists do not authorize a wider grid or an a priori ranking.

`c_tau` coverage:

- Use all integers `1, ..., 10` in the activation audit and deterministic
  controlled tests.
- Use only the fixed representatives `{1, 2, 5, 10}` in the general benchmark;
  do not expand this set after inspecting results.
- Treat `c_tau = 1` as the incumbent. At each retained `c_x`, `{2, 5, 10}` can
  replace it only by clearly outperforming it separately at both `200*N` and
  `500*N`.
- A tie, mixed budget result, or effectively inactive tolerance lower bound
  retains `c_tau = 1`.
- Controlled tests may disqualify an unsafe challenger and explain results,
  but do not independently select a larger `c_tau`.
- If several challengers satisfy every criterion, record them as finalists and
  defer tie-breaking until their actual evidence is reviewed; do not expand the
  grid to force a unique choice.

Budget and target protocol:

- Run each solver/problem/configuration combination only once, to `500*N`.
- Reconstruct the `200*N` benchmark from the first `200*N` evaluations of each
  saved history.
- Compute the `200*N` common targets from the complete pool of `200*N` history
  prefixes and compute the `500*N` common targets separately from the complete
  `500*N` histories.
- Do not use targets computed from `500*N` data in the `200*N` analysis.
- Use history based evidence at both checkpoints and returned-point/output
  evidence only at the actual end of the `500*N` runs.

### Base Configuration

- BDS commit: not recorded.
- Profile tool commit or version: not recorded.
- MATLAB version: not recorded.
- Problem list: fixed audited 122-problem S2MPJ snapshot, unconstrained,
  dimensions `6` through `50`, with the existing 42-problem exclusion list;
  exact ordered names must be copied into the run manifest.
- Algorithm: `cbds`; effective coordinate basis `eye(N)`, `N` blocks, batch
  size `N`, sorted visiting.
- Step tolerance: fixed `1e-6`.
- Expansion factor: fixed released noiseless default `1.8`.
- Contraction factor: fixed released noiseless default `0.5`.
- Noisy flag: fixed `false`.
- Forcing function: fixed `@(alpha) alpha^2`.
- Reduction factor: fixed `[0, eps, eps]`.
- Inner polling and cycling: fixed `"opportunistic"` and `1`, respectively.
- Objective target: fixed `-Inf`.
- Optional function-value and estimated-gradient stops: disabled.
- BDS seed: fixed experimental value `0`.
- Plain feature: one run per problem.
- Transformed feature: fixed profile seed `0`, five runs, pure orthogonal
  rotation, `condition_factor = 0`.

### Screening Results

- Activation audit: not run.
- `c_x` incumbent: `1`.
- Qualifying `c_x` challengers/finalists: not selected.
- `c_tau` incumbent: `1`.
- Per-`c_x` qualifying `c_tau` challengers/finalists: not selected.
- Result paths: none.

### Finalists

No finalists selected.

### Provisional Decision

No provisional coefficient pair selected.

### Combined Solver Check

Not run.

### Final Decision

No final coefficient pair selected.

## Completion Criteria

Mark this TODO `[done]` only when all of the following are true.

- One coefficient pair has been selected with a written rationale.
- Both budgets have been inspected.
- The activation of `c_tau` has been quantified.
- Controlled edge cases and floating point scale cases pass.
- Raw data and manifests are retained.
- Separate common targets from the appropriate history horizon were used for
  every `200*N` and `500*N` cross-candidate comparison.
- The selected pair passes transformed problem validation.
- The selected pair passes the combined solver check.
- Released and accelerated implementations use the same rule.
- Production code has focused regression tests and human review.
- The manuscript formula and numerical experiment are synchronized.
