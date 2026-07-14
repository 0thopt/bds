function manifest_file = run_ds_vs_cbds_high_noise_replay(replay_matrix_file, options)
%RUN_DS_VS_CBDS_HIGH_NOISE_REPLAY runs the targeted Stage 6 paired replay.

if nargin < 1 || isempty(replay_matrix_file)
    replay_matrix_file = default_replay_matrix_file();
end
if nargin < 2
    options = struct();
end
ensure_replay_paths();

options = set_default(options, 'run_indices', []);
options = set_default(options, 'priority_tiers', [1, 2]);
options = set_default(options, 'n_jobs', 1);
options = set_default(options, 'resume', true);
options = set_default(options, 'savepath', fullfile(fileparts(mfilename('fullpath')), ...
    'testdata', ['ds_vs_cbds_high_noise_stage6_replay_', ...
    char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'))]));
validate_runner_options(options);

replay_matrix = read_replay_matrix(replay_matrix_file, options.priority_tiers);
tasks = build_tasks(replay_matrix, options.run_indices, options.savepath);
assert(mod(height(tasks), 2) == 0);
task_pair_counts = groupcounts(tasks(:, {'problem', 'sigma', 'run', 'seed'}), ...
    {'problem', 'sigma', 'run', 'seed'});
assert(all(task_pair_counts.GroupCount == 2), ...
    'Every Stage 6 paired run must contain exactly DS and CBDS.');
fprintf('Stage 6 replay tasks: %d (%d paired runs).\n', ...
    height(tasks), height(task_pair_counts));
prepare_output_directories(tasks, options.savepath);
writetable(replay_matrix, fullfile(options.savepath, 'stage6_targeted_replay_matrix.csv'));
writetable(tasks, fullfile(options.savepath, 'stage6_replay_tasks.csv'));

task_results = cell(height(tasks), 1);
if options.n_jobs > 1
    pool = gcp('nocreate');
    if isempty(pool)
        parpool('local', options.n_jobs);
    elseif pool.NumWorkers ~= options.n_jobs
        delete(pool);
        parpool('local', options.n_jobs);
    end
    parfor i_task = 1:height(tasks)
        task_results{i_task} = run_one_task(tasks(i_task, :), options);
    end
else
    for i_task = 1:height(tasks)
        task_results{i_task} = run_one_task(tasks(i_task, :), options);
    end
end

run_summary = struct2table(vertcat(task_results{:}));
run_summary = sortrows(run_summary, ...
    {'priority_tier', 'selection_order', 'sigma', 'run', 'algorithm'}, ...
    {'ascend', 'ascend', 'descend', 'ascend', 'ascend'});
writetable(run_summary, fullfile(options.savepath, 'stage6_replay_index.csv'));

manifest_file = fullfile(options.savepath, 'stage6_replay_manifest.mat');
save(manifest_file, 'replay_matrix', 'tasks', 'run_summary', 'options', ...
    'replay_matrix_file', '-v7.3');
write_run_report(run_summary, options, ...
    fullfile(options.savepath, 'stage6_replay_run_report.md'));

failed = ~run_summary.success;
if any(failed)
    error('run_ds_vs_cbds_high_noise_replay:TaskFailure', ...
        '%d Stage 6 replay tasks failed; see stage6_replay_index.csv.', sum(failed));
end
audit_completed_run(tasks, run_summary, options.savepath);
fprintf('Stage 6 replay manifest: %s\n', manifest_file);

end

function result = run_one_task(task, options)
result = empty_task_result(task);
trace_file = char(task.trace_file_absolute);
try
    if options.resume && exist(trace_file, 'file')
        loaded = load(trace_file, 'identity', 'run_summary');
        validate_saved_identity(loaded.identity, task);
        result = loaded.run_summary;
        result.reused = true;
        fprintf('REUSE %s sigma=%g run=%d %s\n', ...
            task.problem, task.sigma, task.run, task.algorithm);
        return;
    end

    problem = s2mpj_load(char(task.problem));
    assert(problem.n == task.n, 'Dimension changed for %s.', task.problem);
    feature = Feature('noisy', struct('noise_level', task.sigma, ...
        'n_runs', task.run));
    featured_problem = FeaturedProblem(problem, feature, task.maxfun, task.seed);
    solver_options = baseline_options(char(task.algorithm), task.maxfun, ...
        task.step_tolerance);

    [x, f, output, trace] = trace_ds_cbds_baseline( ...
        @(point) featured_problem.fun(point), @(point) problem.fun(point), ...
        featured_problem.x0, solver_options);
    assert(isequaln(featured_problem.fun_hist, output.true_fhist));
    assert(output.funcCount <= task.maxfun);
    assert(size(output.xhist, 2) == output.funcCount);

    identity = task_identity(task);
    result = summarize_run(identity, x, f, output, trace);
    result.trace_file = string(task.trace_file_relative);
    result.success = true;
    result.reused = false;
    run_summary = result;

    temp_file = [tempname(fileparts(trace_file)), '.mat'];
    cleanup = onCleanup(@() delete_if_present(temp_file));
    save(temp_file, 'identity', 'solver_options', 'x', 'f', 'output', ...
        'trace', 'run_summary', '-v7.3');
    movefile(temp_file, trace_file, 'f');
    clear cleanup;
    fprintf('DONE  %s sigma=%g run=%d %s nf=%d best_true=%.6e\n', ...
        task.problem, task.sigma, task.run, task.algorithm, ...
        output.funcCount, output.best_true_value);
catch exception
    result.success = false;
    result.error_identifier = string(exception.identifier);
    result.error_message = string(exception.message);
    fprintf(2, 'FAIL  %s sigma=%g run=%d %s: %s\n', ...
        task.problem, task.sigma, task.run, task.algorithm, exception.message);
end
end

function result = summarize_run(identity, x, f, output, trace)
accepted = trace.accepted;
base_changed = trace.base_changed;
false_acceptance = trace.false_acceptance;
false_rejection = trace.false_rejection;
true_decrease = trace.base_true_before - trace.trial_true;
noise_scale = identity.sigma * max([ones(1, numel(trace.evaluation)); ...
    abs(trace.base_true_before); abs(trace.trial_true)], [], 1);
step_snr = abs(true_decrease) ./ noise_scale;
updates = trace.block_state.step_update_code;
[~, best_true_evaluation] = min(output.true_fhist, [], 'omitnan');
final_alpha = output.alpha_hist(:, end);

result = empty_task_result(identity);
result.func_count = output.funcCount;
result.exitflag = output.exitflag;
result.termination_message = output.message;
result.returned_noisy = f;
result.returned_true = output.returned_true_value;
result.best_true = output.best_true_value;
result.best_true_evaluation = best_true_evaluation;
result.final_base_true = output.final_base_true;
result.iterations = output.iterations;
result.block_visits = numel(trace.block_state.visit);
result.accepted_decisions = sum(accepted);
result.base_changes = sum(base_changed);
result.false_acceptances = sum(false_acceptance);
result.false_rejections = sum(false_rejection);
result.expansions = sum(updates == 1);
result.contractions = sum(updates == -1);
result.final_alpha_min = min(final_alpha);
result.final_alpha_median = median(final_alpha);
result.final_alpha_max = max(final_alpha);
result.final_alpha_log10_spread = log10(max(final_alpha) / min(final_alpha));
result.median_step_snr = median(step_snr, 'omitnan');
result.low_snr_fraction = mean(step_snr < 1, 'omitnan');
result.budget_after_best_fraction = ...
    (output.funcCount - best_true_evaluation) / max(1, output.funcCount - 1);
result.invalid_evaluations = sum(~isfinite(output.fhist));
result.returned_point_norm = norm(x);
end

function result = empty_task_result(task)
result.priority_tier = double(task.priority_tier);
result.selection_order = double(task.selection_order);
result.problem = string(task.problem);
result.n = double(task.n);
result.sigma = double(task.sigma);
result.analysis_taus = string(task.analysis_taus);
result.primary_role = string(task.primary_role);
result.run = double(task.run);
result.seed = double(task.seed);
result.algorithm = string(task.algorithm);
result.maxfun = double(task.maxfun);
result.step_tolerance = double(task.step_tolerance);
result.decision_source = "noisy";
result.trace_file = string(task.trace_file_relative);
result.success = false;
result.reused = false;
result.func_count = NaN;
result.exitflag = NaN;
result.termination_message = "";
result.returned_noisy = NaN;
result.returned_true = NaN;
result.best_true = NaN;
result.best_true_evaluation = NaN;
result.final_base_true = NaN;
result.iterations = NaN;
result.block_visits = NaN;
result.accepted_decisions = NaN;
result.base_changes = NaN;
result.false_acceptances = NaN;
result.false_rejections = NaN;
result.expansions = NaN;
result.contractions = NaN;
result.final_alpha_min = NaN;
result.final_alpha_median = NaN;
result.final_alpha_max = NaN;
result.final_alpha_log10_spread = NaN;
result.median_step_snr = NaN;
result.low_snr_fraction = NaN;
result.budget_after_best_fraction = NaN;
result.invalid_evaluations = NaN;
result.returned_point_norm = NaN;
result.error_identifier = "";
result.error_message = "";
end

function identity = task_identity(task)
identity.schema_version = 1;
identity.priority_tier = double(task.priority_tier);
identity.selection_order = double(task.selection_order);
identity.problem = string(task.problem);
identity.n = double(task.n);
identity.sigma = double(task.sigma);
identity.analysis_taus = string(task.analysis_taus);
identity.primary_role = string(task.primary_role);
identity.run = double(task.run);
identity.seed = double(task.seed);
identity.algorithm = string(task.algorithm);
identity.maxfun = double(task.maxfun);
identity.step_tolerance = double(task.step_tolerance);
identity.decision_source = "noisy";
identity.trace_file_relative = string(task.trace_file_relative);
end

function options = baseline_options(algorithm, maxfun, step_tolerance)
options.Algorithm = algorithm;
options.use_productive_direction_memory = false;
options.use_sweep_pattern_direction = false;
options.use_momentum_extrapolation = false;
options.MaxFunctionEvaluations = maxfun;
options.StepTolerance = step_tolerance;
options.output_xhist = true;
options.output_alpha_hist = true;
options.output_block_hist = true;
end

function matrix = read_replay_matrix(filename, priority_tiers)
if ~exist(filename, 'file')
    error('run_ds_vs_cbds_high_noise_replay:MissingMatrix', ...
        'Replay matrix not found: %s', filename);
end
matrix = readtable(filename, 'TextType', 'string');
required = ["priority_tier", "selection_order", "problem", "n", "sigma", ...
    "analysis_taus", "initial_runs", "max_eval_factor", "step_tolerance", ...
    "algorithms", "decision_source", "oracle_intervention_deferred", ...
    "primary_role"];
assert(all(ismember(required, string(matrix.Properties.VariableNames))), ...
    'The replay matrix is missing required columns.');
matrix = matrix(ismember(matrix.priority_tier, priority_tiers), :);
assert(~isempty(matrix), 'No replay rows remain after priority-tier filtering.');
assert(all(matrix.decision_source == "noisy"));
assert(all(matrix.oracle_intervention_deferred == 1));
assert(all(erase(matrix.algorithms, " ") == "ds,cbds"));
keys = matrix(:, {'problem', 'sigma'});
assert(height(unique(keys, 'rows')) == height(matrix), ...
    'The replay matrix contains duplicate problem-sigma rows.');
matrix = sortrows(matrix, {'priority_tier', 'selection_order', 'sigma'}, ...
    {'ascend', 'ascend', 'descend'});
end

function tasks = build_tasks(matrix, requested_runs, savepath)
rows = cell(0, 15);
for i_matrix = 1:height(matrix)
    if isempty(requested_runs)
        run_indices = 1:matrix.initial_runs(i_matrix);
    else
        run_indices = requested_runs;
    end
    algorithms = ["ds", "cbds"];
    for run_index = run_indices
        for i_algorithm = 1:numel(algorithms)
            algorithm = algorithms(i_algorithm);
            sigma_token = regexprep(sprintf('%.0e', matrix.sigma(i_matrix)), ...
                'e([+-])0*', 'e$1');
            relative = fullfile('traces', char(matrix.problem(i_matrix)), ...
                ['sigma_', sigma_token], sprintf('run_%03d_%s.mat', ...
                run_index, algorithm));
            rows(end + 1, :) = {matrix.priority_tier(i_matrix), ... %#ok<AGROW>
                matrix.selection_order(i_matrix), matrix.problem(i_matrix), ...
                matrix.n(i_matrix), matrix.sigma(i_matrix), ...
                matrix.analysis_taus(i_matrix), matrix.primary_role(i_matrix), ...
                run_index, mod(211 * run_index, 2^32), algorithm, ...
                matrix.max_eval_factor(i_matrix) * matrix.n(i_matrix), ...
                matrix.step_tolerance(i_matrix), string(relative), ...
                string(fullfile(savepath, relative)), "noisy"};
        end
    end
end
tasks = cell2table(rows, 'VariableNames', {'priority_tier', ...
    'selection_order', 'problem', 'n', 'sigma', 'analysis_taus', ...
    'primary_role', 'run', 'seed', 'algorithm', 'maxfun', ...
    'step_tolerance', 'trace_file_relative', 'trace_file_absolute', ...
    'decision_source'});
end

function prepare_output_directories(tasks, savepath)
if ~exist(savepath, 'dir')
    mkdir(savepath);
end
directories = unique(string(cellfun(@fileparts, ...
    cellstr(tasks.trace_file_absolute), 'UniformOutput', false)));
for i_directory = 1:numel(directories)
    directory = directories(i_directory);
    if ~exist(directory, 'dir')
        mkdir(directory);
    end
end
end

function validate_saved_identity(identity, task)
fields = {'problem', 'n', 'sigma', 'run', 'seed', 'algorithm', 'maxfun', ...
    'step_tolerance', 'decision_source'};
for i_field = 1:numel(fields)
    field = fields{i_field};
    assert(isequaln(string_or_value(identity.(field)), ...
        string_or_value(task.(field))), ...
        'Saved trace identity mismatch for field %s.', field);
end
end

function value = string_or_value(value)
if ischar(value) || isstring(value) || iscellstr(value) %#ok<ISCLSTR>
    value = string(value);
else
    value = double(value);
end
end

function audit_completed_run(tasks, summary, savepath)
assert(height(summary) == height(tasks));
assert(all(summary.success));
assert(all(summary.seed == mod(211 * summary.run, 2^32)));
assert(all(summary.func_count <= summary.maxfun));
assert(all(summary.decision_source == "noisy"));
assert(all(summary.algorithm == "ds" | summary.algorithm == "cbds"));
assert(all(arrayfun(@(i) exist(fullfile(savepath, ...
    summary.trace_file(i)), 'file') == 2, (1:height(summary))')));

keys = summary(:, {'problem', 'sigma', 'run', 'seed'});
counts = groupcounts(keys, {'problem', 'sigma', 'run', 'seed'});
assert(all(counts.GroupCount == 2));
end

function write_run_report(summary, options, filename)
fid = fopen(filename, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Stage 6 Targeted Replay Run Report\n\n');
fprintf(fid, '- Decision source: `normal noisy decisions only`\n');
fprintf(fid, '- Oracle true-acceptance intervention: deferred to Stage 9\n');
fprintf(fid, '- Requested workers: `%d`\n', options.n_jobs);
fprintf(fid, '- Completed/reused/failed tasks: `%d/%d/%d`\n\n', ...
    sum(summary.success), sum(summary.reused), sum(~summary.success));

groups = groupcounts(summary(summary.success, :), ...
    {'problem', 'sigma', 'algorithm'});
fprintf(fid, '| Problem | Sigma | Algorithm | Runs |\n');
fprintf(fid, '| --- | ---: | --- | ---: |\n');
for i = 1:height(groups)
    fprintf(fid, '| `%s` | %.0e | `%s` | %d |\n', groups.problem(i), ...
        groups.sigma(i), groups.algorithm(i), groups.GroupCount(i));
end
end

function validate_runner_options(options)
assert(isnumeric(options.n_jobs) && isscalar(options.n_jobs) ...
    && isfinite(options.n_jobs) && options.n_jobs == floor(options.n_jobs) ...
    && options.n_jobs >= 1, ...
    'options.n_jobs must be a positive integer.');
assert(islogical(options.resume) && isscalar(options.resume), ...
    'options.resume must be a logical scalar.');
if ~isempty(options.run_indices)
    assert(isnumeric(options.run_indices) && isvector(options.run_indices) ...
        && all(options.run_indices >= 1) ...
        && all(options.run_indices == floor(options.run_indices)), ...
        'options.run_indices must contain positive integers.');
end
end

function filename = default_replay_matrix_file()
path_tests = fileparts(mfilename('fullpath'));
filename = fullfile(path_tests, 'testdata', ...
    'ds_vs_cbds_high_noise_primary_20260712_165527', 'analysis', ...
    'noise_matched_problem_ranking', 'stage5_case_selection', ...
    'stage6_targeted_replay_matrix.csv');
end

function options = set_default(options, name, value)
if ~isfield(options, name) || isempty(options.(name))
    options.(name) = value;
end
end

function delete_if_present(filename)
if exist(filename, 'file')
    delete(filename);
end
end

function ensure_replay_paths()
path_tests = fileparts(mfilename('fullpath'));
path_root = fileparts(path_tests);
addpath(path_tests);
addpath(fullfile(path_tests, 'competitors'));
addpath(fullfile(path_root, 'src'));

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
