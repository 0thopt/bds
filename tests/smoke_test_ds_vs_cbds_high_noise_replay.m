function smoke_test_ds_vs_cbds_high_noise_replay()
%SMOKE_TEST_DS_VS_CBDS_HIGH_NOISE_REPLAY checks the Stage 6 file workflow.

path_tests = fileparts(mfilename('fullpath'));
source_matrix = fullfile(path_tests, 'testdata', ...
    'ds_vs_cbds_high_noise_primary_20260712_165527', 'analysis', ...
    'noise_matched_problem_ranking', 'stage5_case_selection', ...
    'stage6_targeted_replay_matrix.csv');
matrix = readtable(source_matrix, 'TextType', 'string');
matrix = matrix(matrix.problem == "COOLHANSLS" & matrix.sigma == 1e-1, :);

workdir = tempname;
mkdir(workdir);
cleanup = onCleanup(@() rmdir(workdir, 's'));
fprintf('Stage 6 smoke directory: %s\n', workdir);
matrix_file = fullfile(workdir, 'smoke_matrix.csv');
writetable(matrix, matrix_file);

options.run_indices = 1;
options.priority_tiers = 1;
options.n_jobs = 1;
options.savepath = fullfile(workdir, 'output');
manifest_file = run_ds_vs_cbds_high_noise_replay(matrix_file, options);
loaded = load(manifest_file, 'run_summary');
assert(height(loaded.run_summary) == 2);
assert(all(loaded.run_summary.success));
assert(~any(loaded.run_summary.reused));
analysis_file = analyze_ds_vs_cbds_high_noise_replay(manifest_file);
analysis = load(analysis_file, 'analysis');
assert(height(analysis.analysis.hit_table) == 1);
assert(height(analysis.analysis.trajectory_windows) == 2);
assert(height(analysis.analysis.trace_audit) == 2);
assert(all(analysis.analysis.trace_audit.complete_history));

manifest_file = run_ds_vs_cbds_high_noise_replay(matrix_file, options);
loaded = load(manifest_file, 'run_summary');
assert(all(loaded.run_summary.reused));
fprintf('PASS Stage 6 replay smoke test.\n');
end
