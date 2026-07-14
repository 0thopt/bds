function analysis_file = analyze_ds_vs_cbds_high_noise_replay(manifest_file, options)
%ANALYZE_DS_VS_CBDS_HIGH_NOISE_REPLAY analyzes Stage 6 paired trajectories.

if nargin < 2
    options = struct();
end
loaded = load(manifest_file, 'run_summary', 'replay_matrix');
run_index = loaded.run_summary;
replay_matrix = loaded.replay_matrix;
output_dir = fileparts(manifest_file);
options = set_default(options, 'stage3_pair_summary_file', ...
    default_stage3_pair_summary_file());
options = set_default(options, 'write_trace_audit', true);

assert(all(run_index.success), 'The replay manifest contains failed tasks.');
pair_summary_stage3 = readtable(options.stage3_pair_summary_file, ...
    'TextType', 'string');
pair_keys = unique(run_index(:, {'priority_tier', 'selection_order', ...
    'problem', 'n', 'sigma', 'analysis_taus', 'primary_role', 'run', 'seed'}), ...
    'rows', 'stable');

hit_names = hit_variable_names();
window_names = window_variable_names();
trace_audit_names = trace_audit_variable_names();
hit_rows = cell(0, numel(hit_names));
window_rows = cell(0, numel(window_names));
trace_audit_rows = cell(height(run_index), numel(trace_audit_names));
audit_row = 0;

for i_pair = 1:height(pair_keys)
    key = pair_keys(i_pair, :);
    selected = run_index.problem == key.problem ...
        & run_index.sigma == key.sigma ...
        & run_index.run == key.run;
    pair = sortrows(run_index(selected, :), 'algorithm', 'descend');
    assert(height(pair) == 2);
    assert(isequal(pair.algorithm, ["ds"; "cbds"]));

    traces = cell(2, 1);
    for i_solver = 1:2
        trace_file = fullfile(output_dir, pair.trace_file(i_solver));
        traces{i_solver} = load(trace_file, 'identity', 'x', 'f', ...
            'output', 'trace', 'run_summary');
        audit_row = audit_row + 1;
        trace_audit_rows(audit_row, :) = trace_audit_row( ...
            traces{i_solver}, pair(i_solver, :), trace_file);
    end

    ds = traces{1};
    cbds = traces{2};
    validate_pair(ds, cbds, key);
    f_init = ds.output.true_fhist(1);
    reference_min = min([f_init, ds.output.true_fhist, ...
        cbds.output.true_fhist], [], 'omitnan');
    taus = parse_taus(key.analysis_taus);

    for tau = taus
        threshold = profile_threshold(f_init, reference_min, tau);
        ds_work = find_first_or_nan(ds.output.true_fhist <= threshold);
        cbds_work = find_first_or_nan(cbds.output.true_fhist <= threshold);
        classification = classify_solved(ds_work, cbds_work);
        time_ordering = classify_time(ds_work, cbds_work);
        plateau_beta = stage3_plateau_beta(pair_summary_stage3, key.sigma, tau);
        plateau_eval = min(key.n * 200, floor(plateau_beta * (key.n + 1)));

        ds_hit = hit_state(ds.trace, ds.output, ds_work);
        cbds_hit = hit_state(cbds.trace, cbds.output, cbds_work);
        hit_rows(end + 1, :) = { ... %#ok<AGROW>
            key.priority_tier, key.selection_order, key.problem, key.n, ...
            key.sigma, tau, key.analysis_taus, key.primary_role, key.run, ...
            key.seed, f_init, reference_min, threshold, ds_work, cbds_work, ...
            normalized_work(ds_work, key.n), normalized_work(cbds_work, key.n), ...
            classification, time_ordering, cbds_work - ds_work, ...
            ratio_or_nan(ds_work, cbds_work), plateau_beta, plateau_eval, ...
            hit_timing(ds_work, plateau_eval), hit_timing(cbds_work, plateau_eval), ...
            ds_hit.iteration, ds_hit.block, ds_hit.direction_index, ...
            ds_hit.polling_order, ds_hit.accepted, ds_hit.base_changed, ...
            ds_hit.true_success, ds_hit.noisy_success, ds_hit.alpha_before, ...
            ds_hit.alpha_after, ds_hit.global_alpha_min_before, ...
            ds_hit.global_alpha_max_before, cbds_hit.iteration, cbds_hit.block, ...
            cbds_hit.direction_index, cbds_hit.polling_order, cbds_hit.accepted, ...
            cbds_hit.base_changed, cbds_hit.true_success, ...
            cbds_hit.noisy_success, cbds_hit.alpha_before, cbds_hit.alpha_after, ...
            cbds_hit.global_alpha_min_before, cbds_hit.global_alpha_max_before};

        window_rows(end + 1, :) = trajectory_window_row( ... %#ok<AGROW>
            key, tau, threshold, plateau_beta, plateau_eval, ds, "ds", ds_work);
        window_rows(end + 1, :) = trajectory_window_row( ... %#ok<AGROW>
            key, tau, threshold, plateau_beta, plateau_eval, cbds, "cbds", cbds_work);
    end
