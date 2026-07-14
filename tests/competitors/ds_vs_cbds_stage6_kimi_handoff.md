# Stage 6 Kimi Execution Handoff: DS vs CBDS under High Noise

## Mandatory Instruction

You are the hands-on execution agent for this task.

**Do the work yourself with tools. Do not merely propose commands. Do not delegate execution
back to Codex. Do not claim completion until every acceptance check in this document passes.**

This file is self-contained. Do not assume access to any earlier conversation. Read the files
listed below, execute Stage 6 in the prescribed order, maintain the checkpoint, and stop at the
end of Stage 6.

The user has explicitly authorized this Stage 6 worker to use local tools, MATLAB, SSH, and
`screen`, and to write task-scoped experiment artifacts on the server and local machine. That
authorization does not relax any protected-path, Git, deletion, credential, or stage boundary in
this document.

## 1. Objective

Complete **Stage 6: Paired Replay and Instrumentation** for the investigation:

> Why is CBDS usually much faster when both solvers reach a coarse target under high noise, while
> DS obtains higher late-stage coverage at the relevant coarse tolerances for some problem classes?

The replay must preserve the original solver decisions and add diagnostic traces that do not feed
back into either solver. The output must support later mechanism analysis without performing the
causal interventions or objective-function study assigned to Stages 7-10.

Stage 6 consists of:

1. accepting the already completed strict trace-equivalence gate;
2. running 20 paired DS/CBDS replays for each of 13 Tier 1 combinations;
3. analyzing relevant-tolerance classifications and the 70% stability rule;
4. extending only unstable Tier 1 combinations to 30 paired runs;
5. running and analyzing 5 Tier 2 combinations under the same rule;
6. rebuilding one complete, auditable manifest over all traces;
7. performing the final deterministic audit;
8. synchronizing outputs to the local repository;
9. updating the investigation plan, results, and checkpoint.

## 2. Hard Scope Boundary

### In scope

- Normal noisy-decision paired replay for baseline DS and baseline CBDS.
- Non-feedback oracle recording of the original true objective.
- Relevant-`tau` first-hitting behavior.
- Early/late trajectory windows around the Stage 3 CBDS plateau.
- Trace completeness, pairing, identity, budget, seed, and history audits.
- First-20 solved-set classification stability.
- Runs 21-30 only where required by the 70% rule.
- Descriptive Stage 6 conclusions supported by generated artifacts.

### Out of scope

- Stage 7 standalone mechanism study beyond the metrics already produced by the Stage 6 analyzer.
- Stage 8 objective-expression and structure analysis.
- Stage 9 oracle-acceptance or other causal interventions.
- Stage 10 rotated external validation.
- Solver redesign or tuning.
- Any change to BDS, DS, CBDS, acceptance tests, noise, seeds, budget, or tolerances.

Stop and report a blocker instead of crossing this boundary.

## 3. Workspaces and Connection

### Local machine

- Repository: `/Users/lihaitian/Work/bds`
- OptiProfiler: `/Users/lihaitian/local/optiprofiler`
- MATLAB executable normally available through `matlab` or the installed MATLAB application.

### Server

- SSH command: `ssh -p 53781 lhtian97@frp-pen.com`
- Repository: `/home/lhtian97/Work/bds`
- OptiProfiler: `/home/lhtian97/local/optiprofiler`
- Long jobs must run inside `screen`.

Do not read or print SSH keys, API keys, tokens, environment secrets, or credential files. Use the
already authenticated command directly.

## 4. Current Authoritative State

Stages 1-5 are complete. Stage 6 infrastructure and the strict equivalence gate are complete, but
the formal 20-run targeted replay dataset is not yet complete.

The strict equivalence gate has already passed over exactly:

```text
9 problems x 2 noise levels x 5 runs x 2 algorithms = 180 solver-runs
```

The verified counts are:

| Check | Passed | Total |
| --- | ---: | ---: |
| Formal solver exact equality | 180 | 180 |
| Internal trace reconstruction | 180 | 180 |
| Original Stage 3 trajectory exact equality | 180 | 180 |

Accept this gate as authoritative. **Do not rerun it.** Its artifacts are:

- `tests/testdata/ds_vs_cbds_high_noise_primary_20260712_165527/analysis/stage6_trace_equivalence/stage6_trace_equivalence_verification.md`
- `tests/testdata/ds_vs_cbds_high_noise_primary_20260712_165527/analysis/stage6_trace_equivalence/stage6_trace_equivalence_verification.csv`
- `tests/testdata/ds_vs_cbds_high_noise_primary_20260712_165527/analysis/stage6_trace_equivalence/stage6_trace_equivalence_verification.mat`

These files are read-only.

## 5. Authoritative Files

All relative paths below are relative to the BDS repository root.

