function verification_file = verify_trace_ds_cbds_baseline( ...
    problem_names, noise_levels, run_indices, options)
%VERIFY_TRACE_DS_CBDS_BASELINE strictly verifies the Stage 6 baseline tracer.

if nargin < 1 || isempty(problem_names)
    problem_names = {'FMINSRF2', 'FLETCHCR', 'GENHUMPS', 'COOLHANSLS', ...
        'EXTROSNB', 'DIXON3DQ', 'HILBERTB', 'MSQRTALS', 'SBRYBND'};
end
if nargin < 2 || isempty(noise_levels)
    noise_levels = [1e-1, 1e-2];
end
if nargin < 3 || isempty(run_indices)
    run_indices = 1:5;
end
if nargin < 4 || isempty(options)
    options = struct();
end
ensure_investigation_paths();

options = set_default(options, 'max_eval_factor', 200);
options = set_default(options, 'step_tolerance', 1e-6);
options = set_default(options, 'stage3_root', default_stage3_root());
options = set_default(options, 'output_dir', fullfile(options.stage3_root, ...
    'analysis', 'stage6_trace_equivalence'));
if ~exist(options.output_dir, 'dir')
    mkdir(options.output_dir);
end

stage3 = load_stage3_results(options.stage3_root, noise_levels);
algorithms = {'ds', 'cbds'};
n_rows = numel(problem_names) * numel(noise_levels) ...
    * numel(run_indices) * numel(algorithms);
rows = cell(n_rows, 16);
row = 0;

for i_problem = 1:numel(problem_names)
    problem_name = char(problem_names{i_problem});
    problem = s2mpj_load(problem_name);
    n = problem.n;
    maxfun = options.max_eval_factor * n;

    for i_sigma = 1:numel(noise_levels)
        sigma = noise_levels(i_sigma);
        results = stage3{i_sigma};
        i_stage3_problem = find(strcmp(results.problem_names, problem_name));
        assert(isscalar(i_stage3_problem), ...
            'Problem %s is missing from the Stage 3 data.', problem_name);
        assert(results.problem_dims(i_stage3_problem) == n);
        feature = Feature('noisy', struct('noise_level', sigma, ...
            'n_runs', max(run_indices)));

        for run_index = run_indices
            seed = mod(211 * run_index, 2^32);
            for i_algorithm = 1:numel(algorithms)
                algorithm = algorithms{i_algorithm};
                solver_options = baseline_options(algorithm, maxfun, ...
                    options.step_tolerance);

                fp_formal = FeaturedProblem(problem, feature, maxfun, seed);
                [x_formal, f_formal, exitflag_formal, out_formal] = ...
                    accelerated_bds_options(@(x) fp_formal.fun(x), ...
                    fp_formal.x0, solver_options);

                fp_trace = FeaturedProblem(problem, feature, maxfun, seed);
                [x_trace, f_trace, out_trace, trace] = trace_ds_cbds_baseline( ...
                    @(x) fp_trace.fun(x), @(x) problem.fun(x), ...
                    fp_trace.x0, solver_options);

                formal_exact = compare_formal_and_trace(x_formal, f_formal, ...
                    exitflag_formal, out_formal, fp_formal.fun_hist, ...
                    x_trace, f_trace, out_trace, fp_trace.fun_hist);
                trace_internal_exact = validate_trace_internal( ...
                    trace, out_trace, solver_options, n);
                [stage3_exact, stage3_nf, stage3_returned_true] = ...
                    compare_trace_and_stage3(out_trace, results, ...
                    i_stage3_problem, i_algorithm, run_index);

                row = row + 1;
                rows(row, :) = {string(problem_name), n, sigma, run_index, ...
                    seed, string(algorithm), maxfun, out_trace.funcCount, ...
                    stage3_nf, exitflag_formal, out_trace.exitflag, ...
                    formal_exact, trace_internal_exact, stage3_exact, ...
                    out_trace.returned_true_value, stage3_returned_true};

                status = "PASS";
                if ~(formal_exact && trace_internal_exact && stage3_exact)
                    status = "FAIL";
                end
                fprintf('%s %s sigma=%g run=%d algorithm=%s nf=%d\n', ...
                    status, problem_name, sigma, run_index, algorithm, ...
                    out_trace.funcCount);
            end
        end
    end
end