end

hit_table = cell2table(hit_rows, 'VariableNames', hit_names);
trajectory_windows = cell2table(window_rows, ...
    'VariableNames', window_names);
trace_audit = cell2table(trace_audit_rows, ...
    'VariableNames', trace_audit_names);
case_summary = summarize_cases(hit_table);
uncertainty = assess_replay_uncertainty(hit_table);

if options.write_trace_audit
    writetable(trace_audit, fullfile(output_dir, 'stage6_trace_audit.csv'));
end
writetable(hit_table, fullfile(output_dir, 'stage6_relevant_tau_hits.csv'));
writetable(trajectory_windows, fullfile(output_dir, ...
    'stage6_plateau_window_metrics.csv'));
writetable(case_summary, fullfile(output_dir, 'stage6_case_summary.csv'));
writetable(uncertainty, fullfile(output_dir, 'stage6_uncertainty_assessment.csv'));

analysis.manifest_file = manifest_file;
analysis.replay_matrix = replay_matrix;
analysis.run_index = run_index;
analysis.trace_audit = trace_audit;
analysis.hit_table = hit_table;
analysis.trajectory_windows = trajectory_windows;
analysis.case_summary = case_summary;
analysis.uncertainty = uncertainty;
analysis.options = options;
analysis_file = fullfile(output_dir, 'stage6_replay_analysis.mat');
save(analysis_file, 'analysis', '-v7.3');
write_report(case_summary, uncertainty, trace_audit, ...
    fullfile(output_dir, 'stage6_replay_analysis.md'));

audit_analysis(run_index, hit_table, trajectory_windows, trace_audit, replay_matrix);
fprintf('Stage 6 replay analysis: %s\n', analysis_file);

end

function row = trajectory_window_row(key, tau, threshold, plateau_beta, ...
    plateau_eval, loaded, algorithm, first_hit)

trace = loaded.trace;
output = loaded.output;
early_event = trace.evaluation <= plateau_eval;
late_event = trace.evaluation > plateau_eval;
early_visit = trace.block_state.evaluation_end <= plateau_eval;
late_visit = trace.block_state.evaluation_end > plateau_eval;
best_before = min(output.true_fhist(1:min(plateau_eval, output.funcCount)), ...
    [], 'omitnan');
best_final = output.best_true_value;
alpha_plateau = alpha_state_after_evaluation(trace, output, plateau_eval);
final_alpha = output.alpha_hist(:, end);

row = {key.priority_tier, key.selection_order, key.problem, key.n, ...
    key.sigma, tau, key.primary_role, key.run, key.seed, algorithm, ...
    threshold, first_hit, normalized_work(first_hit, key.n), plateau_beta, ...
    plateau_eval, output.funcCount, output.exitflag, best_before, best_final, ...
    best_before - best_final, sum(early_event), sum(late_event), ...
    sum(trace.accepted(early_event)), sum(trace.accepted(late_event)), ...
    sum(trace.base_changed(early_event)), sum(trace.base_changed(late_event)), ...
    sum(trace.false_acceptance(early_event)), ...
    sum(trace.false_acceptance(late_event)), ...
    sum(trace.false_rejection(early_event)), ...
    sum(trace.false_rejection(late_event)), ...
    sum(trace.block_state.step_update_code(early_visit) == 1), ...
    sum(trace.block_state.step_update_code(late_visit) == 1), ...
    sum(trace.block_state.step_update_code(early_visit) == -1), ...
    sum(trace.block_state.step_update_code(late_visit) == -1), ...
    min(alpha_plateau), median(alpha_plateau), max(alpha_plateau), ...
    min(final_alpha), median(final_alpha), max(final_alpha)};