| File | Purpose | Mutation rule |
| --- | --- | --- |
| `tests/competitors/ds_vs_cbds_high_noise_investigation_plan.md` | Full research protocol and stage definitions | Update Stage 6 status only after verified completion |
| `tests/competitors/ds_vs_cbds_high_noise_investigation_results.md` | Results from Stages 1-5 and Stage 6 handoff | Append evidence-backed Stage 6 findings only |
| `tests/stage6_inputs/stage6_targeted_replay_matrix.csv` | Version-controlled immutable snapshot of the authoritative 18-combination replay matrix | Read-only; never edit or replace |
| `tests/run_ds_vs_cbds_high_noise_replay.m` | Builds paired tasks, runs traces, writes manifest, and audits each invocation | Read-only during normal execution |
| `tests/analyze_ds_vs_cbds_high_noise_replay.m` | Computes relevant-`tau` hits, windows, stability, reports, and trace audit | Read-only during normal execution |
| `tests/competitors/trace_ds_cbds_baseline.m` | Validated instrumented baseline DS/CBDS implementation | Read-only; changing it invalidates the 180/180 gate |
| `tests/smoke_test_ds_vs_cbds_high_noise_replay.m` | Small temporary end-to-end workflow test | Execute once during preflight; do not edit |
| `tests/verify_trace_ds_cbds_baseline.m` | Equivalence verifier used by the completed gate | Read-only; do not execute for this task |
| `tests/run_stage6_trace_equivalence_gate.m` | Fixed 180-run gate driver | Read-only; do not execute for this task |
| `tests/competitors/private/set_accelerated_bds_options.m` | Normalizes the traced DS/CBDS options | Read-only; its hash must match locally and remotely |
| `tests/competitors/private/get_accelerated_bds_default_constant.m` | Supplies baseline defaults used by the option normalizer | Read-only; its hash must match locally and remotely |
| `tests/stage6_inputs/noise_matched_pair_summary.csv` | Version-controlled immutable snapshot of the Stage 3 plateau definitions used by analyzer | Read-only |
| `tests/testdata/ds_vs_cbds_high_noise_primary_20260712_165527/aggregate_manifest.mat` | Stage 3 aggregate identity and data | Read-only |
| This handoff file | Execution contract | Read-only |

If a core Stage 6 file appears defective, do not silently patch it and continue. Record the exact
failure in the checkpoint and stop for review. A change to the tracer would invalidate the accepted
equivalence gate.

The two files under `tests/stage6_inputs` are execution snapshots copied byte-for-byte from the
historical Stage 3/5 analysis artifacts under `tests/testdata`. The snapshots are the portable,
Git-tracked inputs for local and server execution; the historical originals remain provenance and
must not be moved, deleted, or modified.

## 6. Obsolete Files That Must Not Drive Execution

The following are remnants of an earlier read-only/advisory Kimi design:

- `tests/competitors/kimi_stage6_task.json`
- `tests/tools/kimi_stage6_actions.json`
- `tests/tools/execute_kimi_stage6_action.py`
- `tests/testdata/kimi_stage6_execution/`

Do not execute, edit, delete, or use them as workflow state. In particular, do not run the old
executor and do not try to clear its stale pending plan. Preserve it as historical audit material.

## 7. Fixed Scientific Configuration

These values are immutable:

| Setting | Required value |
| --- | --- |
| Problem library | S2MPJ |
| Problem type | Unconstrained |
| Problems | The 9 problems in the authoritative replay matrix |
| Noise levels | `sigma = 1e-1` and `sigma = 1e-2` |
| Budget | `MaxFunctionEvaluations = 200*n` |
| Step tolerance | `StepTolerance = 1e-6` |
| Algorithms | Baseline `ds` and baseline `cbds` |
| Acceleration switches | All off |
| Decision source | Normal noisy objective |
| Oracle true objective | Diagnostic only; no feedback and no budget charge |
| Initial runs | 20 paired runs per problem-sigma combination |
| Extension | Runs 21-30 only for unstable combinations |
| Paired seed | `seed = mod(211*run, 2^32)` |

The runner constructs baseline solver options as follows:

```matlab
options.Algorithm = algorithm;
options.use_productive_direction_memory = false;
options.use_sweep_pattern_direction = false;
options.use_momentum_extrapolation = false;
options.MaxFunctionEvaluations = 200 * n;
options.StepTolerance = 1e-6;
options.output_xhist = true;
options.output_alpha_hist = true;
options.output_block_hist = true;
```

Do not alter these options.

## 8. Relevant Tolerances

Only analyze tolerances at least as coarse as the noise level:

- For `sigma = 1e-1`, analyze only `tau = 1e-1`.
- For `sigma = 1e-2`, analyze `tau = 1e-1` and `tau = 1e-2`.

Do not use the mean over `tau = 1e-1,...,1e-10` to decide replay sufficiency or scientific
classification. The solver trajectory is run once for each `(problem, sigma, run)` and reused for
all relevant `tau` values.

## 9. Replay Matrix

The authoritative matrix has 18 unique `(problem, sigma)` rows.

### Tier 1: 13 combinations