verification = cell2table(rows, 'VariableNames', {'problem', 'n', 'sigma', ...
    'run', 'seed', 'algorithm', 'maxfun', 'trace_func_count', ...
    'stage3_func_count', 'formal_exitflag', 'trace_exitflag', ...
    'formal_exact', 'trace_internal_exact', 'stage3_exact', ...
    'trace_returned_true', 'stage3_returned_true'});
verification_file = fullfile(options.output_dir, ...
    'stage6_trace_equivalence_verification.mat');
save(verification_file, 'verification', 'options', 'problem_names', ...
    'noise_levels', 'run_indices', '-v7.3');
writetable(verification, fullfile(options.output_dir, ...
    'stage6_trace_equivalence_verification.csv'));
write_report(verification, fullfile(options.output_dir, ...
    'stage6_trace_equivalence_verification.md'));

all_pass = all(verification.formal_exact ...
    & verification.trace_internal_exact & verification.stage3_exact);
assert(all_pass, ...
    'At least one Stage 6 trace equivalence check failed; inspect %s.', ...
    verification_file);
fprintf('PASS all %d Stage 6 strict equivalence cases.\n', height(verification));
fprintf('Verification file: %s\n', verification_file);

end

function exact = compare_formal_and_trace(x_formal, f_formal, ...
    exitflag_formal, out_formal, formal_true_history, ...
    x_trace, f_trace, out_trace, trace_true_history)

exact = isequaln(x_formal, x_trace) ...
    && isequaln(f_formal, f_trace) ...
    && isequaln(exitflag_formal, out_trace.exitflag) ...
    && isequaln(out_formal.funcCount, out_trace.funcCount) ...
    && isequaln(out_formal.xhist, out_trace.xhist) ...
    && isequaln(out_formal.fhist, out_trace.fhist) ...
    && isequaln(out_formal.alpha_hist, out_trace.alpha_hist) ...
    && isequaln(out_formal.blocks_hist, out_trace.blocks_hist) ...
    && isequaln(out_formal.invalid_points, out_trace.invalid_points) ...
    && isequaln(out_formal.message, out_trace.message) ...
    && isequaln(formal_true_history, trace_true_history) ...
    && isequaln(trace_true_history, out_trace.true_fhist);
end

function exact = validate_trace_internal(trace, output, solver_options, n)
try
    n_events = output.funcCount - 1;
    assert(numel(trace.evaluation) == n_events);
    assert(isequal(trace.evaluation, 2:output.funcCount));
    assert(isequaln(trace.trial_point, output.xhist(:, 2:end)));
    assert(isequaln(trace.trial_noisy_raw, output.fhist(2:end)));
    assert(isequaln(trace.trial_noisy, output.noisy_decision_fhist(2:end)));
    assert(isequaln(trace.trial_true, output.true_fhist(2:end)));
    assert(isequal(trace.block_state.block, output.blocks_hist));
    assert(isequal(trace.block_visit, repelem(trace.block_state.visit, ...
        diff([trace.block_state.evaluation_start; ...
        trace.block_state.evaluation_end], 1, 1) + 1)));

    D = zeros(n, 2 * n);
    D(:, 1:2:end) = eye(n);
    D(:, 2:2:end) = -eye(n);
    expected_trial = trace.base_point_before ...
        + D(:, trace.direction_index) .* trace.alpha_before;
    assert(isequaln(expected_trial, trace.trial_point));
    assert(all(trace.polling_order >= 1));
    assert(all(trace.sign == 1 - 2 * mod(trace.direction_index + 1, 2)));
    assert(all(trace.coordinate == ceil(trace.direction_index / 2)));
    assert(all(trace.accepted <= trace.selected_trial));
    assert(all(trace.base_changed == trace.accepted));
    assert(all(trace.false_acceptance ...
        == (trace.accepted & ~trace.true_success)));
    assert(all(trace.false_rejection ...
        == (~trace.noisy_success & trace.true_success)));
    assert(isequaln(trace.block_state.base_point_after(:, end), ...
        output.final_base));
    assert(isequaln(trace.block_state.base_true_after(end), ...
        output.final_base_true));
    assert(output.iterations == size(output.alpha_hist, 2) - 1);
    validate_alpha_reconstruction(trace.block_state, output.alpha_hist);
    exact = true;
catch
    exact = false;
end
end

