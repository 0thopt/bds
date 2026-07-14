function selection_file = select_ds_vs_cbds_high_noise_cases(ranking_file)
%SELECT_DS_VS_CBDS_HIGH_NOISE_CASES fixes the Stage 5 replay shortlist.

if nargin < 1 || isempty(ranking_file)
    path_tests = fileparts(mfilename('fullpath'));
    listing = dir(fullfile(path_tests, 'testdata', ...
        'ds_vs_cbds_high_noise_primary_*', 'analysis', ...
        'noise_matched_problem_ranking', ...
        'noise_matched_problem_ranking_analysis.mat'));
    if isempty(listing)
        error('No Stage 4 problem-ranking analysis was found.');
    end
    [~, index] = max([listing.datenum]);
    ranking_file = fullfile(listing(index).folder, listing(index).name);
end

loaded = load(ranking_file, 'analysis');
stage4 = loaded.analysis;
output_dir = fullfile(fileparts(ranking_file), 'stage5_case_selection');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

ensure_s2mpj_paths();
definitions = case_definitions();
shortlist = make_shortlist(definitions, stage4.problem_ranking);
trajectory = make_trajectory_screening( ...
    stage4.manifest_file, shortlist.problem);
evidence = innerjoin(stage4.problem_ranking( ...
    ismember(stage4.problem_ranking.problem, shortlist.problem), :), ...
    trajectory, 'Keys', {'feature', 'sigma', 'tau', 'problem', 'n'});
evidence = sort_evidence(evidence, shortlist.problem);
replay_matrix = make_replay_matrix(shortlist);
validate_selection(shortlist, evidence, replay_matrix);

writetable(shortlist, fullfile(output_dir, ...
    'stage5_representative_problem_shortlist.csv'));
writetable(evidence, fullfile(output_dir, ...
    'stage5_case_evidence_matrix.csv'));
writetable(replay_matrix, fullfile(output_dir, ...
    'stage6_targeted_replay_matrix.csv'));

selection = struct();
selection.created = char(datetime('now'));
selection.ranking_file = ranking_file;
selection.manifest_file = stage4.manifest_file;
selection.shortlist = shortlist;
selection.evidence = evidence;
selection.replay_matrix = replay_matrix;
selection_file = fullfile(output_dir, 'stage5_case_selection.mat');
save(selection_file, 'selection', '-v7.3');
write_report(selection, fullfile(output_dir, ...
    'stage5_representative_problem_shortlist.md'));

fprintf('Stage 5 case selection: %s\n', selection_file);

end

function definitions = case_definitions()

definitions = struct( ...
    'problem', { ...
        'FMINSRF2', 'FLETCHCR', 'GENHUMPS', 'COOLHANSLS', ...
        'EXTROSNB', 'DIXON3DQ', 'HILBERTB', 'MSQRTALS', 'SBRYBND'}, ...
    'n', {16, 10, 10, 9, 10, 10, 10, 25, 10}, ...
    'pbclass', { ...
        'C-COUR2-MY-V-0', 'C-COUR2-AN-V-0', 'C-COUR2-AN-V-0', ...
        'C-CSUR2-RN-9-0', 'C-CSUR2-AN-V-0', 'C-CQUR2-AN-V-0', ...
        'C-CQUR2-AN-V-0', 'C-CSUR2-AN-V-V', 'C-CSUR2-AN-V-0'}, ...
    'primary_role', { ...
        'late_ds_coverage', ...
        'late_ds_with_counterrun', ...
        'early_ds_only_control', ...
        'cbds_early_efficiency', ...
        'strict_target_cbds_refinement', ...
        'strict_target_ds_persistence', ...
        'noise_sensitive_cbds_recovery', ...
        'stable_cbds_dense_ls_counterexample', ...
        'stable_cbds_banded_ls_counterexample'}, ...
    'structure', { ...
        'free-boundary minimum-surface discretization', ...
        'chained Rosenbrock objective', ...
        'nonconvex nearest-neighbor oscillatory humps', ...
        'dense 3-by-3 quadratic matrix-equation least squares', ...
        'nonseparable extended Rosenbrock residual objective', ...
        'convex tridiagonal quadratic', ...
        'perturbed dense Hilbert quadratic', ...
        'dense matrix-square-root least squares', ...
        'scaled banded Broyden nonlinear least squares'}, ...
    'selection_reason', { ...
        ['High-noise DS hits late after CBDS leads early; at sigma=1e-2 ', ...
         'CBDS wins the coarse target but DS alone reaches the strict target.'], ...
        ['Four of five runs are late DS-only at every primary pair, while one ', ...
         'run is CBDS-only; this preserves a within-problem stochastic counterrun.'], ...
        ['Five of five runs are DS-only at every primary pair, but DS hits ', ...
         'early; this prevents equating every DS-only case with late persistence.'], ...
        ['Both solvers solve every primary run and CBDS is faster in all of ', ...
         'them, with median time ratios from 53.9 to 129.2.'], ...
        ['At sigma=1e-2 the coarse target is reached by both with CBDS 23.8 ', ...
         'times faster, while the strict target is CBDS-only in all five runs.'], ...
        ['At sigma=1e-2 CBDS is faster at the coarse target, but the strict ', ...
         'target is DS-only in all five runs; this is the opposite transition.'], ...
        ['High noise gives four DS-only runs, whereas lower noise gives five ', ...
         'both-solved runs with CBDS 13.8--49.3 times faster.'], ...
        ['CBDS-only in all five runs at every primary pair; a dense ', ...
         'least-squares counterexample to generic DS noise robustness.'], ...
        ['CBDS-only in all five runs at every primary pair; a sparse banded ', ...
         'least-squares contrast to the dense matrix-square-root case.']});