| Order | Problem | n | Sigma | Relevant tau | Primary role |
| ---: | --- | ---: | ---: | --- | --- |
| 1 | `FMINSRF2` | 16 | `1e-1` | `1e-1` | late DS coverage |
| 1 | `FMINSRF2` | 16 | `1e-2` | `1e-1,1e-2` | late DS coverage |
| 2 | `FLETCHCR` | 10 | `1e-1` | `1e-1` | late DS with counterrun |
| 2 | `FLETCHCR` | 10 | `1e-2` | `1e-1,1e-2` | late DS with counterrun |
| 3 | `GENHUMPS` | 10 | `1e-1` | `1e-1` | early DS-only control |
| 4 | `COOLHANSLS` | 9 | `1e-1` | `1e-1` | CBDS early efficiency |
| 4 | `COOLHANSLS` | 9 | `1e-2` | `1e-1,1e-2` | CBDS early efficiency |
| 5 | `EXTROSNB` | 10 | `1e-2` | `1e-1,1e-2` | strict-target CBDS refinement |
| 6 | `DIXON3DQ` | 10 | `1e-2` | `1e-1,1e-2` | strict-target DS persistence |
| 7 | `HILBERTB` | 10 | `1e-1` | `1e-1` | noise-sensitive CBDS recovery |
| 7 | `HILBERTB` | 10 | `1e-2` | `1e-1,1e-2` | noise-sensitive CBDS recovery |
| 8 | `MSQRTALS` | 25 | `1e-2` | `1e-1,1e-2` | stable CBDS dense-LS counterexample |
| 9 | `SBRYBND` | 10 | `1e-2` | `1e-1,1e-2` | stable CBDS banded-LS counterexample |

### Tier 2: 5 combinations

| Order | Problem | n | Sigma | Relevant tau | Primary role |
| ---: | --- | ---: | --- | --- | --- |
| 3 | `GENHUMPS` | 10 | `1e-2` | `1e-1,1e-2` | early DS-only control |
| 5 | `EXTROSNB` | 10 | `1e-1` | `1e-1` | strict-target CBDS refinement |
| 6 | `DIXON3DQ` | 10 | `1e-1` | `1e-1` | strict-target DS persistence |
| 8 | `MSQRTALS` | 25 | `1e-1` | `1e-1` | stable CBDS dense-LS counterexample |
| 9 | `SBRYBND` | 10 | `1e-1` | `1e-1` | stable CBDS banded-LS counterexample |

## 10. Expected Counts

### First 20 runs

- Tier 1: `13 * 20 = 260` paired runs and `520` solver-runs/trace files.
- Tier 2: `5 * 20 = 100` paired runs and `200` solver-runs/trace files.
- Combined: `360` paired runs and `720` solver-runs/trace files.

There are 27 `(problem, sigma, tau)` analysis rows:

- 9 high-noise rows with one relevant tau;
- 9 lower-noise rows with two relevant taus.

With 20 runs everywhere, the final analyzer should produce:

- `540` relevant-tau hit rows;
- `1080` trajectory-window rows;
- `27` case-summary rows;
- `27` uncertainty rows;
- `720` trace-audit rows.

The phase-specific first-20 analyzer counts are:

| Phase | Case-summary rows | Hit rows | Window rows | Trace-audit rows |
| --- | ---: | ---: | ---: | ---: |
| Tier 1 | 21 | 420 | 840 | 520 |
| Tier 2 | 6 | 120 | 240 | 200 |
| Combined | 27 | 540 | 1080 | 720 |

### Extensions

If `U` problem-sigma combinations are extended from 20 to 30 runs:

- paired runs become `360 + 10*U`;
- solver-runs and trace files become `720 + 20*U`;
- trace-audit rows become `720 + 20*U`.

The hit-row increase depends on relevant tau count. Add 10 hit rows for an extended `sigma=1e-1`
combination and 20 hit rows for an extended `sigma=1e-2` combination. Trajectory-window rows are
always twice the hit-row count.

## 11. Stability Rule

For each `(problem, sigma, tau)` row in the first 20 paired runs, classify each run as:

- `both`;
- `ds_only`;
- `cbds_only`;
- `neither`.

Define:

```text
dominant_fraction = max(count_both, count_ds_only, count_cbds_only, count_neither) / 20
```

The row is unstable if and only if:

```text
dominant_fraction < 0.70
```

A `(problem, sigma)` combination is extended to runs 21-30 if **any** of its relevant tau rows is
unstable. A coverage confidence interval crossing zero is diagnostic and is not, by itself, an
extension trigger. Never extend a stable combination. Never exceed run 30.

Archive the first-20 uncertainty table before running extensions. The final 30-run analysis must
not erase the evidence that justified the extension.

## 12. Canonical Output Layout

Use one canonical replay root on the server so trace paths remain stable across phases:

```text
/home/lhtian97/Work/bds/tests/testdata/ds_vs_cbds_high_noise_stage6_replay_20260714
```

If that directory already exists, inspect it. Resume it only if its matrix, task identity, and
traces match this handoff. Do not delete or overwrite an unrelated or inconsistent directory. If
it is inconsistent, choose a new timestamped suffix and record the path in the checkpoint.

Inside the canonical root, maintain:

```text
traces/                              # canonical trace files used by all phases
orchestration/
  drivers/                           # MATLAB phase driver scripts
  logs/                              # screen logs and explicit exit-code files
  matrices/                          # derived read-only execution matrices
  snapshots/
    tier1_first20/
    tier1_final/
    tier2_first20/
    tier2_final/
    combined_final/
stage6_targeted_replay_matrix.csv    # current/final runner matrix
stage6_replay_tasks.csv
stage6_replay_index.csv
stage6_replay_manifest.mat
stage6_replay_run_report.md
stage6_trace_audit.csv
stage6_relevant_tau_hits.csv
stage6_plateau_window_metrics.csv
stage6_case_summary.csv
stage6_uncertainty_assessment.csv
stage6_replay_analysis.mat
stage6_replay_analysis.md
```

The corresponding local destination is:

```text
/Users/lihaitian/Work/bds/tests/testdata/ds_vs_cbds_high_noise_stage6_replay_20260714
```

