function analysis_file = analyze_ds_vs_cbds_noise_matched_problem_ranking(manifest_file)
%ANALYZE_DS_VS_CBDS_NOISE_MATCHED_PROBLEM_RANKING ranks problem contributions.

if nargin < 1 || isempty(manifest_file)
    path_tests = fileparts(mfilename('fullpath'));
    listing = dir(fullfile(path_tests, 'testdata', ...
        'ds_vs_cbds_high_noise_primary_*', 'aggregate_manifest.mat'));
    if isempty(listing)
        error('No primary aggregate manifest was found.');
    end
    [~, index] = max([listing.datenum]);
    manifest_file = fullfile(listing(index).folder, listing(index).name);
end

loaded = load(manifest_file, 'manifest');
manifest = loaded.manifest;
output_dir = fullfile(fileparts(manifest_file), 'analysis', ...
    'noise_matched_problem_ranking');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

primary_specs = struct( ...
    'feature', {'noisy_1e-1', 'noisy_1e-2', 'noisy_1e-2'}, ...
    'sigma', {1e-1, 1e-2, 1e-2}, ...
    'tau', {1e-1, 1e-1, 1e-2});
control_specs = struct( ...
    'feature', {'plain', 'plain'}, ...
    'sigma', {NaN, NaN}, ...
    'tau', {1e-1, 1e-2});

primary_run_tables = cell(numel(primary_specs), 1);
for i_spec = 1:numel(primary_specs)
    primary_run_tables{i_spec} = make_run_metrics( ...
        find_feature(manifest, primary_specs(i_spec).feature), primary_specs(i_spec));
end
primary_run_metrics = vertcat(primary_run_tables{:});

control_run_tables = cell(numel(control_specs), 1);
for i_spec = 1:numel(control_specs)
    control_run_tables{i_spec} = make_run_metrics( ...
        find_feature(manifest, control_specs(i_spec).feature), control_specs(i_spec));
end
plain_control_metrics = vertcat(control_run_tables{:});

problem_ranking = summarize_problems(primary_run_metrics);
problem_ranking = attach_plain_control(problem_ranking, plain_control_metrics);
problem_ranking = add_ranks(problem_ranking);
pair_summary = summarize_pairs(primary_run_metrics, problem_ranking);
family_summary = summarize_families(problem_ranking);
transition_summary = summarize_transitions(primary_run_metrics);
validate_against_profile_decomposition(fileparts(output_dir), pair_summary);

writetable(primary_run_metrics, fullfile(output_dir, ...
    'noise_matched_problem_run_metrics.csv'));
writetable(plain_control_metrics, fullfile(output_dir, ...
    'plain_control_run_metrics.csv'));
writetable(problem_ranking, fullfile(output_dir, ...
    'noise_matched_ranked_problems.csv'));
writetable(pair_summary, fullfile(output_dir, ...
    'noise_matched_problem_ranking_pair_summary.csv'));
writetable(family_summary, fullfile(output_dir, ...
    'noise_matched_family_coverage_summary.csv'));
writetable(transition_summary, fullfile(output_dir, ...
    'noise_matched_classification_transitions.csv'));

analysis = struct();
analysis.created = char(datetime('now'));
analysis.manifest_file = manifest_file;
analysis.primary_rule = 'tau >= sigma';
analysis.best_observed_noisy_available = false;
analysis.primary_run_metrics = primary_run_metrics;
analysis.plain_control_metrics = plain_control_metrics;
analysis.problem_ranking = problem_ranking;
analysis.pair_summary = pair_summary;
analysis.family_summary = family_summary;
analysis.transition_summary = transition_summary;
analysis_file = fullfile(output_dir, ...
    'noise_matched_problem_ranking_analysis.mat');
save(analysis_file, 'analysis', '-v7.3');
write_report(analysis, fullfile(output_dir, ...
    'noise_matched_problem_ranking.md'));

fprintf('Noise-matched problem ranking: %s\n', analysis_file);

end

function entry = find_feature(manifest, feature_name)

index = find(strcmp({manifest.features.name}, feature_name), 1);
if isempty(index)
    error('Feature %s is missing from the manifest.', feature_name);
end
entry = manifest.features(index);

end

function run_table = make_run_metrics(entry, spec)