end

function shortlist = make_shortlist(definitions, ranking)

n_cases = numel(definitions);
rows = cell(n_cases, 26);
for i_case = 1:n_cases
    definition = definitions(i_case);
    selected = ranking.problem == string(definition.problem);
    problem_rows = ranking(selected, :);
    assert(height(problem_rows) == 3, ...
        'Expected three primary-pair rows for %s.', definition.problem);
    assert(all(problem_rows.n == definition.n), ...
        'Unexpected dimension for %s.', definition.problem);

    problem = s2mpj_load(definition.problem);
    pb = feval(definition.problem, 'setup');
    source_file = which(definition.problem);
    python_source = fullfile(char(java.lang.System.getProperty('user.home')), ...
        'local', 'optiprofiler', 'python', 'optiprofiler', 'problem_libs', ...
        's2mpj', 'src', 'python_problems', [definition.problem, '.py']);
    assert(problem.n == definition.n && pb.n == definition.n && pb.m == 0, ...
        'The loaded S2MPJ instance for %s is not the selected unconstrained instance.', ...
        definition.problem);
    assert(strcmp(pb.pbclass, definition.pbclass), ...
        'Unexpected S2MPJ classification for %s.', definition.problem);
    assert(isfile(source_file) && isfile(python_source), ...
        'An authoritative S2MPJ source file is missing for %s.', definition.problem);

    high = select_pair(problem_rows, 'noisy_1e-1', 1e-1);
    low_coarse = select_pair(problem_rows, 'noisy_1e-2', 1e-1);
    low_strict = select_pair(problem_rows, 'noisy_1e-2', 1e-2);
    rows(i_case, :) = {i_case, string(definition.problem), definition.n, ...
        string(definition.primary_role), string(definition.structure), ...
        string(definition.selection_reason), string(definition.pbclass), ...
        problem.fun(problem.x0), string(source_file), string(python_source), ...
        high.both, high.ds_only, high.cbds_only, high.neither, ...
        low_coarse.both, low_coarse.ds_only, ...
        low_coarse.cbds_only, low_coarse.neither, ...
        low_strict.both, low_strict.ds_only, ...
        low_strict.cbds_only, low_strict.neither, ...
        high.median_best_true_advantage_ds, ...
        low_coarse.median_best_true_advantage_ds, ...
        low_strict.median_best_true_advantage_ds, true};
end