Use the actual canonical basename if a timestamped suffix was required.

## 13. Important Runner Behavior

`run_ds_vs_cbds_high_noise_replay.m` writes one manifest for the tasks in its current invocation.
Calling it for a later phase overwrites root-level metadata such as:

- `stage6_targeted_replay_matrix.csv`;
- `stage6_replay_tasks.csv`;
- `stage6_replay_index.csv`;
- `stage6_replay_manifest.mat`;
- `stage6_replay_run_report.md`.

It does not delete canonical trace files. With `options.resume = true`, matching traces are safely
reused after identity validation.

`options.run_indices` has two distinct meanings that must not be confused:

- when it is nonempty, the same explicit run list is applied to every row in the supplied matrix,
  regardless of that row's `initial_runs` value;
- when it is empty, each matrix row produces runs `1:initial_runs`.

Consequently, an extension invocation using `21:30` must receive a matrix containing only the
unstable combinations. The final rebuild must receive all 18 rows with their final per-row
`initial_runs` values and must use `run_indices = []`.

Therefore:

1. use the same canonical root for all traces;
2. snapshot phase metadata and analysis files immediately after each successful phase;
3. create derived execution matrices without editing the authoritative matrix;
4. finish by invoking the runner once over the complete derived matrix with `run_indices = []`;
5. let that full-resume invocation rebuild the final combined manifest from all existing traces;
6. run the analyzer on the rebuilt combined manifest.

Do not concatenate MAT manifests manually. Do not assume a phase manifest contains earlier phases.

## 14. Checkpoint

Maintain this local checkpoint throughout the task:

```text
/Users/lihaitian/Work/bds/tests/testdata/ds_vs_cbds_high_noise_primary_20260712_165527/analysis/stage6_worker_checkpoint.md
```

Update it after every milestone:

1. local/remote preflight;
2. smoke test;
3. Tier 1 launch;
4. Tier 1 first-20 completion and audit;
5. Tier 1 stability decision;
6. Tier 1 extension completion, if any;
7. Tier 2 first-20 completion and audit;
8. Tier 2 stability decision;
9. Tier 2 extension completion, if any;
10. combined-manifest rebuild;
11. final audit;
12. synchronization and documentation update.

Use this structure:

```markdown
# Stage 6 Worker Checkpoint

- Updated: <ISO timestamp with timezone>
- Status: PREFLIGHT | TIER1_RUNNING | TIER1_ANALYZED | TIER2_RUNNING |
  FINAL_AUDIT | COMPLETE | BLOCKED
- Canonical remote root: <absolute path>
- Canonical local root: <absolute path>
- Active screen: <name or none>
- Current phase: <precise phase>

## Completed Actions

- <command/action, timestamp, exit status, artifact>

## Counts

- Matrix combinations: <done/expected>
- Paired runs: <done/expected>
- Solver runs/traces: <done/expected>
- Failed/abnormal runs: <count>

## Stability Decision

- First-20 artifact: <path>
- Unstable problem-sigma combinations: <exact list or none>
- Extension reason: <tau and dominant fraction for each>

## Verification

- Pairing audit: PASS/FAIL with counts
- Seed audit: PASS/FAIL
- Budget audit: PASS/FAIL
- Trace audit: PASS/FAIL
- Final-manifest audit: PASS/FAIL/PENDING

## Blockers or Open Issues

- <issue with exact evidence; write none if empty>

## Next Action

- <one concrete action>
```

Do not write vague updates such as "running normally". Include screen name, log path, completed
counts, and the next deterministic check.

## 15. Step-by-Step Execution

### Step 0: Read the authoritative context

From `/Users/lihaitian/Work/bds`, read at least:

```text
tests/competitors/ds_vs_cbds_high_noise_investigation_plan.md
tests/competitors/ds_vs_cbds_high_noise_investigation_results.md
tests/testdata/ds_vs_cbds_high_noise_primary_20260712_165527/analysis/
  noise_matched_problem_ranking/stage5_case_selection/
  stage5_representative_problem_shortlist.md
tests/stage6_inputs/stage6_targeted_replay_matrix.csv
tests/stage6_inputs/noise_matched_pair_summary.csv
tests/run_ds_vs_cbds_high_noise_replay.m
tests/analyze_ds_vs_cbds_high_noise_replay.m
tests/competitors/trace_ds_cbds_baseline.m
tests/smoke_test_ds_vs_cbds_high_noise_replay.m
```

Confirm that your understanding matches Sections 1-11 of this handoff before executing anything.

### Step 1: Local preflight

Record, without modifying Git state:

```bash
cd /Users/lihaitian/Work/bds
git rev-parse HEAD
git status --short
```

The worktree may be dirty. Do not clean, reset, checkout, stash, commit, push, or pull. Preserve all
existing changes.

Verify that the authoritative matrix has:

- 18 rows;
- 13 Tier 1 rows;
- 5 Tier 2 rows;
- 9 unique problems;
- 9 rows at each sigma;
- no duplicate `(problem, sigma)` keys;
- `initial_runs = 20`;
- `max_eval_factor = 200`;
- `step_tolerance = 1e-6`;
- `algorithms = ds,cbds`;
- `decision_source = noisy`;
- `oracle_intervention_deferred = 1`.

Verify the equivalence CSV has 180 rows and all three exact columns equal 1. Do not regenerate it.