end

function hit = hit_state(trace, output, work)
names = {'iteration', 'block', 'direction_index', 'polling_order', ...
    'alpha_before', 'alpha_after', 'global_alpha_min_before', ...
    'global_alpha_max_before'};
for i_name = 1:numel(names)
    hit.(names{i_name}) = NaN;
end
hit.accepted = false;
hit.base_changed = false;
hit.true_success = false;
hit.noisy_success = false;
if ~isfinite(work)
    return;
end
if work == 1
    alpha = output.alpha_hist(:, 1);
    hit.iteration = 0;
    hit.global_alpha_min_before = min(alpha);
    hit.global_alpha_max_before = max(alpha);
    return;
end

i_event = find(trace.evaluation == work, 1);
assert(isscalar(i_event));
hit.iteration = trace.iteration(i_event);
hit.block = trace.block(i_event);
hit.direction_index = trace.direction_index(i_event);
hit.polling_order = trace.polling_order(i_event);
hit.accepted = trace.accepted(i_event);
hit.base_changed = trace.base_changed(i_event);
hit.true_success = trace.true_success(i_event);
hit.noisy_success = trace.noisy_success(i_event);
hit.alpha_before = trace.alpha_before(i_event);
hit.alpha_after = trace.alpha_after(i_event);
alpha = alpha_state_before_evaluation(trace, output, work);
hit.global_alpha_min_before = min(alpha);
hit.global_alpha_max_before = max(alpha);
end

function alpha = alpha_state_before_evaluation(trace, output, evaluation)
alpha = output.alpha_hist(:, 1);
state = trace.block_state;
prior = find(state.evaluation_end < evaluation);
for i_visit = prior
    alpha(state.block(i_visit)) = state.alpha_after(i_visit);
end
end

function alpha = alpha_state_after_evaluation(trace, output, evaluation)
alpha = output.alpha_hist(:, 1);
state = trace.block_state;
completed = find(state.evaluation_end <= evaluation);
for i_visit = completed
    alpha(state.block(i_visit)) = state.alpha_after(i_visit);
end
end

function row = trace_audit_row(loaded, index_row, trace_file)
trace = loaded.trace;
output = loaded.output;
identity = loaded.identity;
identity_match = identity.problem == index_row.problem ...
    && identity.algorithm == index_row.algorithm ...
    && identity.sigma == index_row.sigma ...
    && identity.run == index_row.run ...
    && identity.seed == index_row.seed;
complete_history = output.funcCount == size(output.xhist, 2) ...
    && output.funcCount == numel(output.fhist) ...
    && output.funcCount == numel(output.true_fhist) ...
    && output.funcCount - 1 == numel(trace.evaluation);
evaluation_order = isequal(trace.evaluation, 2:output.funcCount);
point_history_match = isequaln(trace.trial_point, output.xhist(:, 2:end));
noisy_history_match = isequaln(trace.trial_noisy_raw, output.fhist(2:end));
true_history_match = isequaln(trace.trial_true, output.true_fhist(2:end));
block_history_match = isequal(trace.block_state.block, output.blocks_hist);
budget_ok = output.funcCount <= identity.maxfun;
seed_ok = identity.seed == mod(211 * identity.run, 2^32);
termination_ok = ismember(output.exitflag, [0, 1, 3]);
row = {identity.problem, identity.n, identity.sigma, identity.run, ...
    identity.seed, identity.algorithm, string(trace_file), output.funcCount, ...
    identity.maxfun, identity_match, complete_history, evaluation_order, ...
    point_history_match, noisy_history_match, true_history_match, ...
    block_history_match, budget_ok && seed_ok, termination_ok};
end