shortlist = cell2table(rows, 'VariableNames', { ...
    'selection_order', 'problem', 'n', 'primary_role', 'structure', ...
    'selection_reason', 's2mpj_classification', 'f_init', ...
    'matlab_source_file', 'python_source_file', ...
    'sigma_1e_1_tau_1e_1_both', 'sigma_1e_1_tau_1e_1_ds_only', ...
    'sigma_1e_1_tau_1e_1_cbds_only', 'sigma_1e_1_tau_1e_1_neither', ...
    'sigma_1e_2_tau_1e_1_both', 'sigma_1e_2_tau_1e_1_ds_only', ...
    'sigma_1e_2_tau_1e_1_cbds_only', 'sigma_1e_2_tau_1e_1_neither', ...
    'sigma_1e_2_tau_1e_2_both', 'sigma_1e_2_tau_1e_2_ds_only', ...
    'sigma_1e_2_tau_1e_2_cbds_only', 'sigma_1e_2_tau_1e_2_neither', ...
    'sigma_1e_1_tau_1e_1_median_true_advantage_ds', ...
    'sigma_1e_2_tau_1e_1_median_true_advantage_ds', ...
    'sigma_1e_2_tau_1e_2_median_true_advantage_ds', ...
    'authoritative_definition_available'});

end

function row = select_pair(table_rows, feature, tau)

selected = table_rows.feature == string(feature) ...
    & abs(table_rows.tau - tau) < 10 * eps;
assert(sum(selected) == 1, 'Expected one row for %s at tau %.0e.', feature, tau);
row = table_rows(selected, :);

end

function trajectory = make_trajectory_screening(manifest_file, problem_names)

loaded = load(manifest_file, 'manifest');
manifest = loaded.manifest;
specs = struct( ...
    'feature', {'noisy_1e-1', 'noisy_1e-2', 'noisy_1e-2'}, ...
    'sigma', {1e-1, 1e-2, 1e-2}, ...
    'tau', {1e-1, 1e-1, 1e-2});
early_budget_beta = 24;
rows = cell(numel(specs) * numel(problem_names), 18);
row = 0;

for i_spec = 1:numel(specs)
    spec = specs(i_spec);
    entry = manifest.features(find(strcmp({manifest.features.name}, ...
        spec.feature), 1));
    loaded_results = load(entry.data_file, 'results_plibs');
    results = loaded_results.results_plibs{1};
    for i_problem = 1:numel(problem_names)
        problem_name = problem_names(i_problem);
        i_result = find(strcmp(results.problem_names, problem_name), 1);
        assert(~isempty(i_result), 'Problem %s is missing.', problem_name);
        n = results.problem_dims(i_result);
        n_runs = size(results.fun_histories, 3);
        ds_hit_beta = NaN(n_runs, 1);
        cbds_hit_beta = NaN(n_runs, 1);
        ds_only_hit_beta = NaN(n_runs, 1);
        cbds_progress_early = NaN(n_runs, 1);
        ds_progress_early = NaN(n_runs, 1);
        ds_progress_final = NaN(n_runs, 1);
        cbds_progress_final = NaN(n_runs, 1);
        ds_plateau_beta = NaN(n_runs, 1);
        cbds_plateau_beta = NaN(n_runs, 1);
        classification = strings(n_runs, 1);

        for i_run = 1:n_runs
            f_init = results.fun_inits(i_result, i_run);
            ds_history = result_history(results, i_result, 1, i_run);
            cbds_history = result_history(results, i_result, 2, i_run);
            reference_min = min([f_init; ds_history; cbds_history], [], 'omitnan');
            threshold = max(spec.tau * f_init + ...
                (1 - spec.tau) * reference_min, reference_min);
            ds_work = find_first_or_nan(ds_history <= threshold);
            cbds_work = find_first_or_nan(cbds_history <= threshold);
            classification(i_run) = classify_solved(ds_work, cbds_work);
            ds_hit_beta(i_run) = ds_work / (n + 1);
            cbds_hit_beta(i_run) = cbds_work / (n + 1);
            if classification(i_run) == "ds_only"
                ds_only_hit_beta(i_run) = ds_hit_beta(i_run);
            end

            scale = max(eps, abs(f_init - reference_min));
            ds_progress = normalized_progress(ds_history, f_init, scale);
            cbds_progress = normalized_progress(cbds_history, f_init, scale);
            early_evaluations = max(1, floor(early_budget_beta * (n + 1)));
            ds_progress_early(i_run) = ds_progress( ...
                min(early_evaluations, numel(ds_progress)));
            cbds_progress_early(i_run) = cbds_progress( ...
                min(early_evaluations, numel(cbds_progress)));
            ds_progress_final(i_run) = ds_progress(end);
            cbds_progress_final(i_run) = cbds_progress(end);
            ds_plateau_beta(i_run) = within_one_percent_beta(ds_progress, n);
            cbds_plateau_beta(i_run) = within_one_percent_beta(cbds_progress, n);
        end

        ds_only = classification == "ds_only";
        row = row + 1;
        rows(row, :) = {string(spec.feature), spec.sigma, spec.tau, ...
            problem_name, n, early_budget_beta, ...
            median(ds_hit_beta, 'omitnan'), median(cbds_hit_beta, 'omitnan'), ...
            median(ds_only_hit_beta, 'omitnan'), ...
            median(ds_progress_early, 'omitnan'), ...
            median(cbds_progress_early, 'omitnan'), ...
            median(cbds_progress_early - ds_progress_early, 'omitnan'), ...
            median(ds_progress_final - ds_progress_early, 'omitnan'), ...
            median(cbds_progress_final - cbds_progress_early, 'omitnan'), ...
            median(ds_plateau_beta, 'omitnan'), ...
            median(cbds_plateau_beta, 'omitnan'), ...
            sum(ds_only & cbds_progress_early > ds_progress_early + 10 * eps), ...
            sum(ds_only)};
    end