loaded = load(entry.data_file, 'results_plibs');
assert(isscalar(loaded.results_plibs), ...
    'Expected one problem library in %s.', entry.data_file);
results = loaded.results_plibs{1};
assert(numel(results.solver_names) == 2, 'Expected exactly two solvers.');
assert(contains(lower(results.solver_names{1}), 'ds') ...
    && contains(lower(results.solver_names{2}), 'cbds'), ...
    'Expected DS first and CBDS second, but found %s and %s.', ...
    results.solver_names{1}, results.solver_names{2});

n_problems = numel(results.problem_names);
n_runs = size(results.fun_histories, 3);
n_rows = n_problems * n_runs;
rows = cell(n_rows, 31);
row = 0;

for i_problem = 1:n_problems
    for i_run = 1:n_runs
        row = row + 1;
        n = results.problem_dims(i_problem);
        f_init = results.fun_inits(i_problem, ...
            min(i_run, size(results.fun_inits, 2)));
        ds_nf = floor(results.n_evals(i_problem, 1, i_run));
        cbds_nf = floor(results.n_evals(i_problem, 2, i_run));
        assert(ds_nf <= 200 * n && cbds_nf <= 200 * n, ...
            'A run for %s exceeds the 200n budget.', results.problem_names{i_problem});
        ds_history = finite_history(results, i_problem, 1, i_run, ds_nf);
        cbds_history = finite_history(results, i_problem, 2, i_run, cbds_nf);
        ds_best_true = min(ds_history, [], 'omitnan');
        cbds_best_true = min(cbds_history, [], 'omitnan');
        reference_min = min([f_init; ds_best_true; cbds_best_true], [], 'omitnan');
        threshold = profile_threshold(f_init, reference_min, spec.tau);
        ds_work = find_first_or_nan(ds_history <= threshold);
        cbds_work = find_first_or_nan(cbds_history <= threshold);
        classification = classify_solved(ds_work, cbds_work);
        time_ordering = classify_time(ds_work, cbds_work);
        true_tolerance = 1e-10 * max([1, abs(ds_best_true), abs(cbds_best_true)]);
        best_true_ordering = classify_difference( ...
            cbds_best_true - ds_best_true, true_tolerance);
        ds_output_true = indexed_value(results.fun_outs, i_problem, 1, i_run);
        cbds_output_true = indexed_value(results.fun_outs, i_problem, 2, i_run);
        output_tolerance = 1e-10 * max( ...
            [1, abs(ds_output_true), abs(cbds_output_true)]);
        output_true_ordering = classify_difference( ...
            cbds_output_true - ds_output_true, output_tolerance);
        overall_ordering = classify_overall( ...
            classification, time_ordering, best_true_ordering);
        scale = max(1, abs(f_init - reference_min));

        rows(row, :) = {string(spec.feature), spec.sigma, spec.tau, ...
            string(results.problem_names{i_problem}), n, i_run, 211 * i_run, ...
            f_init, reference_min, threshold, ds_work, cbds_work, ...
            cbds_work - ds_work, ds_work / cbds_work, classification, ...
            time_ordering, ds_best_true, cbds_best_true, ...
            cbds_best_true - ds_best_true, ...
            (cbds_best_true - ds_best_true) / scale, best_true_ordering, ...
            ds_output_true, cbds_output_true, cbds_output_true - ds_output_true, ...
            output_true_ordering, ds_output_true - ds_best_true, ...
            cbds_output_true - cbds_best_true, ds_nf, cbds_nf, ...
            coverage_contribution(classification), overall_ordering};
    end
end

run_table = cell2table(rows, 'VariableNames', { ...
    'feature', 'sigma', 'tau', 'problem', 'n', 'run', 'run_seed', ...
    'f_init', 'reference_min', 'threshold', 'ds_work', 'cbds_work', ...
    'evaluation_advantage_ds', 'ds_to_cbds_time_ratio', 'classification', ...
    'time_ordering', 'ds_best_true', 'cbds_best_true', ...
    'best_true_advantage_ds', 'scaled_best_true_advantage_ds', ...
    'best_true_ordering', 'ds_output_true', 'cbds_output_true', ...
    'output_true_advantage_ds', 'output_true_ordering', ...
    'ds_return_gap_from_best', 'cbds_return_gap_from_best', ...
    'ds_evaluations', 'cbds_evaluations', 'coverage_contribution_ds', ...
    'overall_ordering'});

