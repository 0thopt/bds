function analysis_file = analyze_ds_vs_cbds_high_noise_aggregate(manifest_file)
%ANALYZE_DS_VS_CBDS_HIGH_NOISE_AGGREGATE computes the all-tolerance diagnostic.
%
% The primary high-noise investigation uses
% analyze_ds_vs_cbds_noise_matched_profiles. This function averages profile
% scores over tau = 1e-1,...,1e-10 and must not drive case selection.

if nargin < 1 || isempty(manifest_file)
    path_tests = fileparts(mfilename('fullpath'));
    listing = dir(fullfile(path_tests, 'testdata', 'ds_vs_cbds_high_noise_*', ...
        'aggregate_manifest.mat'));
    if isempty(listing)
        error('No aggregate_manifest.mat was found.');
    end
    [~, index] = max([listing.datenum]);
    manifest_file = fullfile(listing(index).folder, listing(index).name);
end

loaded = load(manifest_file, 'manifest');
manifest = loaded.manifest;
output_dir = fullfile(fileparts(manifest_file), 'analysis');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

analysis = struct();
analysis.manifest_file = manifest_file;
analysis.created = char(datetime('now'));
analysis.features = struct('name', {}, 'solver_names', {}, 'problem_table', {}, ...
    'run_table', {}, 'full_scores', {}, 'saved_scores', {}, 'full_gap', {}, ...
    'filtered_scores', {});

for i_feature = 1:numel(manifest.features)
    entry = manifest.features(i_feature);
    loaded_data = load(entry.data_file, 'results_plibs');
    if numel(loaded_data.results_plibs) ~= 1
        error('Expected exactly one problem library in %s.', entry.data_file);
    end
    results = loaded_data.results_plibs{1};
    solver_names = results.solver_names;
    if numel(solver_names) ~= 2
        error('Expected exactly two solvers in %s.', entry.data_file);
    end

    [problem_table, run_table, work_all] = decompose_results(results);
    full_scores = performance_scores_from_work(work_all);
    saved_scores = entry.solver_scores(:);
    score_error = max(abs(full_scores - saved_scores));
    if score_error > 2e-10
        error('Recomputed scores for %s differ from OptiProfiler by %.3e.', ...
            entry.name, score_error);
    end

    full_gap = full_scores(1) - full_scores(2);
    contribution = zeros(height(problem_table), 1);
    for i_problem = 1:height(problem_table)
        keep = true(height(problem_table), 1);
        keep(i_problem) = false;
        loo_scores = performance_scores_from_work(work_all(keep, :, :, :));
        contribution(i_problem) = full_gap - (loo_scores(1) - loo_scores(2));
    end
    problem_table.profile_gap_contribution = contribution;
    problem_table.family_flag = cellfun(@classify_problem, ...
        problem_table.problem, 'UniformOutput', false);
    filtered = filtered_score_summary(problem_table, work_all, full_scores);
    problem_table = sortrows(problem_table, ...
        {'profile_gap_contribution', 'median_best_true_advantage_ds'}, {'descend', 'descend'});

    feature_slug = strrep(entry.name, '-', '_');
    problem_csv = fullfile(output_dir, [feature_slug, '_problem_ranking.csv']);
    run_csv = fullfile(output_dir, [feature_slug, '_run_metrics.csv']);
    writetable(problem_table, problem_csv);
    writetable(run_table, run_csv);

    feature_analysis = struct();
    feature_analysis.name = entry.name;
    feature_analysis.solver_names = solver_names;
    feature_analysis.problem_table = problem_table;
    feature_analysis.run_table = run_table;
    feature_analysis.full_scores = full_scores;
    feature_analysis.saved_scores = saved_scores;
    feature_analysis.full_gap = full_gap;
    feature_analysis.filtered_scores = filtered;
    analysis.features(end + 1) = feature_analysis;
end

analysis_file = fullfile(output_dir, 'aggregate_analysis.mat');
save(analysis_file, 'analysis', '-v7.3');
write_summary_markdown(analysis, fullfile(output_dir, 'aggregate_problem_ranking.md'));
fprintf('Aggregate analysis: %s\n', analysis_file);

end

function filtered = filtered_score_summary(problem_table, work_all, full_scores)
flags = problem_table.family_flag;
filters = {true(height(problem_table), 1), ...
    ~strcmp(flags, 'unknown_or_unbounded_below'), ...
    strcmp(flags, 'least_squares_or_residual'), ...
    strcmp(flags, 'other')};