end

trajectory = cell2table(rows, 'VariableNames', { ...
    'feature', 'sigma', 'tau', 'problem', 'n', 'early_budget_beta', ...
    'median_ds_hit_beta', 'median_cbds_hit_beta', ...
    'median_ds_only_hit_beta', 'median_ds_progress_at_beta24', ...
    'median_cbds_progress_at_beta24', ...
    'median_cbds_minus_ds_progress_at_beta24', ...
    'median_ds_progress_after_beta24', ...
    'median_cbds_progress_after_beta24', ...
    'median_ds_within_one_pct_final_beta', ...
    'median_cbds_within_one_pct_final_beta', ...
    'ds_only_runs_cbds_ahead_at_beta24', 'ds_only_runs'});

end

function history = result_history(results, i_problem, i_solver, i_run)

nf = floor(results.n_evals(i_problem, i_solver, i_run));
history = squeeze(results.fun_histories( ...
    i_problem, i_solver, i_run, 1:nf));
history = history(:);
history(~isfinite(history)) = Inf;

end

function progress = normalized_progress(history, f_init, scale)

progress = (f_init - cummin(history)) / scale;

end

function beta = within_one_percent_beta(progress, n)

target = progress(end) - 0.01;
index = find(progress >= target - 10 * eps, 1, 'first');
beta = index / (n + 1);

end

function label = classify_solved(ds_work, cbds_work)

if isfinite(ds_work) && isfinite(cbds_work)
    label = "both";
elseif isfinite(ds_work)
    label = "ds_only";
elseif isfinite(cbds_work)
    label = "cbds_only";
else
    label = "neither";
end

end

function index = find_first_or_nan(mask)

index = find(mask, 1, 'first');
if isempty(index)
    index = NaN;
end

end

function evidence = sort_evidence(evidence, problem_order)

evidence.selection_order = zeros(height(evidence), 1);
for i_problem = 1:numel(problem_order)
    evidence.selection_order(evidence.problem == problem_order(i_problem)) = i_problem;
end
evidence = sortrows(evidence, ...
    {'selection_order', 'sigma', 'tau'}, {'ascend', 'descend', 'descend'});

end

function replay_matrix = make_replay_matrix(shortlist)

noise_levels = [1e-1, 1e-2];
rows = cell(height(shortlist) * numel(noise_levels), 14);
row = 0;
for i_case = 1:height(shortlist)
    for sigma = noise_levels
        row = row + 1;
        if sigma == 1e-1
            target_taus = "1e-1";
        else
            target_taus = "1e-1,1e-2";
        end
        priority = replay_priority(shortlist.primary_role(i_case), sigma);
        rows(row, :) = {priority, shortlist.selection_order(i_case), ...
            shortlist.problem(i_case), shortlist.n(i_case), sigma, target_taus, ...
            20, 30, 200, 1e-6, "ds,cbds", "noisy", true, ...
            shortlist.primary_role(i_case)};
    end
end

replay_matrix = cell2table(rows, 'VariableNames', { ...
    'priority_tier', 'selection_order', 'problem', 'n', 'sigma', ...
    'analysis_taus', 'initial_runs', 'increase_to_runs_if_uncertain', ...
    'max_eval_factor', 'step_tolerance', 'algorithms', 'decision_source', ...
    'oracle_intervention_deferred', 'primary_role'});
