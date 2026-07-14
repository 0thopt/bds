function result_file = run_ds_vs_cbds_block_count_mechanism(problem_names, options)
%RUN_DS_VS_CBDS_BLOCK_COUNT_MECHANISM varies only the number of blocks.

if nargin < 2
    options = struct();
end
ensure_paths();
options = set_default(options, 'noise_levels', [1e-1, 1e-2]);
options = set_default(options, 'run_indices', 1:20);
options = set_default(options, 'decision_sources', {'noisy', 'true'});
options = set_default(options, 'max_eval_factor', 200);
options = set_default(options, 'step_tolerance', 1e-6);
options = set_default(options, 'savepath', fullfile(fileparts(mfilename('fullpath')), ...
    'testdata', ['ds_vs_cbds_block_count_', ...
    char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'))]));
if ~exist(options.savepath, 'dir')
    mkdir(options.savepath);
end

rows = {};
for i_problem = 1:numel(problem_names)
    problem = s2mpj_load(problem_names{i_problem});
    n = problem.n;
    block_counts = unique([1, 2, max(2, round(sqrt(n))), n]);
    block_counts = block_counts(block_counts <= n);
    for sigma = options.noise_levels
        feature = Feature('noisy', struct('noise_level', sigma, ...
            'n_runs', max(options.run_indices)));
        for run_index = options.run_indices
            seed = mod(211 * run_index, 2^32);
            for num_blocks = block_counts
                for i_source = 1:numel(options.decision_sources)
                    decision_source = char(options.decision_sources{i_source});
                    featured_problem = FeaturedProblem(problem, feature, ...
                        options.max_eval_factor * n, seed);
                    trace_options.num_blocks = num_blocks;
                    trace_options.MaxFunctionEvaluations = options.max_eval_factor * n;
                    trace_options.StepTolerance = options.step_tolerance;
                    trace_options.decision_source = decision_source;
                    [~, ~, output, trace] = trace_ds_cbds_baseline( ...
                        @(point) featured_problem.fun(point), ...
                        @(point) problem.fun(point), featured_problem.x0, trace_options);
                    metric = mechanism_metrics(trace, output);
                    rows(end + 1, :) = {problem.name, n, sigma, run_index, seed, ...
                        num_blocks, decision_source, metric.best_true, ...
                        metric.false_acceptance_fraction, ...
                        metric.false_rejection_fraction, ...
                        metric.premature_contraction_fraction, ...
                        metric.final_alpha_log10_spread, ...
                        metric.budget_after_best_fraction, metric.accepted_steps, ...
                        metric.contractions}; %#ok<AGROW>
                end
            end
        end
    end
end

summary = cell2table(rows, 'VariableNames', ...
    {'problem', 'n', 'sigma', 'run', 'seed', 'num_blocks', ...
    'decision_source', 'best_true', 'false_acceptance_fraction', ...
    'false_rejection_fraction', 'premature_contraction_fraction', ...
    'final_alpha_log10_spread', 'budget_after_best_fraction', ...
    'accepted_steps', 'contractions'});
grouped = summarize_groups(summary);
result_file = fullfile(options.savepath, 'block_count_results.mat');
save(result_file, 'summary', 'grouped', 'options', '-v7.3');
writetable(summary, fullfile(options.savepath, 'block_count_runs.csv'));
writetable(grouped, fullfile(options.savepath, 'block_count_summary.csv'));
write_report(grouped, fullfile(options.savepath, 'block_count_summary.md'));
fprintf('Block-count mechanism results: %s\n', result_file);
end

function metric = mechanism_metrics(trace, output)
accepted = [trace.accepted];
false_acceptance = accepted & [trace.false_acceptance];
false_rejection = [trace.false_rejection];
visit_indices = last_per_visit(trace);
updates = string({trace(visit_indices).step_update});
metric.best_true = output.best_true_value;
metric.accepted_steps = sum(accepted);
metric.contractions = sum(updates == "shrink");
metric.false_acceptance_fraction = sum(false_acceptance) / max(1, sum(accepted));
metric.false_rejection_fraction = sum(false_rejection) / max(1, sum([trace.true_success]));
premature = 0;
keys = unique([[trace.iteration]', [trace.block]'], 'rows', 'stable');
for i = 1:size(keys, 1)
    entries = trace([trace.iteration] == keys(i, 1) & [trace.block] == keys(i, 2));
    premature = premature + ...
        (any(string({entries.step_update}) == "shrink") && any([entries.true_success]));
end
metric.premature_contraction_fraction = premature / max(1, metric.contractions);
alpha = output.alpha_hist(:, end);
metric.final_alpha_log10_spread = log10(max(alpha) / min(alpha));
[~, best_index] = min(output.true_fhist, [], 'omitnan');
metric.budget_after_best_fraction = ...
    (output.funcCount - best_index) / max(1, output.funcCount - 1);
end

function indices = last_per_visit(trace)
keys = unique([[trace.iteration]', [trace.block]'], 'rows', 'stable');
indices = zeros(1, size(keys, 1));
for i = 1:size(keys, 1)
    selected = find([trace.iteration] == keys(i, 1) & [trace.block] == keys(i, 2));
    indices(i) = selected(end);
end
end

function grouped = summarize_groups(summary)
groups = unique(summary(:, {'problem', 'n', 'sigma', 'num_blocks', ...
    'decision_source'}), 'rows');
rows = cell(height(groups), 12);
for i = 1:height(groups)
    selected = strcmp(summary.problem, groups.problem{i}) ...
        & summary.sigma == groups.sigma(i) ...
        & summary.num_blocks == groups.num_blocks(i) ...
        & strcmp(summary.decision_source, groups.decision_source{i});
    table = summary(selected, :);
    rows(i, :) = {groups.problem{i}, groups.n(i), groups.sigma(i), ...
        groups.num_blocks(i), groups.decision_source{i}, ...
        median(table.best_true), median(table.false_acceptance_fraction), ...
        median(table.false_rejection_fraction), ...
        median(table.premature_contraction_fraction), ...
        median(table.final_alpha_log10_spread), ...
        median(table.budget_after_best_fraction), height(table)};
end
grouped = cell2table(rows, 'VariableNames', ...
    {'problem', 'n', 'sigma', 'num_blocks', 'decision_source', ...
    'median_best_true', 'median_false_acceptance_fraction', ...
    'median_false_rejection_fraction', ...
    'median_premature_contraction_fraction', ...
    'median_final_alpha_log10_spread', ...
    'median_budget_after_best_fraction', 'n_runs'});
end

function write_report(grouped, filename)
fid = fopen(filename, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Block-Count Mechanism Experiment\n\n');
fprintf(fid, '| Problem | Sigma | Blocks | Decision | Median best true | FA | FR | Premature contraction | Alpha spread |\n');
fprintf(fid, '| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:height(grouped)
    fprintf(fid, '| `%s` | %g | %d | `%s` | %.6g | %.3f | %.3f | %.3f | %.3f |\n', ...
        grouped.problem{i}, grouped.sigma(i), grouped.num_blocks(i), ...
        grouped.decision_source{i}, grouped.median_best_true(i), ...
        grouped.median_false_acceptance_fraction(i), ...
        grouped.median_false_rejection_fraction(i), ...
        grouped.median_premature_contraction_fraction(i), ...
        grouped.median_final_alpha_log10_spread(i));
end
end

function options = set_default(options, name, value)
if ~isfield(options, name) || isempty(options.(name))
    options.(name) = value;
end
end

function ensure_paths()
path_tests = fileparts(mfilename('fullpath'));
addpath(path_tests);
addpath(fullfile(path_tests, 'competitors'));
addpath(fullfile(fileparts(path_tests), 'src'));
candidates = {'/Users/lihaitian/local/optiprofiler/matlab/optiprofiler', ...
    '/home/lhtian97/local/optiprofiler/matlab/optiprofiler'};
for i = 1:numel(candidates)
    if exist(candidates{i}, 'dir')
        addpath(fullfile(candidates{i}, 'src'));
        addpath(fullfile(candidates{i}, 'problem_libs', 's2mpj'));
        return;
    end
end
error('OptiProfiler MATLAB was not found.');
end
