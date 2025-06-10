function profile_optiprofiler_multi_feature(solver_names, mindim, maxdim, feature_list)

if nargin < 4
    feature_list = {'plain', ...
        'noisy_1e-1', 'noisy_1e-2', 'noisy_1e-3', 'noisy_1e-4', ...
        'linearly_transformed', ...
        'rotation_noisy_1e-1', 'rotation_noisy_1e-2', 'rotation_noisy_1e-3', 'rotation_noisy_1e-4'...
        'perturbed_x0_0.001', 'perturbed_x0_1', 'perturbed_x0_10', 'perturbed_x0_100'};
end

% Why we need the following variable? In profile_optiprofiler.m, to distinguish different features totally and
% avoid containing hyphens in the benchmark_id, we will let different features have different name in the benchmark_id
% and use underscores instead of hyphens. For example, when the feature is 'noisy_1e-1',
% the benchmark_id will use 'noisy_1_no_rotation' as the feature_id in the benchmark_id.
feature_id_list = {'plain', ...
    'noisy_1_no_rotation', 'noisy_2_no_rotation', 'noisy_3_no_rotation', 'noisy_4_no_rotation', ...
    'linearly_transformed', ...
    'rotation_noisy_1', 'rotation_noisy_2', 'rotation_noisy_3', 'rotation_noisy_4'...
    'perturbed_x0_0_001', 'perturbed_x0_1', 'perturbed_x0_10', 'perturbed_x0_100'};

% In case that there does not exist the folder 'testdata' under the tests folder.
path_testdata = fullfile(fileparts(mfilename('fullpath')), 'testdata');
if ~exist(path_testdata, 'dir')
    mkdir(path_testdata);
end

% Create a folder to save the results under different features. The name of the folder
% is constructed by the solver names, mindim, maxdim and the current time.
solver_str = solver_names{1};
for i = 2:length(solver_names)
    solver_str = [solver_str, '_', solver_names{i}];
end
multi_feature_id = solver_str;
time_str = char(datetime('now', 'Format', 'yy_MM_dd_HH_mm'));
multi_feature_id = [multi_feature_id, '_', num2str(mindim), '_', num2str(maxdim), '_multi_feature', '_', time_str];
path_multi_feature = fullfile(path_testdata, multi_feature_id);

% Create the folder to save the summary results.
merged_str = ['merged_', solver_str, '_', num2str(mindim), '_', num2str(maxdim)];
mkdir(path_multi_feature);
path_merged = fullfile(path_multi_feature, merged_str);
mkdir(path_merged);

options.solver_names = solver_names;
options.mindim = mindim;
options.maxdim = maxdim;
options.savepath = path_multi_feature;

for i = 1:length(feature_list)
    options.feature_name = feature_list{i};
    profile_optiprofiler(options);
end

feature_folder_names = dir(path_multi_feature);
valid_feature_folder_flags = [feature_folder_names.isdir] & ~ismember({feature_folder_names.name}, {'.', '..', merged_str});
feature_dirs = {feature_folder_names(valid_feature_folder_flags).name};

for i = 1:length(feature_dirs)
    feature_folder = feature_dirs{i};
    for j = 1:length(feature_id_list)
        % Check if the feature folder contains the feature_id_list item.
        if contains(feature_folder, feature_id_list{j})
            feature_path = fullfile(path_multi_feature, feature_folder);
            merged_save_path = path_merged;
            merged_pdf_name = ['summary_', solver_str, '_', num2str(mindim), '_', num2str(maxdim), '_', feature_id_list{j}, '.pdf'];

            % Search for the summary.pdf file in the feature folder and its subfolders.
            summary_pdf_info = dir(fullfile(feature_path, '**', 'summary.pdf'));
            if ~isempty(summary_pdf_info)
                summary_pdf_src = fullfile(summary_pdf_info(1).folder, summary_pdf_info(1).name);
                summary_pdf_dst = fullfile(merged_save_path, merged_pdf_name);
                copyfile(summary_pdf_src, summary_pdf_dst);
                fprintf('Copied and renamed: %s -> %s\n', summary_pdf_src, summary_pdf_dst);
            end
        end
    end
end