replay_matrix = sortrows(replay_matrix, ...
    {'priority_tier', 'selection_order', 'sigma'}, ...
    {'ascend', 'ascend', 'descend'});

end

function priority = replay_priority(role, sigma)

if role == "early_ds_only_control" && sigma == 1e-2
    priority = 2;
elseif ismember(role, ["strict_target_cbds_refinement", ...
        "strict_target_ds_persistence"]) && sigma == 1e-1
    priority = 2;
elseif startsWith(role, "stable_cbds_") && sigma == 1e-1
    priority = 2;
else
    priority = 1;
end

end

function validate_selection(shortlist, evidence, replay_matrix)

assert(height(shortlist) == 9 && numel(unique(shortlist.problem)) == 9, ...
    'Stage 5 must contain nine distinct problems.');
assert(all(shortlist.authoritative_definition_available), ...
    'Every selected problem must have an authoritative S2MPJ definition.');
assert(height(evidence) == 27, ...
    'Expected three primary-pair evidence rows per selected problem.');
assert(height(replay_matrix) == 18, ...
    'Expected two noise-level replay rows per selected problem.');
assert(sum(replay_matrix.priority_tier == 1) >= 12, ...
    'The core replay tier does not cover enough problem-feature cases.');
assert(all(replay_matrix.decision_source == "noisy") ...
    && all(replay_matrix.oracle_intervention_deferred), ...
    'Stage 6 must preserve noisy decisions and defer oracle intervention.');

assert_counts(shortlist, 'FMINSRF2', [1, 4, 0, 0], [5, 0, 0, 0], [0, 5, 0, 0]);
assert_counts(shortlist, 'GENHUMPS', [0, 5, 0, 0], [0, 5, 0, 0], [0, 5, 0, 0]);
assert_counts(shortlist, 'COOLHANSLS', [5, 0, 0, 0], [5, 0, 0, 0], [5, 0, 0, 0]);
assert_counts(shortlist, 'EXTROSNB', [5, 0, 0, 0], [5, 0, 0, 0], [0, 0, 5, 0]);
assert_counts(shortlist, 'DIXON3DQ', [5, 0, 0, 0], [5, 0, 0, 0], [0, 5, 0, 0]);
assert_counts(shortlist, 'HILBERTB', [1, 4, 0, 0], [5, 0, 0, 0], [5, 0, 0, 0]);
assert_counts(shortlist, 'MSQRTALS', [0, 0, 5, 0], [0, 0, 5, 0], [0, 0, 5, 0]);
assert_counts(shortlist, 'SBRYBND', [0, 0, 5, 0], [0, 0, 5, 0], [0, 0, 5, 0]);

end

function assert_counts(shortlist, problem, high, low_coarse, low_strict)

row = shortlist(shortlist.problem == string(problem), :);
actual_high = pair_counts(row, 'sigma_1e_1_tau_1e_1');
actual_low_coarse = pair_counts(row, 'sigma_1e_2_tau_1e_1');
actual_low_strict = pair_counts(row, 'sigma_1e_2_tau_1e_2');
assert(height(row) == 1 && isequal(actual_high, high) ...
    && isequal(actual_low_coarse, low_coarse) ...
    && isequal(actual_low_strict, low_strict), ...
    'Unexpected primary-pair status for %s.', problem);

end

function counts = pair_counts(row, prefix)

counts = [row.([prefix, '_both']), row.([prefix, '_ds_only']), ...
    row.([prefix, '_cbds_only']), row.([prefix, '_neither'])];

end

function ensure_s2mpj_paths()

home_dir = char(java.lang.System.getProperty('user.home'));
root = fullfile(home_dir, 'local', 'optiprofiler', 'matlab', 'optiprofiler');
paths = {fullfile(root, 'src'), fullfile(root, 'problem_libs'), ...
    fullfile(root, 'problem_libs', 's2mpj')};
for i_path = 1:numel(paths)
    if isfolder(paths{i_path})
        addpath(paths{i_path});
    end
end
if ~exist('s2mpj_load', 'file')
    error('Cannot find the local OptiProfiler S2MPJ loader.');
end

end

function write_report(selection, output_file)

fid = fopen(output_file, 'w');
cleanup = onCleanup(@() fclose(fid));
shortlist = selection.shortlist;
evidence = selection.evidence;
replay = selection.replay_matrix;