Also confirm that every local path in Section 5 exists. The checkpoint file is the one intentional
exception: create it from the template in Section 14 if it does not exist.

### Step 2: Server preflight

Use:

```bash
ssh -p 53781 lhtian97@frp-pen.com
```

On the server, inspect without changing files:

```bash
cd /home/lhtian97/Work/bds
date
git rev-parse HEAD
git status --short
command -v matlab
command -v screen
screen -ls
nproc
free -h
df -h /home/lhtian97
```

Confirm existence of:

```text
/home/lhtian97/local/optiprofiler/matlab/optiprofiler/src/benchmark.m
/home/lhtian97/local/optiprofiler/matlab/optiprofiler/problem_libs/s2mpj/s2mpj_load.m
/home/lhtian97/Work/bds/tests/run_ds_vs_cbds_high_noise_replay.m
/home/lhtian97/Work/bds/tests/analyze_ds_vs_cbds_high_noise_replay.m
/home/lhtian97/Work/bds/tests/competitors/trace_ds_cbds_baseline.m
```

Compare SHA-256 hashes between local and remote copies of:

```text
tests/run_ds_vs_cbds_high_noise_replay.m
tests/analyze_ds_vs_cbds_high_noise_replay.m
tests/competitors/trace_ds_cbds_baseline.m
tests/competitors/private/set_accelerated_bds_options.m
tests/competitors/private/get_accelerated_bds_default_constant.m
tests/stage6_inputs/stage6_targeted_replay_matrix.csv
tests/stage6_inputs/noise_matched_pair_summary.csv
```

Also compare the BDS repository commit and the OptiProfiler repository commit when available.

Because `trace_ds_cbds_baseline.m` resolves helper functions through
`tests/competitors/private`, verify that the symlink targets used by the tracer exist remotely.
At minimum this includes `cycling.m`, `divide_direction_set.m`, `eval_fun.m`,
`get_direction_set.m`, and `get_exitflag.m`. The local and remote BDS commit comparison does not
replace hashing the two untracked/task-specific option files listed above.

If a critical file exists on both machines but hashes differ, stop and record `BLOCKED`. Do not
overwrite either copy and do not run `git pull`. If a task-specific file is missing remotely, report
the missing path before copying it; never overwrite a mismatched existing file.

Ensure no unrelated heavy experiment would make a new MATLAB pool unsafe. Do not terminate or
modify unrelated user processes.

### Step 3: Workflow smoke test

Run the existing smoke test on the execution machine before the long job:

```matlab
cd('/home/lhtian97/Work/bds');
addpath(fullfile(pwd, 'tests'));
smoke_test_ds_vs_cbds_high_noise_replay;
```

For a noninteractive server invocation, use the equivalent command from the repository root:

```bash
matlab -batch "addpath(fullfile(pwd,'tests')); smoke_test_ds_vs_cbds_high_noise_replay"
```

The expected terminal marker is:

```text
PASS Stage 6 replay smoke test.
```

The smoke test must confirm one paired run, analysis output, complete trace audit, and resume/reuse.
It uses a temporary directory and is not part of the formal dataset.

Do not run `run_stage6_trace_equivalence_gate`.

### Step 4: Create canonical orchestration directories

Create the canonical root and only its new orchestration subdirectories. Do not remove existing
files:

```text
orchestration/drivers
orchestration/logs
orchestration/matrices
orchestration/snapshots/tier1_first20
orchestration/snapshots/tier1_final
orchestration/snapshots/tier2_first20
orchestration/snapshots/tier2_final
orchestration/snapshots/combined_final
```

Copy the authoritative matrix into `orchestration/matrices/source_matrix.csv` and record its
SHA-256 hash. This is a snapshot, not a replacement for the authoritative file.

Before creating anything, record whether the canonical root already exists. If it does, compare
its existing `source_matrix.csv` hash, inspect every existing trace identity, and check for an
active Stage 6 controller. Resume only after all three checks agree. The mere presence of a
similarly named directory is not permission to reuse it.

### Step 5: Choose safe parallelism

Start with `options.n_jobs = 15` only if memory and current server load support it. The explicit
seed makes task results independent of scheduling order. If 15 MATLAB workers would create memory
pressure, choose a lower value and record the reason in the checkpoint.

Do not increase concurrency after launch without evidence. Do not run multiple Stage 6 MATLAB
controllers against the same trace root concurrently.

### Step 6: Run Tier 1, runs 1-20

Create a MATLAB driver under `orchestration/drivers`, for example
`tier1_first20.m`, with the following logical content:

```matlab
repo = '/home/lhtian97/Work/bds';
matrix_file = fullfile(repo, 'tests', 'stage6_inputs', ...
    'stage6_targeted_replay_matrix.csv');
savepath = fullfile(repo, 'tests', 'testdata', ...
    'ds_vs_cbds_high_noise_stage6_replay_20260714');
cd(repo);
addpath(fullfile(repo, 'tests'));
options.run_indices = 1:20;
options.priority_tiers = 1;
options.n_jobs = 15; % Lower only if preflight requires it.
options.resume = true;
options.savepath = savepath;
manifest = run_ds_vs_cbds_high_noise_replay(matrix_file, options);
analyze_ds_vs_cbds_high_noise_replay(manifest);
```

