function manifest_file = run_ds_vs_cbds_high_noise_aggregate(options)
%RUN_DS_VS_CBDS_HIGH_NOISE_AGGREGATE runs the aggregate investigation cases.

if nargin < 1
    options = struct();
end

path_tests = fileparts(mfilename('fullpath'));
addpath(path_tests);

options = set_default(options, 'mindim', 6);
options = set_default(options, 'maxdim', 50);
options = set_default(options, 'features', {'plain', 'noisy_1e-2', 'noisy_1e-1'});
options = set_default(options, 'problem_names', {});
options = set_default(options, 'seed', 0);
options = set_default(options, 'n_jobs', []);
options = set_default(options, 'solver_verbose', 1);
options = set_default(options, 'label', 'primary');

timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
default_savepath = fullfile(path_tests, 'testdata', ...
    ['ds_vs_cbds_high_noise_', options.label, '_', timestamp]);
options = set_default(options, 'savepath', default_savepath);
if ~exist(options.savepath, 'dir')
    mkdir(options.savepath);
end

manifest = struct();
manifest.started = char(datetime('now'));
manifest.timestamp = timestamp;
manifest.options = options;
manifest.solver_names = {'ds-baseline-200n', 'cbds-baseline-200n'};
manifest.features = struct('name', {}, 'n_runs', {}, 'solver_scores', {}, ...
    'profile_scores', {}, 'data_file', {}, 'summary_file', {}, ...
    'started', {}, 'finished', {});

manifest_file = fullfile(options.savepath, 'aggregate_manifest.mat');
save(manifest_file, 'manifest');

for i_feature = 1:numel(options.features)
    feature_name = char(options.features{i_feature});
    n_runs = runs_for_feature(feature_name);
    before_data = recursive_files(options.savepath, 'data_for_loading.mat');

    profile_options = struct();
    profile_options.mindim = options.mindim;
    profile_options.maxdim = options.maxdim;
    profile_options.plibs = 's2mpj';
    profile_options.feature_name = feature_name;
    profile_options.feature_display_name = feature_name;
    profile_options.n_runs = n_runs;
    profile_options.solver_names = manifest.solver_names;
    profile_options.savepath = options.savepath;
    profile_options.max_eval_factor = 200;
    profile_options.seed = options.seed;
    profile_options.run_plain = false;
    profile_options.draw_hist_plots = 'none';
    profile_options.summarize_performance_profiles = true;
    profile_options.summarize_data_profiles = false;
    profile_options.summarize_log_ratio_profiles = false;
    profile_options.summarize_output_based_profiles = false;
    profile_options.solver_verbose = options.solver_verbose;
    if ~isempty(options.problem_names)
        profile_options.problem_names = options.problem_names;
    end
    if ~isempty(options.n_jobs)
        profile_options.n_jobs = options.n_jobs;
    end

    fprintf('\n[%s] Aggregate feature %d/%d: %s (n_runs=%d)\n', ...
        char(datetime('now')), i_feature, numel(options.features), feature_name, n_runs);
    feature_started = char(datetime('now'));
    [solver_scores, profile_scores] = profile_optiprofiler(profile_options);
    feature_finished = char(datetime('now'));

    data_file = newest_new_file(options.savepath, 'data_for_loading.mat', before_data);
    summary_file = summary_for_data_file(data_file);

    entry = struct();
    entry.name = feature_name;
    entry.n_runs = n_runs;
    entry.solver_scores = solver_scores;
    entry.profile_scores = profile_scores;
    entry.data_file = data_file;
    entry.summary_file = summary_file;
    entry.started = feature_started;
    entry.finished = feature_finished;
    manifest.features(end + 1) = entry; %#ok<AGROW>
    save(manifest_file, 'manifest', '-v7.3');

    fprintf('[%s] Finished %s. Scores: DS=%.6f, CBDS=%.6f\n', ...
        char(datetime('now')), feature_name, solver_scores(1), solver_scores(2));
    fprintf('Raw data: %s\n', data_file);
end

manifest.finished = char(datetime('now'));
save(manifest_file, 'manifest', '-v7.3');
fprintf('\nAggregate manifest: %s\n', manifest_file);

end

function options = set_default(options, name, value)
if ~isfield(options, name) || isempty(options.(name))
    options.(name) = value;
end
end

function n_runs = runs_for_feature(feature_name)
if strcmpi(feature_name, 'plain')
    n_runs = 1;
else
    n_runs = 5;
end
end

function paths = recursive_files(root, filename)
listing = dir(fullfile(root, '**', filename));
paths = arrayfun(@(f) fullfile(f.folder, f.name), listing, 'UniformOutput', false);
end

function path = newest_new_file(root, filename, before)
listing = dir(fullfile(root, '**', filename));
paths = arrayfun(@(f) fullfile(f.folder, f.name), listing, 'UniformOutput', false);
is_new = ~ismember(paths, before);
listing = listing(is_new);
if isempty(listing)
    error('run_ds_vs_cbds_high_noise_aggregate:MissingData', ...
        'No new %s was created under %s.', filename, root);
end
[~, index] = max([listing.datenum]);
path = fullfile(listing(index).folder, listing(index).name);
end

function summary_file = summary_for_data_file(data_file)
experiment_dir = fileparts(fileparts(data_file));
summary_file = fullfile(experiment_dir, 'summary.pdf');
if ~exist(summary_file, 'file')
    listing = dir(fullfile(experiment_dir, 'summary_*.pdf'));
    if isempty(listing)
        summary_file = '';
    else
        [~, index] = max([listing.datenum]);
        summary_file = fullfile(listing(index).folder, listing(index).name);
    end
end
end