names = {'all', 'exclude_unknown_or_unbounded', ...
    'least_squares_or_residual', 'other'};
rows = cell(numel(filters), 7);
for i = 1:numel(filters)
    keep = filters{i};
    if all(keep)
        scores = full_scores;
    else
        scores = performance_scores_from_work(work_all(keep, :, :, :));
    end
    rows(i, :) = {names{i}, sum(keep), scores(1), scores(2), ...
        scores(1) - scores(2), sum(problem_table.ds_wins(keep)), ...
        sum(problem_table.cbds_wins(keep))};
end
filtered = cell2table(rows, 'VariableNames', ...
    {'filter', 'n_problems', 'ds_score', 'cbds_score', 'score_gap_ds', ...
    'ds_run_wins', 'cbds_run_wins'});
end

function flag = classify_problem(name)
if ismember(name, {'INDEF', 'INDEFM', 'FLETCHBV', 'FLETBV3M', ...
        'CURLY10', 'CURLY20', 'CURLY30', 'SCURLY10', 'SCURLY20', ...
        'SCURLY30'})
    flag = 'unknown_or_unbounded_below';
elseif endsWith(name, 'LS') || startsWith(name, 'PALMER') ...
        || ismember(name, {'EXTROSNB', 'SBRYBND', 'SSBRYBND', ...
        'BRYBND', 'BROYDNBDLS', 'MSQRTALS', 'MSQRTBLS'})
    flag = 'least_squares_or_residual';
else
    flag = 'other';
end
end

function [problem_table, run_table, work_all] = decompose_results(results)
histories = results.fun_histories;
fun_outs = results.fun_outs;
fun_inits = results.fun_inits;
n_evals = results.n_evals;
n_problems = size(histories, 1);
n_solvers = size(histories, 2);
n_runs = size(histories, 3);
tolerances = 10 .^ (-1:-1:-10);

work_all = NaN(n_problems, n_solvers, n_runs, numel(tolerances));
best_true = NaN(n_problems, n_solvers, n_runs);
run_rows = cell(n_problems * n_runs, 13);
row = 0;

for i_problem = 1:n_problems
    for i_run = 1:n_runs
        init_value = fun_inits(i_problem, min(i_run, size(fun_inits, 2)));
        values = NaN(n_solvers, 1);
        for i_solver = 1:n_solvers
            nf = max(0, floor(n_evals(i_problem, i_solver, i_run)));
            history = squeeze(histories(i_problem, i_solver, i_run, :));
            history = history(1:min(nf, numel(history)));
            values(i_solver) = min(history, [], 'omitnan');
            best_true(i_problem, i_solver, i_run) = values(i_solver);
        end
        merit_min = min([values(:); init_value], [], 'omitnan');
        for i_tol = 1:numel(tolerances)
            if isinf(init_value)
                threshold = Inf;
            elseif isfinite(merit_min)
                threshold = max(tolerances(i_tol) * init_value + ...
                    (1 - tolerances(i_tol)) * merit_min, merit_min);
            else
                threshold = -Inf;
            end
            for i_solver = 1:n_solvers
                nf = max(0, floor(n_evals(i_problem, i_solver, i_run)));
                history = squeeze(histories(i_problem, i_solver, i_run, :));
                history = history(1:min(nf, numel(history)));
                work_all(i_problem, i_solver, i_run, i_tol) = ...
                    find_first_or_nan(history <= threshold);
            end
        end

        ds_value = values(1);
        cbds_value = values(2);
        comparison_tolerance = 1e-10 * max([1, abs(ds_value), abs(cbds_value)]);
        outcome = sign_with_tolerance(cbds_value - ds_value, comparison_tolerance);
        row = row + 1;
        run_rows(row, :) = {results.problem_names{i_problem}, ...
            results.problem_dims(i_problem), i_run, init_value, ds_value, cbds_value, ...
            cbds_value - ds_value, outcome, ...
            fun_outs(i_problem, 1, i_run), fun_outs(i_problem, 2, i_run), ...
            n_evals(i_problem, 1, i_run), n_evals(i_problem, 2, i_run), merit_min};
    end
end

run_table = cell2table(run_rows, 'VariableNames', ...
    {'problem', 'n', 'run', 'f_init', 'ds_best_true', 'cbds_best_true', ...
    'best_true_advantage_ds', 'outcome', 'ds_output_true', 'cbds_output_true', ...
    'ds_evaluations', 'cbds_evaluations', 'reference_min'});

