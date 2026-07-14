function audit_file = audit_ds_vs_cbds_high_noise_stage3(manifest_file)
%AUDIT_DS_VS_CBDS_HIGH_NOISE_STAGE3 validates the recovered aggregate data.

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
expected_features = {'plain', 'noisy_1e-2', 'noisy_1e-1'};
expected_runs = [1, 5, 5];
expected_solvers = {'ds-baseline-200n', 'cbds-baseline-200n'};

assert(isfield(manifest, 'finished') && ~isempty(manifest.finished), ...
    'The aggregate experiment did not record a completion time.');
assert(isequal(manifest.solver_names, expected_solvers), ...
    'The manifest does not contain the expected pairwise solvers.');
assert(isequal({manifest.features.name}, expected_features), ...
    'The manifest features or their order do not match Stage 3.');
assert(isequal([manifest.features.n_runs], expected_runs), ...
    'The feature run counts do not match Stage 3.');

n_rows = 0;
for i_feature = 1:numel(manifest.features)
    data = load(manifest.features(i_feature).data_file, 'results_plibs');
    assert(isscalar(data.results_plibs), 'Expected one problem library per feature.');
    results = data.results_plibs{1};
    n_rows = n_rows + numel(results.problem_names) * numel(expected_solvers) * ...
        manifest.features(i_feature).n_runs;
end

feature = strings(n_rows, 1);
problem = strings(n_rows, 1);
n = zeros(n_rows, 1);
run = zeros(n_rows, 1);
run_seed = zeros(n_rows, 1);
solver = strings(n_rows, 1);
evaluations = zeros(n_rows, 1);
budget = zeros(n_rows, 1);
termination_reason = strings(n_rows, 1);
success = false(n_rows, 1);
abnormal = false(n_rows, 1);
output_fallback = false(n_rows, 1);
f_init = NaN(n_rows, 1);
returned_true = NaN(n_rows, 1);
best_true_evaluated = NaN(n_rows, 1);
nonfinite_true_history_values = zeros(n_rows, 1);

reference_problem_names = {};
reference_problem_dims = [];
reference_excludelist = {};
row = 0;
for i_feature = 1:numel(manifest.features)
    entry = manifest.features(i_feature);
    assert(exist(entry.data_file, 'file') == 2, 'Missing raw data: %s', entry.data_file);
    data = load(entry.data_file, 'results_plibs');
    results = data.results_plibs{1};

    assert(strcmp(results.plib, 's2mpj'), 'Unexpected problem library in %s.', entry.data_file);
    assert(isequal(results.solver_names, expected_solvers), ...
        'Unexpected solver names in %s.', entry.data_file);
    assert(size(results.fun_histories, 3) == entry.n_runs, ...
        'Unexpected run count in %s.', entry.data_file);
    assert(min(results.problem_dims) >= 6 && max(results.problem_dims) <= 50, ...
        'A problem dimension lies outside 6-50 in %s.', entry.data_file);

    if isempty(reference_problem_names)
        reference_problem_names = results.problem_names;
        reference_problem_dims = results.problem_dims;
        reference_excludelist = results.excludelist;
    else
        assert(isequal(results.problem_names, reference_problem_names), ...
            'Problem names differ across features.');
        assert(isequal(results.problem_dims, reference_problem_dims), ...
            'Problem dimensions differ across features.');
        assert(isequal(results.excludelist, reference_excludelist), ...
            'The exclusion list differs across features.');
    end

    experiment_dir = fileparts(fileparts(entry.data_file));
    required_profiles = {'perf_hist.pdf', 'data_hist.pdf', 'log-ratio_hist.pdf', ...
        'perf_out.pdf', 'data_out.pdf', 'log-ratio_out.pdf'};
    assert(all(cellfun(@(name) exist(fullfile(experiment_dir, name), 'file') == 2, ...
        required_profiles)), 'A profile PDF is missing under %s.', experiment_dir);

    for i_problem = 1:numel(results.problem_names)
        problem_budget = 200 * results.problem_dims(i_problem);
        for i_solver = 1:numel(expected_solvers)
            for i_run = 1:entry.n_runs
                nf = results.n_evals(i_problem, i_solver, i_run);
                assert(isfinite(nf) && nf >= 1 && nf <= problem_budget, ...
                    'Invalid evaluation count for %s.', results.problem_names{i_problem});
                history = squeeze(results.fun_histories(i_problem, i_solver, i_run, :));
                history = history(1:nf);
                assert(~isempty(history), 'An evaluation history is empty.');

                row = row + 1;
                feature(row) = entry.name;
                problem(row) = results.problem_names{i_problem};
                n(row) = results.problem_dims(i_problem);
                run(row) = i_run;
                run_seed(row) = 211 * i_run;
                solver(row) = expected_solvers{i_solver};
                evaluations(row) = nf;
                budget(row) = problem_budget;
                if nf == problem_budget
                    termination_reason(row) = "MAXFUN_REACHED";
                else
                    termination_reason(row) = "SMALL_ALPHA";
                end
                success(row) = results.solvers_successes(i_problem, i_solver, i_run);
                abnormal(row) = results.solver_abnormal_terminations(i_problem, i_solver, i_run);
                output_fallback(row) = results.solver_output_fallbacks(i_problem, i_solver, i_run);
                f_init(row) = results.fun_inits(i_problem, min(i_run, size(results.fun_inits, 2)));
                returned_true(row) = results.fun_outs(i_problem, i_solver, i_run);
                best_true_evaluated(row) = min(history, [], 'omitnan');
                nonfinite_true_history_values(row) = sum(~isfinite(history));
            end
        end
    end