end

function history = finite_history(results, i_problem, i_solver, i_run, nf)

history = squeeze(results.fun_histories(i_problem, i_solver, i_run, 1:nf));
history = history(:);
if isempty(history)
    error('Empty history for problem %s.', results.problem_names{i_problem});
end

end

function value = indexed_value(array, i_problem, i_solver, i_run)

if ismatrix(array)
    value = array(i_problem, i_solver);
else
    value = array(i_problem, i_solver, i_run);
end

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

if ~isfinite(ds_work) || ~isfinite(cbds_work)
    label = "not_both_solved";
elseif ds_work < cbds_work
    label = "ds";
elseif cbds_work < ds_work
    label = "cbds";
else
    label = "tie";
end

end

function label = classify_difference(advantage_ds, tolerance)

if advantage_ds > tolerance
    label = "ds";
elseif advantage_ds < -tolerance
    label = "cbds";
else
    label = "tie";
end

end

function contribution = coverage_contribution(classification)

if classification == "ds_only"
    contribution = 1;
elseif classification == "cbds_only"
    contribution = -1;
else
    contribution = 0;
end

end

function label = classify_overall(classification, time_ordering, true_ordering)

if classification == "ds_only"
    label = "ds";
elseif classification == "cbds_only"
    label = "cbds";
elseif classification == "both"
    label = time_ordering;
else
    label = true_ordering;
end

end

function problem_table = summarize_problems(run_table)

groups = unique(run_table(:, {'feature', 'sigma', 'tau', 'problem', 'n'}), ...
    'rows', 'stable');
n_groups = height(groups);
rows = cell(n_groups, 34);

for i_group = 1:n_groups
    selected = run_table.feature == groups.feature(i_group) ...
        & run_table.tau == groups.tau(i_group) ...
        & run_table.problem == groups.problem(i_group);
    table_group = run_table(selected, :);
    n_runs = height(table_group);
    both = sum(table_group.classification == "both");
    ds_only = sum(table_group.classification == "ds_only");
    cbds_only = sum(table_group.classification == "cbds_only");
    neither = sum(table_group.classification == "neither");
    ds_faster = sum(table_group.time_ordering == "ds");
    cbds_faster = sum(table_group.time_ordering == "cbds");
    time_ties = sum(table_group.time_ordering == "tie");
    both_rows = table_group.classification == "both";
    ds_true_wins = sum(table_group.best_true_ordering == "ds");
    cbds_true_wins = sum(table_group.best_true_ordering == "cbds");
    true_ties = sum(table_group.best_true_ordering == "tie");
    ds_overall = sum(table_group.overall_ordering == "ds");
    cbds_overall = sum(table_group.overall_ordering == "cbds");
    overall_ties = sum(table_group.overall_ordering == "tie");
    class_counts = [both, ds_only, cbds_only, neither];
    dominant_classification = dominant_label( ...
        class_counts, ["both", "ds_only", "cbds_only", "neither"]);
    overall_winner = dominant_label( ...
        [ds_overall, cbds_overall, overall_ties], ["ds", "cbds", "tie"]);
    contribution = ds_only - cbds_only;
    case_pool = classify_case_pool(contribution, both, cbds_faster, n_runs);

    rows(i_group, :) = {n_runs, both, ds_only, cbds_only, neither, ...
        contribution, max(class_counts) / n_runs, dominant_classification, ...
        ds_faster, cbds_faster, time_ties, ...
        median(table_group.ds_to_cbds_time_ratio(both_rows), 'omitnan'), ...
        robust_iqr(table_group.ds_to_cbds_time_ratio(both_rows)), ...
        median(table_group.evaluation_advantage_ds(both_rows), 'omitnan'), ...
        robust_iqr(table_group.evaluation_advantage_ds(both_rows)), ...
        median(table_group.best_true_advantage_ds, 'omitnan'), ...
        robust_iqr(table_group.best_true_advantage_ds), ...
        median(table_group.scaled_best_true_advantage_ds, 'omitnan'), ...
        robust_iqr(table_group.scaled_best_true_advantage_ds), ...
        ds_true_wins, cbds_true_wins, true_ties, ...
        median(table_group.output_true_advantage_ds, 'omitnan'), ...
        robust_iqr(table_group.output_true_advantage_ds), ...
        median(table_group.ds_return_gap_from_best, 'omitnan'), ...
        median(table_group.cbds_return_gap_from_best, 'omitnan'), ...
        ds_overall, cbds_overall, overall_ties, overall_winner, ...
        case_pool, screening_family(groups.problem(i_group)), 0, 0};