fprintf(fid, '# Stage 5 Representative-Problem Shortlist\n\n');
fprintf(fid, 'Generated: %s\n\n', selection.created);
fprintf(fid, '本阶段从 Stage 4 ranked candidate pools 中固定 `9` 个问题。选择目标不是');
fprintf(fid, '最大化 DS 的胜例数量，而是让同一组案例覆盖 `late DS coverage`、');
fprintf(fid, '`CBDS early efficiency`、strict-target 下相反的 classification transitions，');
fprintf(fid, '以及稳定的 `CBDS-only counterexamples`。\n\n');

fprintf(fid, '## Selection Rules\n\n');
fprintf(fid, '1. 只使用三个 primary `(sigma,tau)` pairs，不使用 ten-tau average score。\n');
fprintf(fid, '2. 优先选择 five-run classification 至少 `4/5` 稳定的问题；明确保留的');
fprintf(fid, ' counterrun 除外。\n');
fprintf(fid, '3. `late DS-only` 必须由 first-hitting budget 与 true-history screening 支撑，');
fprintf(fid, '不能只根据最终 DS-only 标签命名。\n');
fprintf(fid, '4. 同时纳入 DS-positive、CBDS-positive 和 within-family opposite cases。\n');
fprintf(fid, '5. 每个问题必须能由本地 S2MPJ MATLAB/Python source 重新加载，且实际');
fprintf(fid, '实例维数与 Stage 3 数据一致。\n\n');

fprintf(fid, 'Status 记为 `both/DS-only/CBDS-only/neither`，每项总和为 5。\n\n');
fprintf(fid, '| # | Problem | n | Primary role | sigma=.1,tau=.1 | sigma=.01,tau=.1 | sigma=.01,tau=.01 | Structure |\n');
fprintf(fid, '| ---: | --- | ---: | --- | ---: | ---: | ---: | --- |\n');
for i_case = 1:height(shortlist)
    fprintf(fid, '| %d | `%s` | %d | `%s` | %s | %s | %s | %s |\n', ...
        shortlist.selection_order(i_case), shortlist.problem(i_case), ...
        shortlist.n(i_case), shortlist.primary_role(i_case), ...
        format_pair_counts(shortlist(i_case, :), 'sigma_1e_1_tau_1e_1'), ...
        format_pair_counts(shortlist(i_case, :), 'sigma_1e_2_tau_1e_1'), ...
        format_pair_counts(shortlist(i_case, :), 'sigma_1e_2_tau_1e_2'), ...
        shortlist.structure(i_case));
end
fprintf(fid, '\n');

fprintf(fid, '## Why Each Case Is Kept\n\n');
for i_case = 1:height(shortlist)
    fprintf(fid, '- `%s`: %s\n', shortlist.problem(i_case), ...
        shortlist.selection_reason(i_case));
end
fprintf(fid, '\n');

fprintf(fid, '## Trajectory Screening\n\n');
fprintf(fid, '`beta = evaluations/(n+1)`。`progress@24` 使用 paired reference minimum ');
fprintf(fid, '归一化后的 best-so-far true progress。下面只列 role-defining pair。\n\n');
fprintf(fid, '| Problem | Pair | DS-only | Median DS-only hit beta | CBDS-DS progress@24 | DS late progress | CBDS final-1%% beta |\n');
fprintf(fid, '| --- | --- | ---: | ---: | ---: | ---: | ---: |\n');
for i_case = 1:height(shortlist)
    row = role_defining_evidence(evidence, shortlist.primary_role(i_case), ...
        shortlist.problem(i_case));
    fprintf(fid, '| `%s` | `sigma=%.0e,tau=%.0e` | %d | %.3g | %+.3g | %.3g | %.3g |\n', ...
        row.problem, row.sigma, row.tau, row.ds_only, ...
        row.median_ds_only_hit_beta, ...
        row.median_cbds_minus_ds_progress_at_beta24, ...
        row.median_ds_progress_after_beta24, ...
        row.median_cbds_within_one_pct_final_beta);
end
fprintf(fid, '\n该表是 case selection diagnostic，不是 mechanism proof。特别是 ');
fprintf(fid, '`progress@24` 的符号不能替代 Stage 6 的 noisy decision、step-size 和 ');
fprintf(fid, 'false-rejection traces。\n\n');