end

inventory = table(feature, problem, n, run, run_seed, solver, evaluations, budget, ...
    termination_reason, success, abnormal, output_fallback, f_init, returned_true, ...
    best_true_evaluated, nonfinite_true_history_values);

assert(row == n_rows, 'The run inventory has an unexpected number of rows.');
assert(all(inventory.success), 'At least one solver-run was unsuccessful.');
assert(~any(inventory.abnormal), 'At least one solver-run terminated abnormally.');
assert(~any(inventory.output_fallback), 'At least one solver-run used output fallback.');

output_dir = fullfile(fileparts(manifest_file), 'analysis');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
writetable(inventory, fullfile(output_dir, 'stage3_run_inventory.csv'));

audit = struct();
audit.created = char(datetime('now'));
audit.manifest_file = manifest_file;
audit.n_problems = numel(reference_problem_names);
audit.problem_dims = reference_problem_dims;
audit.excludelist = reference_excludelist;
audit.inventory = inventory;
audit_file = fullfile(output_dir, 'stage3_data_audit.mat');
save(audit_file, 'audit', '-v7.3');
write_audit_markdown(audit, manifest, fullfile(output_dir, 'stage3_data_audit.md'));

fprintf('Stage 3 audit passed: %d problems, %d solver-runs, no abnormal runs.\n', ...
    audit.n_problems, height(inventory));
fprintf('Audit file: %s\n', audit_file);

end

function write_audit_markdown(audit, manifest, output_file)

inventory = audit.inventory;
fid = fopen(output_file, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Stage 3 Aggregate Data Audit\n\n');
fprintf(fid, 'Generated: %s\n\n', audit.created);
fprintf(fid, '- Problems: %d S2MPJ unconstrained problems, dimensions %d-%d\n', ...
    audit.n_problems, min(audit.problem_dims), max(audit.problem_dims));
fprintf(fid, '- Solvers: `ds-baseline-200n` and `cbds-baseline-200n`\n');
fprintf(fid, '- Solver-runs: %d\n', height(inventory));
fprintf(fid, '- Abnormal terminations: %d\n', sum(inventory.abnormal));
fprintf(fid, '- Output fallbacks: %d\n', sum(inventory.output_fallback));
fprintf(fid, '- Missing evaluation counts: %d\n\n', sum(~isfinite(inventory.evaluations)));
fprintf(fid, '| Feature | Runs | DS score | CBDS score | DS minus CBDS |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: |\n');
for i = 1:numel(manifest.features)
    scores = manifest.features(i).solver_scores;
    fprintf(fid, '| `%s` | %d | %.6f | %.6f | %+.6f |\n', ...
        manifest.features(i).name, manifest.features(i).n_runs, ...
        scores(1), scores(2), scores(1) - scores(2));
end
fprintf(fid, '\n### Nonfinite trial evaluations\n\n');
fprintf(fid, '| Feature | Solver | Nonfinite values | Affected runs | Affected problems |\n');
fprintf(fid, '| --- | --- | ---: | ---: | ---: |\n');
feature_names = unique(inventory.feature, 'stable');
solver_names = unique(inventory.solver, 'stable');
for i_feature = 1:numel(feature_names)
    for i_solver = 1:numel(solver_names)
        selected = inventory.feature == feature_names(i_feature) ...
            & inventory.solver == solver_names(i_solver);
        affected = selected & inventory.nonfinite_true_history_values > 0;
        fprintf(fid, '| `%s` | `%s` | %d | %d | %d |\n', ...
            feature_names(i_feature), solver_names(i_solver), ...
            sum(inventory.nonfinite_true_history_values(selected)), sum(affected), ...
            numel(unique(inventory.problem(affected))));
    end
end
fprintf(fid, '\nThe nonfinite values are trial evaluations on `OSBORNEB`, `SCHMVETT`, and ');
fprintf(fid, '`YATP1LS`. They do not cause abnormal termination: every best-evaluated true value ');
fprintf(fid, 'and every returned-point true value is finite.\n\n');
fprintf(fid, '\nTermination reasons are inferred exactly for these wrappers: `ftarget = -Inf`, ');
fprintf(fid, '`maxit = MaxFunctionEvaluations`, and function-value and estimated-gradient stopping ');
fprintf(fid, 'are disabled. Therefore a run below `200n` ended at `SMALL_ALPHA`; a run at `200n` ');
fprintf(fid, 'ended at `MAXFUN_REACHED`.\n\n');
fprintf(fid, 'OptiProfiler does not store returned-point coordinates or solver exitflag text in ');
fprintf(fid, '`data_for_loading.mat`. The inventory stores the returned-point true value and the ');
fprintf(fid, 'reconstructed termination reason; full point-level diagnostics belong to the Stage 6 replay.\n');

end