Launch it in a detached screen with an explicit log and exit-code file. Use a descriptive name such
as `bds_stage6_tier1_20`. A robust shell wrapper should:

1. `cd` to the remote BDS repository;
2. run `matlab -batch "run('<absolute-driver-path>')"`;
3. redirect stdout and stderr to `orchestration/logs/tier1_first20.log`;
4. write the shell exit code to `orchestration/logs/tier1_first20.exit`.

Record the exact screen name, command, PID if visible, log, and start time in the checkpoint.

Use this launch pattern, substituting only the phase name and canonical root. Keeping the exit-code
write in the same shell makes a disappeared screen auditable:

```bash
screen -dmS bds_stage6_tier1_20 bash -lc \
  'cd /home/lhtian97/Work/bds; matlab -batch "run('"'"'/absolute/path/tier1_first20.m'"'"')" > /absolute/canonical/root/orchestration/logs/tier1_first20.log 2>&1; status=$?; printf "%s\n" "$status" > /absolute/canonical/root/orchestration/logs/tier1_first20.exit; exit "$status"'
```

After launch, confirm exactly one matching screen/controller exists and that the log has advanced
past MATLAB startup. Do not start another controller if the log is temporarily quiet.

Monitor with:

```bash
screen -ls
tail -n 80 <tier1-log>
find <canonical-root>/traces -type f -name '*.mat' | wc -l
free -h
```

Do not infer success merely because the screen disappeared. Success requires:

- exit-code file equals 0;
- manifest exists;
- exactly 520 successful solver rows;
- exactly 260 paired keys, each with DS and CBDS;
- 520 trace files;
- analyzer completes without assertion failure;
- trace audit has 520 passing rows.

The Tier 1 analyzer must additionally contain exactly 21 case-summary/uncertainty rows, 420 hit
rows, and 840 trajectory-window rows.

Snapshot the phase metadata and analysis files into `snapshots/tier1_first20` immediately.

A phase snapshot must contain copies of all root-level `stage6_*` files produced by that invocation,
the phase driver, phase log, exit-code file, the exact input matrix, and a SHA-256 inventory. Do not
move files out of the canonical root, and do not include or duplicate the trace tree in a snapshot.

### Step 7: Apply the Tier 1 stability rule

Read the archived first-20 `stage6_uncertainty_assessment.csv`.

For each `(problem, sigma)`, extend it if any relevant tau row has
`increase_to_30 == 1`. Record for each selected combination:

- problem;
- sigma;
- triggering tau;
- dominant classification fraction;
- first-20 counts for `both/ds_only/cbds_only/neither`.

Create two derived matrices under `orchestration/matrices`:

1. `tier1_extension_matrix.csv`: only unstable Tier 1 problem-sigma rows, unchanged except that it
   will be invoked with explicit runs 21-30;
2. `tier1_execution_matrix.csv`: every Tier 1 row, with `initial_runs = 30` only for unstable rows
   and `initial_runs = 20` for stable rows.

All columns other than `initial_runs` must match the authoritative source exactly. Assert:

- no stable row is changed to 30;
- every unstable problem-sigma row is changed to 30;
- all values are either 20 or 30;
- no row is added, removed, or duplicated.

Generate these matrices with a reproducible script under `orchestration/drivers`; do not edit CSV
cells by hand. Match a stability decision to the source by the composite key `(problem, sigma)`,
not by row number or floating-point display text. Save the script and a decision CSV containing the
source key, every triggering `tau`, first-20 counts, dominant fraction, and boolean extension
decision.

If no Tier 1 combination is unstable, create an empty decision record, skip runs 21-30, and make
`tier1_execution_matrix.csv` equal to the 13 source Tier 1 rows.

### Step 8: Run Tier 1 extensions, if required

If `tier1_extension_matrix.csv` is nonempty, call the runner with:

```matlab
options.run_indices = 21:30;
options.priority_tiers = 1;
options.resume = true;
options.savepath = <same canonical root>;
```

Use a separate screen, log, driver, and exit-code file. Do not run stable combinations.

Whether or not an extension was required, rebuild the complete Tier 1 manifest by calling the
runner on `tier1_execution_matrix.csv` with:

```matlab
options.run_indices = [];
options.priority_tiers = 1;
options.resume = true;
options.savepath = <same canonical root>;
```

This call should validate and reuse all existing Tier 1 traces. Run the analyzer on the rebuilt
manifest, then snapshot metadata and analysis to `snapshots/tier1_final`. If there was no extension,
the final Tier 1 counts equal the first-20 counts, but this rebuild and final snapshot are still
mandatory.

### Step 9: Run Tier 2, runs 1-20

Repeat the formal process for the 5 Tier 2 source rows:

```matlab
options.run_indices = 1:20;
options.priority_tiers = 2;
options.resume = true;
options.savepath = <same canonical root>;
```

Use a new screen such as `bds_stage6_tier2_20`, a separate driver, log, and exit-code file.

Tier 2 first-20 success requires:

- exactly 200 successful solver rows;
- exactly 100 paired keys;
- 200 Tier 2 traces in the invocation;
- complete analyzer and trace audit;
- no pairing, budget, identity, or history failure.

The Tier 2 analyzer must additionally contain exactly 6 case-summary/uncertainty rows, 120 hit rows,
and 240 trajectory-window rows.

Snapshot phase metadata and analysis into `snapshots/tier2_first20`.

