function analysis_file = analyze_ds_vs_cbds_noise_matched_profiles(manifest_file)
%ANALYZE_DS_VS_CBDS_NOISE_MATCHED_PROFILES analyzes relevant practical tolerances.

if nargin < 1 || isempty(manifest_file)
    path_tests = fileparts(mfilename('fullpath'));
    listing = dir(fullfile(path_tests, 'testdata', 'ds_vs_cbds_high_noise_primary_*', ...
        'aggregate_manifest.mat'));
    if isempty(listing)
        error('No primary aggregate manifest was found.');
    end
    [~, index] = max([listing.datenum]);
    manifest_file = fullfile(listing(index).folder, listing(index).name);
end

loaded = load(manifest_file, 'manifest');
manifest = loaded.manifest;
output_dir = fullfile(fileparts(manifest_file), 'analysis', 'noise_matched_profiles');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

pair_specs = struct( ...
    'feature', {'noisy_1e-1', 'noisy_1e-2', 'noisy_1e-2', 'plain', 'plain'}, ...
    'sigma', {1e-1, 1e-2, 1e-2, NaN, NaN}, ...
    'tau', {1e-1, 1e-1, 1e-2, 1e-1, 1e-2}, ...
    'role', {'primary', 'primary', 'primary', 'control', 'control'});
normalized_budget_grid = [1, 2, 4, 8, 16, 32, 64, 100, 150, 200];

pair_tables = cell(numel(pair_specs), 1);
run_tables = cell(numel(pair_specs), 1);
problem_tables = cell(numel(pair_specs), 1);
budget_tables = cell(numel(pair_specs), 1);

for i_pair = 1:numel(pair_specs)
    spec = pair_specs(i_pair);
    entry = find_feature(manifest, spec.feature);
    data = load(entry.data_file, 'results_plibs');
    assert(isscalar(data.results_plibs), 'Expected one problem library in %s.', entry.data_file);
    results = data.results_plibs{1};

    [work, thresholds] = work_at_tolerance(results, spec.tau);
    profile_score = entry.profile_scores(:, tolerance_index(spec.tau), 1, 1);
    [pair_table, budget_table] = summarize_pair( ...
        spec, results, work, profile_score, normalized_budget_grid);
    run_table = make_run_table(spec, results, work, thresholds);
    problem_table = make_problem_table(run_table);

    pair_tables{i_pair} = pair_table;
    run_tables{i_pair} = run_table;
    problem_tables{i_pair} = problem_table;
    budget_tables{i_pair} = budget_table;
end

pair_summary = vertcat(pair_tables{:});
run_decomposition = vertcat(run_tables{:});
problem_decomposition = vertcat(problem_tables{:});
budget_coverage = vertcat(budget_tables{:});
all_tau_diagnostic = make_all_tau_diagnostic(manifest);

writetable(pair_summary, fullfile(output_dir, 'noise_matched_pair_summary.csv'));
writetable(run_decomposition, fullfile(output_dir, 'noise_matched_run_decomposition.csv'));
writetable(problem_decomposition, fullfile(output_dir, 'noise_matched_problem_decomposition.csv'));
writetable(budget_coverage, fullfile(output_dir, 'noise_matched_budget_coverage.csv'));
writetable(all_tau_diagnostic, fullfile(output_dir, 'all_tau_average_diagnostic.csv'));

analysis = struct();
analysis.created = char(datetime('now'));
analysis.manifest_file = manifest_file;
analysis.primary_rule = 'tau >= sigma';
analysis.pair_summary = pair_summary;
analysis.run_decomposition = run_decomposition;
analysis.problem_decomposition = problem_decomposition;
analysis.budget_coverage = budget_coverage;
analysis.all_tau_diagnostic = all_tau_diagnostic;
analysis_file = fullfile(output_dir, 'noise_matched_profile_analysis.mat');
save(analysis_file, 'analysis', '-v7.3');
write_report(analysis, fullfile(output_dir, 'noise_matched_profile_analysis.md'));

fprintf('Noise-matched profile analysis: %s\n', analysis_file);