problem_rows = cell(n_problems, 17);
for i_problem = 1:n_problems
    rows = strcmp(run_table.problem, results.problem_names{i_problem});
    gaps = run_table.best_true_advantage_ds(rows);
    outcomes = run_table.outcome(rows);
    ds_output = run_table.ds_output_true(rows);
    cbds_output = run_table.cbds_output_true(rows);
    ds_solved = squeeze(sum(isfinite(work_all(i_problem, 1, :, :)), [3, 4]));
    cbds_solved = squeeze(sum(isfinite(work_all(i_problem, 2, :, :)), [3, 4]));
    work_ds = squeeze(work_all(i_problem, 1, :, :));
    work_cbds = squeeze(work_all(i_problem, 2, :, :));
    paired = isfinite(work_ds) & isfinite(work_cbds);
    work_advantage = work_cbds(paired) - work_ds(paired);
    if isempty(work_advantage)
        median_work_advantage = NaN;
    else
        median_work_advantage = median(work_advantage, 'omitnan');
    end
    problem_rows(i_problem, :) = {results.problem_names{i_problem}, ...
        results.problem_dims(i_problem), sum(outcomes > 0), sum(outcomes < 0), ...
        sum(outcomes == 0), median(gaps, 'omitnan'), mean(gaps, 'omitnan'), ...
        robust_iqr(gaps), median(cbds_output - ds_output, 'omitnan'), ...
        min(squeeze(best_true(i_problem, 1, :)), [], 'omitnan'), ...
        min(squeeze(best_true(i_problem, 2, :)), [], 'omitnan'), ...
        ds_solved, cbds_solved, median_work_advantage, ...
        any(results.solver_abnormal_terminations(i_problem, 1, :)), ...
        any(results.solver_abnormal_terminations(i_problem, 2, :)), 0};
end

problem_table = cell2table(problem_rows, 'VariableNames', ...
    {'problem', 'n', 'ds_wins', 'cbds_wins', 'ties', ...
    'median_best_true_advantage_ds', 'mean_best_true_advantage_ds', ...
    'iqr_best_true_advantage_ds', 'median_output_true_advantage_ds', ...
    'ds_best_true_over_runs', 'cbds_best_true_over_runs', ...
    'ds_solved_cells', 'cbds_solved_cells', 'median_evaluation_advantage_ds', ...
    'ds_abnormal', 'cbds_abnormal', 'profile_gap_contribution'});
end

function index = find_first_or_nan(mask)
index = find(mask, 1, 'first');
if isempty(index)
    index = NaN;
end
end

function outcome = sign_with_tolerance(value, tolerance)
if value > tolerance
    outcome = 1;
elseif value < -tolerance
    outcome = -1;
else
    outcome = 0;
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

function scores = performance_scores_from_work(work_all)
n_tolerances = size(work_all, 4);
profile_scores = zeros(2, n_tolerances);
for i_tol = 1:n_tolerances
    work = reshape(work_all(:, :, :, i_tol), ...
        size(work_all, 1), size(work_all, 2), size(work_all, 3));
    profile_scores(:, i_tol) = one_tolerance_scores(work);
end
scores = mean(profile_scores, 2);
end

function scores = one_tolerance_scores(work)
[n_problems, n_solvers, n_runs] = size(work);
if n_problems == 0
    scores = zeros(n_solvers, 1);
    return;
end

denominator = NaN(n_problems, n_runs);
for i_problem = 1:n_problems
    for i_run = 1:n_runs
        denominator(i_problem, i_run) = min(work(i_problem, :, i_run), [], 'omitnan');
    end
end

x = NaN(n_solvers, n_problems, n_runs);
for i_run = 1:n_runs
    for i_problem = 1:n_problems
        x(:, i_problem, i_run) = work(i_problem, :, i_run) / denominator(i_problem, i_run);
    end
end
if all(isnan(x(:)))
    ratio_max = eps;
else
    ratio_max = max(x(:), [], 'omitnan');
end
x(isnan(x)) = Inf;
x = sort(x, 2);
x = reshape(x, [n_solvers, n_problems * n_runs]);
x = permute(x, [2, 1]);
[x, index_sort_x] = sort(x, 1);