end

metrics = cell2table(rows, 'VariableNames', { ...
    'n_runs', 'both', 'ds_only', 'cbds_only', 'neither', ...
    'coverage_contribution_ds', 'classification_stability', ...
    'dominant_classification', 'ds_faster', 'cbds_faster', 'time_ties', ...
    'median_ds_to_cbds_time_ratio', 'iqr_ds_to_cbds_time_ratio', ...
    'median_evaluation_advantage_ds', 'iqr_evaluation_advantage_ds', ...
    'median_best_true_advantage_ds', 'iqr_best_true_advantage_ds', ...
    'median_scaled_best_true_advantage_ds', ...
    'iqr_scaled_best_true_advantage_ds', 'ds_best_true_wins', ...
    'cbds_best_true_wins', 'best_true_ties', ...
    'median_output_true_advantage_ds', 'iqr_output_true_advantage_ds', ...
    'median_ds_return_gap_from_best', 'median_cbds_return_gap_from_best', ...
    'ds_overall_wins', 'cbds_overall_wins', 'overall_ties', ...
    'dominant_overall_ordering', 'case_pool', 'screening_family', ...
    'ds_coverage_rank', 'cbds_coverage_rank'});
problem_table = [groups, metrics];

end

function label = dominant_label(counts, labels)

maximum = max(counts);
if maximum == 0 || sum(counts == maximum) > 1
    label = "mixed_or_tied";
else
    label = labels(find(counts == maximum, 1));
end

end

function label = classify_case_pool(contribution, both, cbds_faster, n_runs)

if contribution >= 3
    label = "late_ds_coverage";
elseif contribution <= -3
    label = "cbds_coverage_counterexample";
elseif both == n_runs && cbds_faster >= n_runs - 1
    label = "both_solved_cbds_faster";
else
    label = "mixed";
end

end

function family = screening_family(problem)

name = char(problem);
if ismember(name, {'INDEF', 'INDEFM', 'FLETCHBV', 'FLETBV3M', ...
        'CURLY10', 'CURLY20', 'CURLY30', 'SCURLY10', 'SCURLY20', ...
        'SCURLY30'})
    family = "unknown_or_unbounded_below";
elseif endsWith(name, 'LS') || startsWith(name, 'PALMER') ...
        || ismember(name, {'EXTROSNB', 'SBRYBND', 'SSBRYBND', ...
        'BRYBND', 'BROYDNBDLS', 'MSQRTALS', 'MSQRTBLS'})
    family = "least_squares_or_residual";
else
    family = "other";
end

end

function problem_table = attach_plain_control(problem_table, control_table)

n_rows = height(problem_table);
plain_classification = strings(n_rows, 1);
plain_time_ordering = strings(n_rows, 1);
plain_best_true_ordering = strings(n_rows, 1);
plain_overall_ordering = strings(n_rows, 1);
plain_best_true_advantage_ds = NaN(n_rows, 1);
rank_reversal_from_plain = false(n_rows, 1);

for i_row = 1:n_rows
    selected = control_table.tau == problem_table.tau(i_row) ...
        & control_table.problem == problem_table.problem(i_row);
    assert(sum(selected) == 1, 'Expected one matching plain control row.');
    control = control_table(selected, :);
    plain_classification(i_row) = control.classification;
    plain_time_ordering(i_row) = control.time_ordering;
    plain_best_true_ordering(i_row) = control.best_true_ordering;
    plain_overall_ordering(i_row) = control.overall_ordering;
    plain_best_true_advantage_ds(i_row) = control.best_true_advantage_ds;
    noisy_ordering = problem_table.dominant_overall_ordering(i_row);
    rank_reversal_from_plain(i_row) = ismember(noisy_ordering, ["ds", "cbds"]) ...
        && ismember(plain_overall_ordering(i_row), ["ds", "cbds"]) ...
        && noisy_ordering ~= plain_overall_ordering(i_row);
end