### Step 10: Apply the Tier 2 stability rule and extend if required

Use the same first-20 `< 0.70` rule. Build:

- `tier2_extension_matrix.csv`;
- `tier2_execution_matrix.csv`.

Run only unstable combinations for runs 21-30. Whether or not any extension is required, rebuild
the complete Tier 2 manifest from `tier2_execution_matrix.csv` using `run_indices = []`, analyze it,
and snapshot to `snapshots/tier2_final`.

Do not extend a combination merely because a confidence interval crosses zero. Never run 31 or
higher.

### Step 11: Build the combined final execution matrix

Create `orchestration/matrices/final_execution_matrix.csv` from all 18 authoritative rows.

- Set `initial_runs = 30` for the union of Tier 1 and Tier 2 unstable problem-sigma combinations.
- Keep `initial_runs = 20` for every other row.
- Preserve every other field exactly.

Audit this derived matrix against the source before using it. Save a machine-readable extension
decision table with problem, sigma, triggering tau, dominant fraction, and source snapshot path.
The final matrix must be generated from the original 18-row source matrix, not by concatenating the
root-level runner matrix left behind by the latest phase.

### Step 12: Rebuild the final combined manifest

Call the runner once with:

```matlab
matrix_file = <final_execution_matrix.csv>;
options.run_indices = [];
options.priority_tiers = [1, 2];
options.resume = true;
options.savepath = <same canonical root>;
```

Every completed trace should be reused after identity validation. This invocation rebuilds the
single authoritative Stage 6 manifest over all Tier 1 and Tier 2 traces.

Run:

```matlab
analysis_file = analyze_ds_vs_cbds_high_noise_replay(manifest_file);
```

Snapshot final metadata and analysis into `snapshots/combined_final` without moving or deleting the
canonical root files.

During this full-resume rebuild, the runner should report every task as reused. Any newly executed
task means that a required phase trace was absent; investigate and document it before accepting the
combined manifest.

## 16. Final Deterministic Audit

The final audit must be executable and machine-readable. A small new audit helper may be created
under the canonical root's `orchestration` directory; do not modify core solver or tracer code.

At minimum assert all of the following.

### Matrix audit

- 18 unique `(problem, sigma)` rows.
- 13 Tier 1 and 5 Tier 2 rows.
- 9 unique problems.
- All fields except `initial_runs` equal the authoritative matrix.
- `initial_runs` is 20 or 30 only.
- The set of 30-run combinations exactly matches first-20 instability evidence.

### Run-index audit

- Expected paired runs equal `sum(final_matrix.initial_runs)`.
- Expected solver runs equal twice the paired runs.
- Every solver row has `success = true`.
- No `error_identifier` or `error_message` remains.
- Every `(problem, sigma, run, seed)` key has exactly two rows.
- Those two rows contain exactly one `ds` and one `cbds`.
- Both rows have the same paired seed.
- `seed = mod(211*run, 2^32)`.
- `maxfun = 200*n`.
- `step_tolerance = 1e-6`.
- `decision_source = noisy`.
- `func_count <= maxfun`.
- Exit flags and termination messages are defined.

### Trace-file audit

- Exactly one trace file exists for every solver row.
- No expected trace file is missing.
- The set of `.mat` files under `traces/` equals the manifest trace-path set exactly; no extra or
  orphan trace is present.
- Trace identity matches manifest identity.
- Complete history is true for every row.
- Evaluation order is exact.
- Point, noisy-value, true-value, and block histories match.
- Budget, seed, and termination audits pass.
- Any invalid evaluation is investigated and reported; do not hide it.

### Analysis audit

- `stage6_trace_audit.csv` row count equals solver-run count.
- All logical audit fields are true.
- `stage6_case_summary.csv` and `stage6_uncertainty_assessment.csv` each contain 27 rows.
- Every analyzed `tau >= sigma`.
- Hit-row count equals the sum of `initial_runs * number_of_relevant_taus` over the final matrix.
- Trajectory-window row count is exactly twice the hit-row count.
- No ten-tolerance average is used for the extension decision.
- First-20 instability snapshots remain available after final analysis.

Write a concise final-audit Markdown file and a CSV/JSON summary under the canonical root.
The audit must exit nonzero on the first failed invariant and must also write the expected and
observed counts, source/final matrix hashes, extension key set, manifest hash, analysis hash, and
trace-path-set result. A prose-only inspection is not sufficient.

## 17. Scientific Reporting Boundary

The Stage 6 report should answer, with trace evidence:

- which representative cases preserve the Stage 3 solved-set classification over 20 or 30 runs;
- when CBDS reaches the relevant target earlier among both-solved runs;
- which DS-only hits occur after the Stage 3 CBDS plateau;
- whether true progress continues after that plateau;
- what the step-size states and accepted/base-change counts look like around the plateau;
- whether false decisions or post-best budget fractions differ descriptively;
- which cases contradict a simple universal explanation.

Do not claim a function-structure causal mechanism in Stage 6. Do not perform Stage 8 objective
analysis. Use language such as "the trace evidence is consistent with" unless a deterministic
identity or directly measured event establishes the claim.

## 18. Synchronize Results to Local

After the remote final audit passes:

1. measure remote output size with `du -sh`;
2. verify local free disk space;
3. synchronize with a resumable transfer such as `rsync --partial` over SSH port 53781;
4. do not delete either remote or local data;
5. compare final manifest/report hashes after transfer;
6. verify local trace count and final audit again.