fprintf(fid, '## Deliberate Contrasts\n\n');
fprintf(fid, '- `FMINSRF2` vs `GENHUMPS`: 都有 DS-only，但前者是 late coverage，');
fprintf(fid, '后者很早命中，是 within-DS positive control。\n');
fprintf(fid, '- `EXTROSNB` vs `DIXON3DQ`: 在 `sigma=1e-2,tau=1e-1` 都是 ');
fprintf(fid, 'CBDS faster；收紧到 `tau=1e-2` 后分别变成 CBDS-only 与 DS-only。\n');
fprintf(fid, '- `MSQRTALS` vs `SBRYBND`: 都是稳定 CBDS-only，但分别代表 dense matrix');
fprintf(fid, ' coupling 与 sparse banded residual structure。\n');
fprintf(fid, '- `FLETCHCR` vs `EXTROSNB`: 都属于 Rosenbrock-type coupled objectives，');
fprintf(fid, '却产生相反 coverage ordering，防止把结论粗暴归因于函数名称或 family。\n\n');

fprintf(fid, '## Important Exclusions\n\n');
fprintf(fid, '- `INDEF`, `INDEFM`, `CURLY*`, `SCURLY*`, and `FLETCHBV` 尽管排名靠前，');
fprintf(fid, '但 boundedness/solution interpretation 或 family duplication 需要额外澄清，');
fprintf(fid, '因此不进入主 replay shortlist。\n');
fprintf(fid, '- `MSQRTBLS` 与 `MSQRTALS` 行为和结构高度重复，只保留后者。\n');
fprintf(fid, '- `ERRINROS/ERRINRSM` 是很强的 early-efficiency candidates，但 ');
fprintf(fid, '`COOLHANSLS` 提供更不同的 matrix-equation structure，而 `EXTROSNB` 已保留');
fprintf(fid, '一个 Rosenbrock-type CBDS-positive case。\n\n');

fprintf(fid, '## Stage 6 Replay Matrix\n\n');
fprintf(fid, '- 所有 9 个问题均在 `sigma=1e-1` 和 `1e-2` 下进入矩阵，共 18 个');
fprintf(fid, ' problem-feature combinations。\n');
fprintf(fid, '- Tier 1 有 %d 个 combinations；每项先做 20 paired runs，', ...
    sum(replay.priority_tier == 1));
fprintf(fid, 'uncertainty 仍大时增加到 30。\n');
fprintf(fid, '- Stage 6 只使用 normal noisy decisions，并先严格验证 trace 与正式 solver');
fprintf(fid, ' 一致；oracle true-acceptance intervention 延后到 Stage 9。\n');
fprintf(fid, '- `tau` 不改变 solver trajectory。同一个 `(problem,sigma,run)` 的 trace ');
fprintf(fid, '同时分析该 sigma 对应的 relevant taus。\n\n');
fprintf(fid, '机器可读 replay 计划见 `stage6_targeted_replay_matrix.csv`。\n\n');

fprintf(fid, '## Source Boundary\n\n');
fprintf(fid, '本阶段已经验证 source availability、S2MPJ classification、维数、无约束性');
fprintf(fid, '和初始函数值。完整 objective expression 与 structure-to-mechanism analysis ');
fprintf(fid, '属于 Stage 8，不能把这里的短结构标签当作最终函数分析。\n');

end

function row = role_defining_evidence(evidence, role, problem)

if ismember(role, ["late_ds_coverage", "late_ds_with_counterrun", ...
        "early_ds_only_control", "noise_sensitive_cbds_recovery"])
    sigma = 1e-1;
    tau = 1e-1;
elseif ismember(role, ["strict_target_cbds_refinement", ...
        "strict_target_ds_persistence", ...
        "stable_cbds_dense_ls_counterexample", ...
        "stable_cbds_banded_ls_counterexample"])
    sigma = 1e-2;
    tau = 1e-2;
else
    sigma = 1e-2;
    tau = 1e-1;
end
selected = evidence.problem == problem & abs(evidence.sigma - sigma) < 10 * eps ...
    & abs(evidence.tau - tau) < 10 * eps;
assert(sum(selected) == 1, 'Missing role-defining evidence for %s.', problem);
row = evidence(selected, :);

end

function text = format_pair_counts(row, prefix)

counts = pair_counts(row, prefix);
text = sprintf('%d/%d/%d/%d', counts);

end