problem_table.plain_classification = plain_classification;
problem_table.plain_time_ordering = plain_time_ordering;
problem_table.plain_best_true_ordering = plain_best_true_ordering;
problem_table.plain_overall_ordering = plain_overall_ordering;
problem_table.plain_best_true_advantage_ds = plain_best_true_advantage_ds;
problem_table.rank_reversal_from_plain = rank_reversal_from_plain;

end

function problem_table = add_ranks(problem_table)

problem_table.cbds_speed_rank = zeros(height(problem_table), 1);
pair_keys = unique(problem_table(:, {'feature', 'sigma', 'tau'}), 'rows', 'stable');
for i_pair = 1:height(pair_keys)
    selected = problem_table.feature == pair_keys.feature(i_pair) ...
        & problem_table.tau == pair_keys.tau(i_pair);
    indices = find(selected);
    pair = problem_table(selected, :);

    [~, order] = sortrows(pair, ...
        {'coverage_contribution_ds', 'classification_stability', 'ds_only', ...
        'median_scaled_best_true_advantage_ds'}, ...
        {'descend', 'descend', 'descend', 'descend'});
    problem_table.ds_coverage_rank(indices(order)) = (1:numel(indices))';

    [~, order] = sortrows(pair, ...
        {'coverage_contribution_ds', 'classification_stability', 'cbds_only', ...
        'median_scaled_best_true_advantage_ds'}, ...
        {'ascend', 'descend', 'descend', 'ascend'});
    problem_table.cbds_coverage_rank(indices(order)) = (1:numel(indices))';

    pair.cbds_speed_margin = pair.cbds_faster - pair.ds_faster;
    [~, order] = sortrows(pair, ...
        {'cbds_speed_margin', 'both', 'median_ds_to_cbds_time_ratio', ...
        'classification_stability'}, ...
        {'descend', 'descend', 'descend', 'descend'});
    problem_table.cbds_speed_rank(indices(order)) = (1:numel(indices))';
end

problem_table = sortrows(problem_table, ...
    {'sigma', 'tau', 'ds_coverage_rank'}, {'descend', 'descend', 'ascend'});

end

function pair_summary = summarize_pairs(run_table, problem_table)

pair_keys = unique(run_table(:, {'feature', 'sigma', 'tau'}), 'rows', 'stable');
rows = cell(height(pair_keys), 17);
for i_pair = 1:height(pair_keys)
    selected_runs = run_table.feature == pair_keys.feature(i_pair) ...
        & run_table.tau == pair_keys.tau(i_pair);
    selected_problems = problem_table.feature == pair_keys.feature(i_pair) ...
        & problem_table.tau == pair_keys.tau(i_pair);
    runs = run_table(selected_runs, :);
    problems = problem_table(selected_problems, :);
    contributions = problems.coverage_contribution_ds;
    positive_total = sum(contributions(contributions > 0));
    negative_total = -sum(contributions(contributions < 0));
    sorted_positive = sort(contributions(contributions > 0), 'descend');
    top_five_positive = sum(sorted_positive(1:min(5, numel(sorted_positive))));
    rows(i_pair, :) = {height(runs), sum(runs.classification == "both"), ...
        sum(runs.classification == "ds_only"), ...
        sum(runs.classification == "cbds_only"), ...
        sum(runs.classification == "neither"), ...
        sum(runs.time_ordering == "ds"), sum(runs.time_ordering == "cbds"), ...
        sum(runs.time_ordering == "tie"), ...
        sum(contributions > 0), sum(contributions < 0), sum(contributions == 0), ...
        sum(contributions >= 3), sum(contributions <= -3), ...
        positive_total, negative_total, positive_total - negative_total, ...
        top_five_positive / max(1, positive_total)};
end

metrics = cell2table(rows, 'VariableNames', { ...
    'n_problem_runs', 'both', 'ds_only', 'cbds_only', 'neither', ...
    'ds_faster', 'cbds_faster', 'time_ties', ...
    'problems_net_ds_coverage', 'problems_net_cbds_coverage', ...
    'problems_zero_net_coverage', 'stable_ds_coverage_candidates', ...
    'stable_cbds_coverage_candidates', 'positive_coverage_runs', ...
    'negative_coverage_runs', 'net_coverage_runs_ds', ...
    'top_five_share_of_positive_ds_coverage'});
pair_summary = [pair_keys, metrics];

end

function family_summary = summarize_families(problem_table)