end

function entry = find_feature(manifest, feature_name)

index = find(strcmp({manifest.features.name}, feature_name), 1);
if isempty(index)
    error('Feature %s is missing from the manifest.', feature_name);
end
entry = manifest.features(index);

end

function index = tolerance_index(tau)

index = round(-log10(tau));
if index < 1 || index > 10 || abs(tau - 10^(-index)) > 10 * eps
    error('Tolerance %.16g is not one of 1e-1 through 1e-10.', tau);
end

end

function [work, thresholds] = work_at_tolerance(results, tau)

n_problems = numel(results.problem_names);
n_solvers = numel(results.solver_names);
n_runs = size(results.fun_histories, 3);
work = NaN(n_problems, n_solvers, n_runs);
thresholds = NaN(n_problems, n_runs);

for i_problem = 1:n_problems
    for i_run = 1:n_runs
        init_value = results.fun_inits(i_problem, min(i_run, size(results.fun_inits, 2)));
        best_values = NaN(n_solvers, 1);
        histories = cell(n_solvers, 1);
        for i_solver = 1:n_solvers
            nf = results.n_evals(i_problem, i_solver, i_run);
            history = squeeze(results.fun_histories(i_problem, i_solver, i_run, 1:nf));
            histories{i_solver} = history;
            best_values(i_solver) = min(history, [], 'omitnan');
        end
        reference_min = min([best_values; init_value], [], 'omitnan');
        if isinf(init_value)
            threshold = Inf;
        elseif isfinite(reference_min)
            threshold = max(tau * init_value + (1 - tau) * reference_min, reference_min);
        else
            threshold = -Inf;
        end
        thresholds(i_problem, i_run) = threshold;
        for i_solver = 1:n_solvers
            work(i_problem, i_solver, i_run) = find_first_or_nan( ...
                histories{i_solver} <= threshold);
        end
    end
end

end

function [summary, budget_table] = summarize_pair(spec, results, work, profile_score, budget_grid)

n_problem_runs = size(work, 1) * size(work, 3);
ds_solved = squeeze(isfinite(work(:, 1, :)));
cbds_solved = squeeze(isfinite(work(:, 2, :)));
both = ds_solved & cbds_solved;
ds_only = ds_solved & ~cbds_solved;
cbds_only = ~ds_solved & cbds_solved;
neither = ~ds_solved & ~cbds_solved;

work_ds = squeeze(work(:, 1, :));
work_cbds = squeeze(work(:, 2, :));
time_ratio = work_ds ./ work_cbds;
ds_faster = both & work_ds < work_cbds;
cbds_faster = both & work_cbds < work_ds;
time_ties = both & work_ds == work_cbds;

denominator = min(work, [], 2, 'omitnan');
performance_ratio = work ./ denominator;
problem_dims = reshape(results.problem_dims, [], 1, 1);
data_ratio = work ./ (problem_dims + 1);

perf_metrics = profile_metrics(performance_ratio, 1);
data_metrics = profile_metrics(data_ratio, 0);

feature = string(spec.feature);
role = string(spec.role);
sigma = spec.sigma;
tau = spec.tau;
ds_profile_score = profile_score(1);
cbds_profile_score = profile_score(2);
ds_rho1_coverage = coverage_at(performance_ratio(:, 1, :), 1);
cbds_rho1_coverage = coverage_at(performance_ratio(:, 2, :), 1);
ds_final_coverage = sum(ds_solved(:)) / n_problem_runs;
cbds_final_coverage = sum(cbds_solved(:)) / n_problem_runs;
ds_solved_runs = sum(ds_solved(:));
cbds_solved_runs = sum(cbds_solved(:));
both_solved_runs = sum(both(:));
ds_only_runs = sum(ds_only(:));
cbds_only_runs = sum(cbds_only(:));
neither_runs = sum(neither(:));
ds_faster_runs = sum(ds_faster(:));
cbds_faster_runs = sum(cbds_faster(:));
time_tie_runs = sum(time_ties(:));
median_ds_to_cbds_time = median(time_ratio(both), 'omitnan');
performance_sustained_crossing = perf_metrics.sustained_crossing;
data_sustained_crossing = data_metrics.sustained_crossing;
ds_performance_last_gain = perf_metrics.last_gain(1);
cbds_performance_last_gain = perf_metrics.last_gain(2);
ds_data_last_gain = data_metrics.last_gain(1);
cbds_data_last_gain = data_metrics.last_gain(2);
ds_data_within_one_pct_final = data_metrics.within_one_pct_final(1);
cbds_data_within_one_pct_final = data_metrics.within_one_pct_final(2);