For rsync, the SSH transport must use:

```text
ssh -p 53781
```

The intended direction and trailing-slash semantics are:

```bash
rsync -a --partial -e 'ssh -p 53781' \
  lhtian97@frp-pen.com:/home/lhtian97/Work/bds/tests/testdata/<canonical-basename>/ \
  /Users/lihaitian/Work/bds/tests/testdata/<canonical-basename>/
```

Run without `--delete`. If interrupted, rerun the same command. Do not copy a directory into an
already nested directory of the same name.

If full trace synchronization cannot fit locally, mark the task `BLOCKED` before claiming complete.
At minimum synchronize metadata and reports for review, but do not call Stage 6 complete until the
agreed final artifact boundary is explicit.

## 19. Update the Investigation Documents

Only after final audit and synchronization:

### Plan

Update:

```text
tests/competitors/ds_vs_cbds_high_noise_investigation_plan.md
```

- Mark Stage 6 `Completed` only if every acceptance criterion passes.
- Record the canonical local output path.
- Record first-20 and extension counts.
- Record unresolved uncertainty without changing Stage 7-10 status.

### Results

Update:

```text
tests/competitors/ds_vs_cbds_high_noise_investigation_results.md
```

Add a Stage 6 section with:

- exact run counts and audit counts;
- unstable combinations and extensions;
- relevant-`tau` classification stability;
- first-hitting and plateau-window findings;
- descriptive trace evidence;
- counterexamples and limitations;
- exact artifact paths;
- a clear statement that oracle intervention and objective-function causality remain deferred.

Use Chinese for descriptive explanation and English for key technical terms and core claims, in the
style already used by the file.

Do not rewrite or remove prior-stage findings.

## 20. Failure Handling

### A phase fails

- Preserve all completed traces and logs.
- Record the exact MATLAB exception, phase, task identity, and exit code.
- Do not delete the root or restart from scratch.
- Diagnose whether the failure is deterministic, environment-related, or resource-related.
- Resume only with `options.resume = true` after the cause is understood.

### A trace identity mismatch occurs

- Stop immediately.
- Do not overwrite the trace.
- Record expected and actual identity fields.
- Treat it as evidence that the canonical root is inconsistent.

### Resource pressure occurs

- Do not kill unrelated processes.
- Preserve checkpoint and logs.
- Gracefully stop the task-scoped controller if necessary.
- Reduce `n_jobs` for the resumed invocation and document the change.
- Seeds and results must remain identical because task identities are explicit.

### SSH disconnects

- The experiment must continue in `screen`.
- Reconnect and inspect screen, log, exit-code file, and trace count.
- Do not launch a duplicate controller against the same root.

### Screen disappears

- Check the explicit exit-code file and log.
- A missing screen is not proof of completion.

### Core code mismatch or suspected bug

- Stop and mark `BLOCKED`.
- Do not edit tracer, solver, authoritative matrix, or equivalence artifacts.
- Report exact hashes and evidence for Codex review.

## 21. Prohibited Operations

Never perform any of the following:

- `git commit`, `git push`, `git pull`, `git reset`, `git rebase`, `git checkout`, `git clean`, or
  `git stash`;
- deletion or truncation of existing experiment data;
- overwrite of a mismatched remote file;
- modification of anything under `src/`;
- modification of `tests/competitors/accelerated_bds_options.m`;
- modification of `tests/competitors/trace_ds_cbds_baseline.m`;
- modification of the authoritative replay matrix;
- modification or regeneration of the 180/180 equivalence artifact;
- oracle-acceptance intervention;
- changes to seeds, noise, tau, budget, step tolerance, solver definitions, or shortlist;
- execution of Stage 7-10;
- use of the obsolete schema-v2 Kimi executor;
- exposure of credentials or environment secrets.

## 22. Completion Criteria

Stage 6 is complete only when all statements below are true:

1. The accepted 180/180 equivalence gate is cited and unchanged.
2. All 18 matrix combinations have at least 20 complete paired runs.
3. Only first-20 unstable combinations have runs 21-30.
4. One combined final manifest covers every expected DS and CBDS trace.
5. Pairing, seed, budget, identity, history, trace, and termination audits pass.
6. All expected Stage 6 CSV, MAT, and Markdown artifacts exist.
7. First-20 stability evidence is preserved.
8. Final outputs are synchronized locally and hash/count checked.
9. The checkpoint says `COMPLETE` with exact evidence.
10. The investigation plan and results accurately record Stage 6.
11. No protected file or out-of-scope stage was modified.

If any item is false, report `BLOCKED` or the precise incomplete status. Do not claim completion.

## 23. Final Response Contract

Your final response must contain:

- status: `COMPLETED` or `BLOCKED`;
- canonical remote and local output paths;
- screen sessions and phase exit codes;
- total combinations, paired runs, solver runs, and trace files;
- Tier 1 and Tier 2 first-20 counts;
- exact extended combinations and reasons;
- final audit pass/fail counts;
- key generated artifacts;
- files modified outside `tests/testdata`;
- concise Stage 6 findings and limitations;
- any unresolved issue;
- confirmation that Git mutation, protected-file modification, oracle intervention, and Stages 7-10
  were not performed.

Do not substitute a narrative assurance for these auditable facts.