function validate_pair(ds, cbds, key)
assert(ds.identity.problem == key.problem && cbds.identity.problem == key.problem);
assert(ds.identity.sigma == key.sigma && cbds.identity.sigma == key.sigma);
assert(ds.identity.run == key.run && cbds.identity.run == key.run);
assert(ds.identity.seed == key.seed && cbds.identity.seed == key.seed);
assert(ds.identity.algorithm == "ds" && cbds.identity.algorithm == "cbds");
assert(isequaln(ds.output.xhist(:, 1), cbds.output.xhist(:, 1)));
assert(isequaln(ds.output.true_fhist(1), cbds.output.true_fhist(1)));
end

function summary = summarize_cases(hit_table)
keys = unique(hit_table(:, {'priority_tier', 'selection_order', 'problem', ...
    'n', 'sigma', 'tau', 'primary_role'}), 'rows', 'stable');
rows = cell(height(keys), 22);
for i_key = 1:height(keys)
    selected = hit_table.problem == keys.problem(i_key) ...
        & hit_table.sigma == keys.sigma(i_key) ...
        & hit_table.tau == keys.tau(i_key);
    data = hit_table(selected, :);
    both = data.classification == "both";
    ds_only = data.classification == "ds_only";
    cbds_only = data.classification == "cbds_only";
    neither = data.classification == "neither";
    ds_faster = data.time_ordering == "ds_faster";
    cbds_faster = data.time_ordering == "cbds_faster";
    time_tie = data.time_ordering == "tie";
    contribution = double(ds_only) - double(cbds_only);
    [ci_low, ci_high] = mean_ci(contribution);
    rows(i_key, :) = {keys.priority_tier(i_key), keys.selection_order(i_key), ...
        keys.problem(i_key), keys.n(i_key), keys.sigma(i_key), keys.tau(i_key), ...
        keys.primary_role(i_key), height(data), sum(both), sum(ds_only), ...
        sum(cbds_only), sum(neither), sum(ds_faster), sum(cbds_faster), ...
        sum(time_tie), median(data.ds_work, 'omitnan'), ...
        median(data.cbds_work, 'omitnan'), median(data.ds_work_beta, 'omitnan'), ...
        median(data.cbds_work_beta, 'omitnan'), mean(contribution), ci_low, ci_high};
end
summary = cell2table(rows, 'VariableNames', {'priority_tier', ...
    'selection_order', 'problem', 'n', 'sigma', 'tau', 'primary_role', ...
    'n_runs', 'both', 'ds_only', 'cbds_only', 'neither', 'ds_faster', ...
    'cbds_faster', 'time_ties', 'median_ds_work', 'median_cbds_work', ...
    'median_ds_work_beta', 'median_cbds_work_beta', ...
    'mean_coverage_contribution_ds', 'coverage_ci_low', 'coverage_ci_high'});
end

function uncertainty = assess_replay_uncertainty(hit_table)
summary = summarize_cases(hit_table);
dominant_fraction = max([summary.both, summary.ds_only, summary.cbds_only, ...
    summary.neither], [], 2) ./ summary.n_runs;
coverage_ci_crosses_zero = summary.coverage_ci_low <= 0 ...
    & summary.coverage_ci_high >= 0;
classification_unstable = dominant_fraction < 0.70;
increase_to_30 = classification_unstable;
uncertainty = summary(:, {'priority_tier', 'selection_order', 'problem', ...
    'n', 'sigma', 'tau', 'primary_role', 'n_runs'});
uncertainty.dominant_classification_fraction = dominant_fraction;
uncertainty.classification_unstable = classification_unstable;
uncertainty.coverage_ci_crosses_zero = coverage_ci_crosses_zero;
uncertainty.increase_to_30 = increase_to_30;
end

function [low, high] = mean_ci(values)
n = numel(values);
center = mean(values);
if n <= 1
    low = NaN;
    high = NaN;
else
    half_width = 1.96 * std(values) / sqrt(n);
    low = max(-1, center - half_width);
    high = min(1, center + half_width);
end
end

function beta = stage3_plateau_beta(summary, sigma, tau)
selected = summary.sigma == sigma & summary.tau == tau ...
    & summary.role == "primary";
assert(sum(selected) == 1, ...
    'Expected one Stage 3 primary pair for sigma=%g, tau=%g.', sigma, tau);
beta = summary.cbds_data_within_one_pct_final(selected);
end