summary = table(feature, role, sigma, tau, n_problem_runs, ...
    ds_profile_score, cbds_profile_score, ds_rho1_coverage, cbds_rho1_coverage, ...
    ds_final_coverage, cbds_final_coverage, ds_solved_runs, cbds_solved_runs, ...
    both_solved_runs, ds_only_runs, cbds_only_runs, neither_runs, ...
    ds_faster_runs, cbds_faster_runs, time_tie_runs, median_ds_to_cbds_time, ...
    performance_sustained_crossing, data_sustained_crossing, ...
    ds_performance_last_gain, cbds_performance_last_gain, ...
    ds_data_last_gain, cbds_data_last_gain, ...
    ds_data_within_one_pct_final, cbds_data_within_one_pct_final);

budget_feature = repmat(feature, numel(budget_grid), 1);
budget_role = repmat(role, numel(budget_grid), 1);
budget_sigma = repmat(sigma, numel(budget_grid), 1);
budget_tau = repmat(tau, numel(budget_grid), 1);
normalized_budget = budget_grid(:);
ds_coverage = arrayfun(@(value) coverage_at(data_ratio(:, 1, :), value), budget_grid(:));
cbds_coverage = arrayfun(@(value) coverage_at(data_ratio(:, 2, :), value), budget_grid(:));
budget_table = table(budget_feature, budget_role, budget_sigma, budget_tau, ...
    normalized_budget, ds_coverage, cbds_coverage, ...
    'VariableNames', {'feature', 'role', 'sigma', 'tau', 'normalized_budget', ...
    'ds_coverage', 'cbds_coverage'});

end

function metrics = profile_metrics(ratio, minimum_axis_value)

n_solvers = size(ratio, 2);
event_grid = unique(ratio(isfinite(ratio)));
event_grid = event_grid(event_grid >= minimum_axis_value);
if isempty(event_grid)
    event_grid = minimum_axis_value;
end
coverage = zeros(numel(event_grid), n_solvers);
for i_solver = 1:n_solvers
    solver_ratio = ratio(:, i_solver, :);
    for i_event = 1:numel(event_grid)
        coverage(i_event, i_solver) = coverage_at(solver_ratio, event_grid(i_event));
    end
end