keys = unique(problem_table(:, ...
    {'feature', 'sigma', 'tau', 'screening_family'}), 'rows', 'stable');
rows = cell(height(keys), 10);
for i_group = 1:height(keys)
    selected = problem_table.feature == keys.feature(i_group) ...
        & problem_table.tau == keys.tau(i_group) ...
        & problem_table.screening_family == keys.screening_family(i_group);
    family = problem_table(selected, :);
    contribution = family.coverage_contribution_ds;
    positive = sum(contribution(contribution > 0));
    negative = -sum(contribution(contribution < 0));
    rows(i_group, :) = {height(family), sum(contribution > 0), ...
        sum(contribution < 0), sum(contribution == 0), ...
        sum(contribution >= 3), sum(contribution <= -3), ...
        positive, negative, positive - negative, ...
        sum(family.rank_reversal_from_plain)};
end

metrics = cell2table(rows, 'VariableNames', { ...
    'n_problems', 'problems_net_ds_coverage', ...
    'problems_net_cbds_coverage', 'problems_zero_net_coverage', ...
    'stable_ds_coverage_candidates', 'stable_cbds_coverage_candidates', ...
    'positive_coverage_runs', 'negative_coverage_runs', ...
    'net_coverage_runs_ds', 'rank_reversals_from_plain'});
family_summary = [keys, metrics];

end

function transition_summary = summarize_transitions(run_table)

specs = struct( ...
    'name', {'lower_noise_at_tau_1e-1', 'stricter_tau_at_sigma_1e-2'}, ...
    'from_feature', {'noisy_1e-1', 'noisy_1e-2'}, ...
    'from_sigma', {1e-1, 1e-2}, ...
    'from_tau', {1e-1, 1e-1}, ...
    'to_feature', {'noisy_1e-2', 'noisy_1e-2'}, ...
    'to_sigma', {1e-2, 1e-2}, ...
    'to_tau', {1e-1, 1e-2});
rows = cell(16 * numel(specs), 13);
row = 0;

for i_spec = 1:numel(specs)
    spec = specs(i_spec);
    from = run_table(run_table.feature == spec.from_feature ...
        & run_table.tau == spec.from_tau, :);
    to = run_table(run_table.feature == spec.to_feature ...
        & run_table.tau == spec.to_tau, :);
    from = sortrows(from, {'problem', 'run'});
    to = sortrows(to, {'problem', 'run'});
    assert(height(from) == height(to) ...
        && isequal(from.problem, to.problem) && isequal(from.run, to.run), ...
        'Transition tables do not contain the same paired problem-runs.');

    transition = from.classification + "_to_" + to.classification;
    labels = unique(transition, 'stable');
    for i_label = 1:numel(labels)
        selected = transition == labels(i_label);
        from_contribution = sum(from.coverage_contribution_ds(selected));
        to_contribution = sum(to.coverage_contribution_ds(selected));
        row = row + 1;
        rows(row, :) = {string(spec.name), string(spec.from_feature), ...
            spec.from_sigma, spec.from_tau, string(spec.to_feature), ...
            spec.to_sigma, spec.to_tau, labels(i_label), sum(selected), ...
            numel(unique(from.problem(selected))), from_contribution, ...
            to_contribution, to_contribution - from_contribution};
    end
end
rows = rows(1:row, :);

transition_summary = cell2table(rows, 'VariableNames', { ...
    'comparison', 'from_feature', 'from_sigma', 'from_tau', ...
    'to_feature', 'to_sigma', 'to_tau', 'transition', ...
    'n_problem_runs', 'n_problems', 'from_coverage_contribution_ds', ...
    'to_coverage_contribution_ds', 'net_coverage_change_ds'});

end

function validate_against_profile_decomposition(noise_matched_dir, pair_summary)

reference_file = fullfile(noise_matched_dir, ...
    'noise_matched_profiles', 'noise_matched_pair_summary.csv');
reference = readtable(reference_file, 'TextType', 'string');
reference = reference(reference.role == "primary", :);