function validate_alpha_reconstruction(state, alpha_hist)
alpha = alpha_hist(:, 1);
for iteration = 1:(size(alpha_hist, 2) - 1)
    selected = find(state.iteration == iteration);
    for i_visit = selected
        block = state.block(i_visit);
        assert(isequaln(alpha(block), state.alpha_before(i_visit)));
        alpha(block) = state.alpha_after(i_visit);
    end
    assert(isequaln(alpha, alpha_hist(:, iteration + 1)));
end
end

function [exact, nf, returned_true] = compare_trace_and_stage3( ...
    out_trace, results, i_problem, i_solver, i_run)

nf = floor(results.n_evals(i_problem, i_solver, i_run));
history = squeeze(results.fun_histories(i_problem, i_solver, i_run, 1:nf));
history = history(:)';
returned_true = results.fun_outs(i_problem, i_solver, i_run);
f_init = results.fun_inits(i_problem, ...
    min(i_run, size(results.fun_inits, 2)));
exact = isequaln(out_trace.funcCount, nf) ...
    && isequaln(out_trace.true_fhist, history) ...
    && isequaln(out_trace.true_fhist(1), f_init) ...
    && isequaln(out_trace.returned_true_value, returned_true);
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

function results_by_sigma = load_stage3_results(stage3_root, noise_levels)
manifest_file = fullfile(stage3_root, 'aggregate_manifest.mat');
assert(exist(manifest_file, 'file') == 2, ...
    'Stage 3 aggregate manifest not found: %s', manifest_file);
loaded = load(manifest_file, 'manifest');
results_by_sigma = cell(size(noise_levels));
for i_sigma = 1:numel(noise_levels)
    sigma = noise_levels(i_sigma);
    feature_name = sprintf('noisy_1e-%d', round(-log10(sigma)));
    i_feature = find(strcmp({loaded.manifest.features.name}, feature_name));
    assert(isscalar(i_feature), 'Missing Stage 3 feature %s.', feature_name);
    data_file = loaded.manifest.features(i_feature).data_file;
    if ~exist(data_file, 'file')
        data_file = locate_stage3_data_file(stage3_root, sigma);
    end
    data = load(data_file, 'results_plibs');
    results = data.results_plibs{1};
    assert(isequal(results.solver_names, ...
        {'ds-baseline-200n', 'cbds-baseline-200n'}));
    results_by_sigma{i_sigma} = results;
end
end

function data_file = locate_stage3_data_file(stage3_root, sigma)
listing = dir(fullfile(stage3_root, '**', 'data_for_loading.mat'));
data_file = '';
for i_file = 1:numel(listing)
    candidate = fullfile(listing(i_file).folder, listing(i_file).name);
    loaded = load(candidate, 'results_plibs');
    stamp = string(loaded.results_plibs{1}.feature_stamp);
    if contains(stamp, sprintf('noisy_%g_', sigma))
        data_file = candidate;
        return;
    end
end
error('No Stage 3 raw data found for sigma=%g.', sigma);
end

function write_report(verification, filename)
fid = fopen(filename, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Stage 6 Trace Equivalence Verification\n\n');
fprintf(fid, 'Strict gate over `%d` solver-runs. Every row compares the tracer with ', ...
    height(verification));
fprintf(fid, 'the formal solver and with the original Stage 3 raw history.\n\n');
fprintf(fid, '| Check | Passed | Total |\n');
fprintf(fid, '| --- | ---: | ---: |\n');
fprintf(fid, '| Formal solver exact equality | %d | %d |\n', ...
    sum(verification.formal_exact), height(verification));
fprintf(fid, '| Internal trace reconstruction | %d | %d |\n', ...
    sum(verification.trace_internal_exact), height(verification));
fprintf(fid, '| Original Stage 3 trajectory exact equality | %d | %d |\n\n', ...
    sum(verification.stage3_exact), height(verification));
fprintf(fid, 'Exact equality covers evaluated points, noisy values, true histories, ');
fprintf(fid, 'block/direction order, step-size history, returned point/value, function ');
fprintf(fid, 'count, and termination state wherever the formal output exposes them.\n');
end

function root = default_stage3_root()
path_tests = fileparts(mfilename('fullpath'));
root = fullfile(path_tests, 'testdata', ...
    'ds_vs_cbds_high_noise_primary_20260712_165527');
end

function options = set_default(options, name, value)
if ~isfield(options, name) || isempty(options.(name))
    options.(name) = value;
end
end

function ensure_investigation_paths()
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