function threshold = profile_threshold(f_init, reference_min, tau)
if isinf(f_init)
    threshold = Inf;
elseif isfinite(reference_min)
    threshold = max(tau * f_init + (1 - tau) * reference_min, reference_min);
else
    threshold = -Inf;
end
end

function taus = parse_taus(text)
parts = split(string(text), ',');
taus = arrayfun(@str2double, parts(:)');
assert(all(isfinite(taus)) && all(taus > 0));
end

function work = find_first_or_nan(mask)
work = find(mask, 1);
if isempty(work)
    work = NaN;
end
end

function beta = normalized_work(work, n)
if isfinite(work)
    beta = work / (n + 1);
else
    beta = NaN;
end
end

function value = ratio_or_nan(numerator, denominator)
if isfinite(numerator) && isfinite(denominator) && denominator > 0
    value = numerator / denominator;
else
    value = NaN;
end
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

function label = classify_time(ds_work, cbds_work)
if ~(isfinite(ds_work) && isfinite(cbds_work))
    label = "not_both";
elseif ds_work < cbds_work
    label = "ds_faster";
elseif cbds_work < ds_work
    label = "cbds_faster";
else
    label = "tie";
end
end

function label = hit_timing(work, plateau_eval)
if ~isfinite(work)
    label = "not_hit";
elseif work <= plateau_eval
    label = "by_cbds_plateau";
else
    label = "after_cbds_plateau";
end
end

function names = hit_variable_names()
names = {'priority_tier', 'selection_order', 'problem', 'n', 'sigma', ...
    'tau', 'analysis_taus', 'primary_role', 'run', 'seed', 'f_init', ...
    'reference_min', 'threshold', 'ds_work', 'cbds_work', 'ds_work_beta', ...
    'cbds_work_beta', 'classification', 'time_ordering', ...
    'evaluation_advantage_ds', 'ds_to_cbds_time_ratio', ...
    'cbds_plateau_beta', 'cbds_plateau_evaluation', 'ds_hit_timing', ...
    'cbds_hit_timing', 'ds_hit_iteration', 'ds_hit_block', ...
    'ds_hit_direction_index', 'ds_hit_polling_order', 'ds_hit_accepted', ...
    'ds_hit_base_changed', 'ds_hit_true_success', 'ds_hit_noisy_success', ...
    'ds_hit_alpha_before', 'ds_hit_alpha_after', ...
    'ds_hit_global_alpha_min_before', 'ds_hit_global_alpha_max_before', ...
    'cbds_hit_iteration', 'cbds_hit_block', 'cbds_hit_direction_index', ...
    'cbds_hit_polling_order', 'cbds_hit_accepted', 'cbds_hit_base_changed', ...
    'cbds_hit_true_success', 'cbds_hit_noisy_success', ...
    'cbds_hit_alpha_before', 'cbds_hit_alpha_after', ...
    'cbds_hit_global_alpha_min_before', 'cbds_hit_global_alpha_max_before'};
end

function names = window_variable_names()
names = {'priority_tier', 'selection_order', 'problem', 'n', 'sigma', ...
    'tau', 'primary_role', 'run', 'seed', 'algorithm', 'threshold', ...
    'first_hit', 'first_hit_beta', 'cbds_plateau_beta', ...
    'cbds_plateau_evaluation', 'func_count', 'exitflag', ...
    'best_true_by_plateau', 'best_true_final', 'true_progress_after_plateau', ...
    'evaluations_before_plateau', 'evaluations_after_plateau', ...
    'accepted_before_plateau', 'accepted_after_plateau', ...
    'base_changes_before_plateau', 'base_changes_after_plateau', ...
    'false_acceptances_before_plateau', 'false_acceptances_after_plateau', ...
    'false_rejections_before_plateau', 'false_rejections_after_plateau', ...
    'expansions_before_plateau', 'expansions_after_plateau', ...
    'contractions_before_plateau', 'contractions_after_plateau', ...
    'alpha_min_at_plateau', 'alpha_median_at_plateau', ...
    'alpha_max_at_plateau', 'final_alpha_min', 'final_alpha_median', ...
    'final_alpha_max'};
end

function names = trace_audit_variable_names()
names = {'problem', 'n', 'sigma', 'run', 'seed', 'algorithm', ...
    'trace_file', 'func_count', 'maxfun', 'identity_match', ...
    'complete_history', 'evaluation_order', 'point_history_match', ...
    'noisy_history_match', 'true_history_match', 'block_history_match', ...
    'budget_and_seed_ok', 'termination_ok'};
end

function audit_analysis(run_index, hits, windows, trace_audit, matrix)
assert(height(trace_audit) == height(run_index));
logical_fields = {'identity_match', 'complete_history', 'evaluation_order', ...
    'point_history_match', 'noisy_history_match', 'true_history_match', ...
    'block_history_match', 'budget_and_seed_ok', 'termination_ok'};
for i_field = 1:numel(logical_fields)
    assert(all(trace_audit.(logical_fields{i_field})), ...
        'Trace audit failed for %s.', logical_fields{i_field});
end
assert(all(hits.seed == mod(211 * hits.run, 2^32)));
assert(all(hits.tau >= hits.sigma - 10 * eps));
assert(height(windows) == 2 * height(hits));
assert(all(windows.func_count <= 200 * windows.n));
assert(height(unique(run_index(:, {'problem', 'sigma'}), 'rows')) == height(matrix));
end

function write_report(summary, uncertainty, trace_audit, filename)
fid = fopen(filename, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Stage 6 Paired Replay Analysis\n\n');
fprintf(fid, '本报告只分析 `normal noisy decisions`。Oracle true-acceptance intervention ');
fprintf(fid, '仍然推迟到 Stage 9。每个 threshold 使用同一 paired run 的 DS/CBDS ');
fprintf(fid, 'true histories 共同定义 `reference_min`。\n\n');
fprintf(fid, '- Complete trace files audited: `%d/%d`\n', ...
    sum(trace_audit.complete_history), height(trace_audit));
fprintf(fid, '- Missing or budget-exceeding traces: `0`\n\n');

fprintf(fid, '| Problem | Sigma | Tau | Runs | Both/DS-only/CBDS-only/neither | ');
fprintf(fid, 'DS/CBDS/tie faster | Median beta DS/CBDS | Mean net DS coverage [95%% CI] |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:height(summary)
    fprintf(fid, '| `%s` | %.0e | %.0e | %d | %d/%d/%d/%d | %d/%d/%d | ', ...
        summary.problem(i), summary.sigma(i), summary.tau(i), summary.n_runs(i), ...
        summary.both(i), summary.ds_only(i), summary.cbds_only(i), ...
        summary.neither(i), summary.ds_faster(i), summary.cbds_faster(i), ...
        summary.time_ties(i));
    fprintf(fid, '%.3g/%.3g | %+.3f [%+.3f, %+.3f] |\n', ...
        summary.median_ds_work_beta(i), summary.median_cbds_work_beta(i), ...
        summary.mean_coverage_contribution_ds(i), summary.coverage_ci_low(i), ...
        summary.coverage_ci_high(i));
end

needs_more = uncertainty(uncertainty.increase_to_30, :);
fprintf(fid, '\n## Replay Sufficiency\n\n');
fprintf(fid, '`increase_to_30` is triggered only when no single solved-set ');
fprintf(fid, 'classification occupies at least 70%% of the first 20 paired runs.\n\n');
if isempty(needs_more)
    fprintf(fid, 'All problem-sigma-tau rows pass the 20-run classification-stability rule.\n');
else
    fprintf(fid, '| Problem | Sigma | Tau | Dominant fraction |\n');
    fprintf(fid, '| --- | ---: | ---: | ---: |\n');
    for i = 1:height(needs_more)
        fprintf(fid, '| `%s` | %.0e | %.0e | %.2f |\n', ...
            needs_more.problem(i), needs_more.sigma(i), needs_more.tau(i), ...
            needs_more.dominant_classification_fraction(i));
    end
end
end

function filename = default_stage3_pair_summary_file()
path_tests = fileparts(mfilename('fullpath'));
filename = fullfile(path_tests, 'stage6_inputs', ...
    'noise_matched_pair_summary.csv');
end

function options = set_default(options, name, value)
if ~isfield(options, name) || isempty(options.(name))
    options.(name) = value;
end
end