for i_pair = 1:height(pair_summary)
    selected = reference.feature == pair_summary.feature(i_pair) ...
        & abs(reference.tau - pair_summary.tau(i_pair)) < 10 * eps;
    assert(sum(selected) == 1, 'Missing primary reference pair.');
    row = reference(selected, :);
    assert(pair_summary.both(i_pair) == row.both_solved_runs ...
        && pair_summary.ds_only(i_pair) == row.ds_only_runs ...
        && pair_summary.cbds_only(i_pair) == row.cbds_only_runs ...
        && pair_summary.neither(i_pair) == row.neither_runs ...
        && pair_summary.ds_faster(i_pair) == row.ds_faster_runs ...
        && pair_summary.cbds_faster(i_pair) == row.cbds_faster_runs ...
        && pair_summary.time_ties(i_pair) == row.time_tie_runs, ...
        'Stage 4 decomposition disagrees with the profile analysis.');
end

end

function value = robust_iqr(values)

values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = iqr(values);
end

end

function index = find_first_or_nan(mask)

index = find(mask, 1, 'first');
if isempty(index)
    index = NaN;
end

end

function write_report(analysis, output_file)

fid = fopen(output_file, 'w');
cleanup = onCleanup(@() fclose(fid));
summary = analysis.pair_summary;
ranking = analysis.problem_ranking;
family = analysis.family_summary;
transitions = analysis.transition_summary;

fprintf(fid, '# Noise-Matched Problem-Level Ranking\n\n');
fprintf(fid, 'Generated: %s\n\n', analysis.created);
fprintf(fid, '本报告只使用三个 primary `(sigma, tau)` pairs，并以 single-tau ');
fprintf(fid, '`eventual coverage` 和 `time-to-target` 为主，不使用十个 tau 的平均 score。\n\n');

fprintf(fid, '## Data Boundary\n\n');
fprintf(fid, '- `fun_histories` 保存每个 evaluated point 的 true objective value。\n');
fprintf(fid, '- `fun_outs` 保存 returned point 的 true objective value。\n');
fprintf(fid, '- Stage 3 aggregate MAT 不保存 solver 实际观察到的 noisy values；因此本阶段');
fprintf(fid, '不能恢复 `best observed noisy value`，该量将在 instrumented replay 中记录。\n');
fprintf(fid, '- `best_true_advantage_ds = CBDS best true - DS best true`；正值表示 DS 更好。\n');
fprintf(fid, '- `evaluation_advantage_ds = T_CBDS - T_DS`；正值表示 DS 更快。\n\n');

fprintf(fid, '## Pair-Level Concentration\n\n');
fprintf(fid, '| Feature | tau | Net run coverage DS | Problems net DS/CBDS/zero | ');
fprintf(fid, 'Stable DS/CBDS pools | Top-5 share of positive DS coverage |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: |\n');
for i_pair = 1:height(summary)
    fprintf(fid, '| `%s` | `%.0e` | %+d | %d/%d/%d | %d/%d | %.3f |\n', ...
        summary.feature(i_pair), summary.tau(i_pair), ...
        summary.net_coverage_runs_ds(i_pair), ...
        summary.problems_net_ds_coverage(i_pair), ...
        summary.problems_net_cbds_coverage(i_pair), ...
        summary.problems_zero_net_coverage(i_pair), ...
        summary.stable_ds_coverage_candidates(i_pair), ...
        summary.stable_cbds_coverage_candidates(i_pair), ...
        summary.top_five_share_of_positive_ds_coverage(i_pair));
end
fprintf(fid, '\n`Stable pool` 在这里只表示五次 runs 中净 coverage contribution 的绝对值');
fprintf(fid, '至少为 3；它是 Stage 5 的候选池，不是最终 case selection。\n\n');

fprintf(fid, '## Provisional Family Accounting\n\n');
fprintf(fid, '| Feature | tau | Screening family | Problems | Positive/negative runs | Net DS coverage |\n');
fprintf(fid, '| --- | ---: | --- | ---: | ---: | ---: |\n');
for i_row = 1:height(family)
    fprintf(fid, '| `%s` | `%.0e` | `%s` | %d | %d/%d | %+d |\n', ...
        family.feature(i_row), family.tau(i_row), ...
        family.screening_family(i_row), family.n_problems(i_row), ...
        family.positive_coverage_runs(i_row), ...
        family.negative_coverage_runs(i_row), ...
        family.net_coverage_runs_ds(i_row));
end
fprintf(fid, '\n该 family label 只用于 Stage 4 screening。尤其是 ');
fprintf(fid, '`unknown_or_unbounded_below` 必须在 Stage 8 由 authoritative definition ');
fprintf(fid, '核验，不能仅凭名字作数学结论。\n\n');