strictly_above = coverage(:, 1) > coverage(:, 2) + 10 * eps;
sustained_index = find(arrayfun(@(index) all(strictly_above(index:end)), ...
    (1:numel(event_grid))'), 1);
if isempty(sustained_index)
    sustained_crossing = NaN;
else
    sustained_crossing = event_grid(sustained_index);
end

last_gain = NaN(1, n_solvers);
within_one_pct_final = NaN(1, n_solvers);
for i_solver = 1:n_solvers
    solver_ratio = ratio(:, i_solver, :);
    finite_ratio = solver_ratio(isfinite(solver_ratio));
    if ~isempty(finite_ratio)
        last_gain(i_solver) = max(finite_ratio);
    end
    final_coverage = coverage(end, i_solver);
    threshold = max(0, final_coverage - 0.01);
    index = find(coverage(:, i_solver) >= threshold - 10 * eps, 1);
    if ~isempty(index)
        within_one_pct_final(i_solver) = event_grid(index);
    end
end

metrics = struct();
metrics.sustained_crossing = sustained_crossing;
metrics.last_gain = last_gain;
metrics.within_one_pct_final = within_one_pct_final;

end

function fraction = coverage_at(ratio, limit)

fraction = sum(ratio(:) <= limit) / numel(ratio);

end

function run_table = make_run_table(spec, results, work, thresholds)

n_problems = numel(results.problem_names);
n_runs = size(work, 3);
n_rows = n_problems * n_runs;
feature = repmat(string(spec.feature), n_rows, 1);
role = repmat(string(spec.role), n_rows, 1);
sigma = repmat(spec.sigma, n_rows, 1);
tau = repmat(spec.tau, n_rows, 1);
problem = strings(n_rows, 1);
n = zeros(n_rows, 1);
run = zeros(n_rows, 1);
run_seed = zeros(n_rows, 1);
threshold = NaN(n_rows, 1);
ds_work = NaN(n_rows, 1);
cbds_work = NaN(n_rows, 1);
classification = strings(n_rows, 1);
time_ordering = strings(n_rows, 1);

row = 0;
for i_problem = 1:n_problems
    for i_run = 1:n_runs
        row = row + 1;
        problem(row) = results.problem_names{i_problem};
        n(row) = results.problem_dims(i_problem);
        run(row) = i_run;
        run_seed(row) = 211 * i_run;
        threshold(row) = thresholds(i_problem, i_run);
        ds_work(row) = work(i_problem, 1, i_run);
        cbds_work(row) = work(i_problem, 2, i_run);
        classification(row) = classify_solved(ds_work(row), cbds_work(row));
        time_ordering(row) = classify_time(ds_work(row), cbds_work(row));
    end
end

run_table = table(feature, role, sigma, tau, problem, n, run, run_seed, ...
    threshold, ds_work, cbds_work, classification, time_ordering);

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
    label = "ds_faster";
elseif cbds_work < ds_work
    label = "cbds_faster";
else
    label = "tie";
end

end

function problem_table = make_problem_table(run_table)

groups = unique(run_table(:, {'feature', 'role', 'sigma', 'tau', 'problem', 'n'}), ...
    'rows', 'stable');
n_groups = height(groups);
both = zeros(n_groups, 1);
ds_only = zeros(n_groups, 1);
cbds_only = zeros(n_groups, 1);
neither = zeros(n_groups, 1);
ds_faster = zeros(n_groups, 1);
cbds_faster = zeros(n_groups, 1);
time_ties = zeros(n_groups, 1);
median_ds_to_cbds_time = NaN(n_groups, 1);

for i_group = 1:n_groups
    selected = run_table.feature == groups.feature(i_group) ...
        & run_table.tau == groups.tau(i_group) ...
        & run_table.problem == groups.problem(i_group);
    rows = run_table(selected, :);
    both(i_group) = sum(rows.classification == "both");
    ds_only(i_group) = sum(rows.classification == "ds_only");
    cbds_only(i_group) = sum(rows.classification == "cbds_only");
    neither(i_group) = sum(rows.classification == "neither");
    ds_faster(i_group) = sum(rows.time_ordering == "ds_faster");
    cbds_faster(i_group) = sum(rows.time_ordering == "cbds_faster");
    time_ties(i_group) = sum(rows.time_ordering == "tie");
    both_rows = rows.classification == "both";
    median_ds_to_cbds_time(i_group) = median( ...
        rows.ds_work(both_rows) ./ rows.cbds_work(both_rows), 'omitnan');
end

coverage_contribution_ds = ds_only - cbds_only;
problem_table = [groups, table(both, ds_only, cbds_only, neither, ds_faster, ...
    cbds_faster, time_ties, median_ds_to_cbds_time, coverage_contribution_ds)];

end

function diagnostic = make_all_tau_diagnostic(manifest)

n_features = numel(manifest.features);
feature = strings(n_features, 1);
ds_all_tau_score = zeros(n_features, 1);
cbds_all_tau_score = zeros(n_features, 1);
for i_feature = 1:n_features
    feature(i_feature) = manifest.features(i_feature).name;
    scores = manifest.features(i_feature).solver_scores;
    ds_all_tau_score(i_feature) = scores(1);
    cbds_all_tau_score(i_feature) = scores(2);
end
diagnostic = table(feature, ds_all_tau_score, cbds_all_tau_score);

end

function index = find_first_or_nan(mask)

index = find(mask, 1);
if isempty(index)
    index = NaN;
end

end


function write_report(analysis, output_file)

fid = fopen(output_file, 'w');
cleanup = onCleanup(@() fclose(fid));
summary = analysis.pair_summary;
budget = analysis.budget_coverage;

fprintf(fid, '# Noise-Matched DS vs CBDS Profile Analysis\n\n');
fprintf(fid, 'Generated: %s\n\n', analysis.created);
fprintf(fid, 'Primary rule: analyze practical tolerances satisfying `tau >= sigma`. ');
fprintf(fid, 'The ten-tolerance average score is retained only as a diagnostic.\n\n');

fprintf(fid, '## Pair Summary\n\n');
fprintf(fid, '| Feature | tau | Role | Profile score DS/CBDS | Coverage at rho=1 DS/CBDS | Final coverage DS/CBDS | Both | DS-only | CBDS-only | Sustained crossing perf/data |\n');
fprintf(fid, '| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:height(summary)
    fprintf(fid, '| `%s` | `%.0e` | `%s` | %.6f / %.6f | %.6f / %.6f | %.6f / %.6f | %d | %d | %d | %s / %s |\n', ...
        summary.feature(i), summary.tau(i), summary.role(i), ...
        summary.ds_profile_score(i), summary.cbds_profile_score(i), ...
        summary.ds_rho1_coverage(i), summary.cbds_rho1_coverage(i), ...
        summary.ds_final_coverage(i), summary.cbds_final_coverage(i), ...
        summary.both_solved_runs(i), summary.ds_only_runs(i), summary.cbds_only_runs(i), ...
        format_number(summary.performance_sustained_crossing(i)), ...
        format_number(summary.data_sustained_crossing(i)));
end

fprintf(fid, '\n## Early Efficiency Among Both-Solved Runs\n\n');
fprintf(fid, '| Feature | tau | DS faster | CBDS faster | Ties | Median T_DS/T_CBDS |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:height(summary)
    fprintf(fid, '| `%s` | `%.0e` | %d | %d | %d | %.6g |\n', ...
        summary.feature(i), summary.tau(i), summary.ds_faster_runs(i), ...
        summary.cbds_faster_runs(i), summary.time_tie_runs(i), ...
        summary.median_ds_to_cbds_time(i));
end

fprintf(fid, '\n## Data-Profile Coverage\n\n');
primary = summary.role == "primary";
primary_summary = summary(primary, :);
for i = 1:height(primary_summary)
    selected = budget.feature == primary_summary.feature(i) ...
        & budget.tau == primary_summary.tau(i);
    rows = budget(selected, :);
    fprintf(fid, '### %s, tau = %.0e\n\n', primary_summary.feature(i), primary_summary.tau(i));
    fprintf(fid, '| Evaluations/(n+1) | DS | CBDS | DS minus CBDS |\n');
    fprintf(fid, '| ---: | ---: | ---: | ---: |\n');
    for j = 1:height(rows)
        fprintf(fid, '| %g | %.6f | %.6f | %+.6f |\n', ...
            rows.normalized_budget(j), rows.ds_coverage(j), rows.cbds_coverage(j), ...
            rows.ds_coverage(j) - rows.cbds_coverage(j));
    end
    fprintf(fid, '\n');
end

fprintf(fid, '## Interpretation Boundary\n\n');
fprintf(fid, '- A performance-profile plateau means no additional solved cases appear as the allowed relative evaluation ratio grows.\n');
fprintf(fid, '- A data-profile plateau means no additional solved cases appear as normalized absolute budget grows.\n');
fprintf(fid, '- Neither statement alone proves that every objective trajectory stopped improving; that requires the instrumented histories in later stages.\n');
fprintf(fid, '- A profile-area score combines early efficiency and eventual coverage. It must not replace reporting both quantities separately.\n');

end

function text = format_number(value)

if isnan(value)
    text = 'none';
else
    text = sprintf('%.6g', value);
end

end