y = NaN(n_problems * n_runs, n_solvers, n_runs);
for i_solver = 1:n_solvers
    for i_run = 1:n_runs
        indices = (i_run - 1) * n_problems + 1:i_run * n_problems;
        y(indices, i_solver, i_run) = linspace(1 / n_problems, 1, n_problems);
        y_partial = y(:, i_solver, i_run);
        y(:, i_solver, i_run) = y_partial(index_sort_x(:, i_solver));
        for i_problem = 1:n_problems * n_runs
            if isnan(y(i_problem, i_solver, i_run))
                if i_problem > 1
                    y(i_problem, i_solver, i_run) = y(i_problem - 1, i_solver, i_run);
                else
                    y(i_problem, i_solver, i_run) = 0;
                end
            end
        end
    end
end

index_ratio_max = NaN(n_solvers, 1);
for i_solver = 1:n_solvers
    index = find(x(:, i_solver) <= ratio_max, 1, 'last');
    if ~isempty(index)
        index_ratio_max(i_solver) = index;
    end
end
ratio_max_y = zeros(n_solvers, n_runs);
for i_solver = 1:n_solvers
    for i_run = 1:n_runs
        if ~isnan(index_ratio_max(i_solver)) && ~isempty(index_ratio_max(i_solver))
            ratio_max_y(i_solver, i_run) = y(index_ratio_max(i_solver), i_solver, i_run);
        end
    end
end
for i_solver = 1:n_solvers
    for i_run = 1:n_runs
        y(:, i_solver, i_run) = min(y(:, i_solver, i_run), ratio_max_y(i_solver, i_run));
    end
end

x(isfinite(x)) = log2(x(isfinite(x)));
if ratio_max > eps
    ratio_max = max(log2(ratio_max), eps);
end
x(isinf(x)) = 1.1 * ratio_max;
x = [zeros(1, n_solvers); x; ones(1, n_solvers) * ratio_max * 1.1];
y = [zeros(1, n_solvers, n_runs); y; y(end, :, :)];

scores = zeros(n_solvers, 1);
for i_solver = 1:n_solvers
    y_mean = squeeze(mean(y(:, i_solver, :), 3));
    contribution = diff(x(:, i_solver)) .* y_mean(1:end-1);
    scores(i_solver) = sum(contribution(isfinite(contribution)));
end
normalizer = max(scores);
if normalizer > 0
    scores = scores / normalizer;
end
end

function write_summary_markdown(analysis, output_file)
fid = fopen(output_file, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# DS vs CBDS High-Noise Aggregate Decomposition\n\n');
fprintf(fid, 'Generated: %s\n\n', analysis.created);
fprintf(fid, '> Diagnostic only: these scores average tau = 1e-1 through 1e-10. ');
fprintf(fid, 'Use `noise_matched_profiles/noise_matched_profile_analysis.md` for the primary analysis.\n\n');
for i_feature = 1:numel(analysis.features)
    feature = analysis.features(i_feature);
    fprintf(fid, '## %s\n\n', feature.name);
    fprintf(fid, '- DS score: %.6f\n', feature.full_scores(1));
    fprintf(fid, '- CBDS score: %.6f\n', feature.full_scores(2));
    fprintf(fid, '- DS minus CBDS: %+.6f\n\n', feature.full_gap);
    fprintf(fid, '### Filtered scores\n\n');
    fprintf(fid, '| Filter | Problems | DS | CBDS | Gap (DS) | DS/CBDS run wins |\n');
    fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: |\n');
    filtered = feature.filtered_scores;
    for i = 1:height(filtered)
        fprintf(fid, '| `%s` | %d | %.6f | %.6f | %+.6f | %d/%d |\n', ...
            filtered.filter{i}, filtered.n_problems(i), filtered.ds_score(i), ...
            filtered.cbds_score(i), filtered.score_gap_ds(i), ...
            filtered.ds_run_wins(i), filtered.cbds_run_wins(i));
    end
    fprintf(fid, '\n');
    table = feature.problem_table;
    n_show = min(12, height(table));
    fprintf(fid, '| Problem | n | DS wins | CBDS wins | Median true advantage (DS) | Score-gap contribution |\n');
    fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: |\n');
    for i = 1:n_show
        fprintf(fid, '| `%s` | %d | %d | %d | %.6g | %+.6g |\n', ...
            table.problem{i}, table.n(i), table.ds_wins(i), table.cbds_wins(i), ...
            table.median_best_true_advantage_ds(i), table.profile_gap_contribution(i));
    end
    fprintf(fid, '\n');
end
end