fprintf(fid, '## Classification Transitions\n\n');
fprintf(fid, '| Comparison | Transition | Problem-runs | Problems | Net DS coverage change |\n');
fprintf(fid, '| --- | --- | ---: | ---: | ---: |\n');
for i_row = 1:height(transitions)
    fprintf(fid, '| `%s` | `%s` | %d | %d | %+d |\n', ...
        transitions.comparison(i_row), transitions.transition(i_row), ...
        transitions.n_problem_runs(i_row), transitions.n_problems(i_row), ...
        transitions.net_coverage_change_ds(i_row));
end
fprintf(fid, '\n当 `sigma=1e-2` 固定而 tau 从 `1e-1` 收紧到 `1e-2` 时，');
fprintf(fid, '`92` 个 runs 从 `both` 变成 `CBDS-only`，只有 `36` 个 runs 从 ');
fprintf(fid, '`both` 变成 `DS-only`，恰好解释净 coverage 从 `+37` 变为 `-19` ');
fprintf(fid, '的 `-56` 变化。原有的 `71 DS-only` 和 `34 CBDS-only` runs 全部保持');
fprintf(fid, '原分类；所以反超消失不是 DS-positive cases 消失，而是 stricter target ');
fprintf(fid, '在原本 both-solved 的集合中产生了更多新的 CBDS-only runs。\n\n');

for i_pair = 1:height(summary)
    selected = ranking.feature == summary.feature(i_pair) ...
        & ranking.tau == summary.tau(i_pair);
    pair = ranking(selected, :);
    fprintf(fid, '## %s, tau = %.0e\n\n', ...
        summary.feature(i_pair), summary.tau(i_pair));
    write_rank_table(fid, pair, "ds_coverage_rank", ...
        'Largest DS late-coverage contributions');
    write_rank_table(fid, pair, "cbds_coverage_rank", ...
        'Largest CBDS coverage counterexamples');
    write_rank_table(fid, pair, "cbds_speed_rank", ...
        'Strongest both-solved CBDS early-efficiency cases');
end

fprintf(fid, '## Ranking Interpretation\n\n');
fprintf(fid, '- `coverage rank` 首先按 `DS-only - CBDS-only` 排序，再用 five-run ');
fprintf(fid, 'classification stability 和 true-value gap 打破并列。\n');
fprintf(fid, '- `CBDS speed rank` 首先按 `CBDS-faster - DS-faster` 排序，再看 ');
fprintf(fid, '`both solved` 数量和 median `T_DS/T_CBDS`。\n');
fprintf(fid, '- `rank_reversal_from_plain` 使用同一 tau 的 plain run 作为 control；');
fprintf(fid, '每个 run 先比较 coverage，双方都 solved 时再比较 hitting time。\n');
fprintf(fid, '- `screening_family` 只是按问题名称做的预筛分类，不替代后续对 ');
fprintf(fid, 'authoritative S2MPJ objective expression 的核查。\n');

end

function write_rank_table(fid, pair, rank_name, title_text)

rank_name = char(rank_name);
pair = sortrows(pair, rank_name, 'ascend');
n_show = min(10, height(pair));
fprintf(fid, '### %s\n\n', title_text);
fprintf(fid, '| Problem | n | Both/DS-only/CBDS-only | DS/CBDS faster | ');
fprintf(fid, 'Median T ratio | Median true advantage DS | Plain ordering | Reversal |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: | --- | --- |\n');
for i_row = 1:n_show
    fprintf(fid, '| `%s` | %d | %d/%d/%d | %d/%d | %.4g | %.4g | `%s` | %s |\n', ...
        pair.problem(i_row), pair.n(i_row), pair.both(i_row), ...
        pair.ds_only(i_row), pair.cbds_only(i_row), pair.ds_faster(i_row), ...
        pair.cbds_faster(i_row), pair.median_ds_to_cbds_time_ratio(i_row), ...
        pair.median_best_true_advantage_ds(i_row), ...
        pair.plain_overall_ordering(i_row), ...
        yes_no(pair.rank_reversal_from_plain(i_row)));
end
fprintf(fid, '\n');

end

function text = yes_no(value)

if value
    text = 'yes';
else
    text = 'no';
end

end
