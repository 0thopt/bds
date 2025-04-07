function plot_parameters_optiprofiler(parameters, options)
% parameters: a structure with two fields; the field names are the names of the parameters; for each
% field, the value is a vector representing the values of the corresponding parameter.
% options: a structure representing the options to be passed to the performance function.

% Get parameter names
param_names = fieldnames(parameters);

% Check if param_names contains the required fields for each combination
if all(ismember({'grad_tol', 'grad_window_size', 'grad_tol_ratio'}, param_names))
    param1_name = 'grad_window_size';
    param2_name = 'grad_tol';
elseif all(ismember({'func_tol', 'func_window_size', 'func_tol_ratio'}, param_names))
    param1_name = 'func_window_size';
    param2_name = 'func_tol';
elseif all(ismember({'expand', 'shrink'}, param_names))
    param1_name = 'expand';
    param2_name = 'shrink';
else
    % If param_names does not match any combination, throw an error
    error('Invalid param_names: %s. Must contain one of the predefined combinations.', mat2str(param_names));
end

% If no valid combination is found, throw an error
if isempty(param1_name) || isempty(param2_name)
    error('The parameter names provided in parameters are not valid.');
end

% Set grad_tol_ratio and func_tol_ratio if they exist
if ismember('grad_tol_ratio', param_names) && isscalar(parameters.grad_tol_ratio)
    grad_tol_ratio = parameters.grad_tol_ratio;
else
    grad_tol_ratio = [];
end
if ismember('func_tol_ratio', param_names) && isscalar(parameters.func_tol_ratio)
    func_tol_ratio = parameters.func_tol_ratio;
else
    func_tol_ratio = [];
end

% Create a grid of parameter values
[p1, p2] = meshgrid(parameters.(param1_name), parameters.(param2_name));

% Initialize performance matrix
perfs = NaN(size(p1));
% Initialize profile_scores matrix as a cell array
profile_scores = cell(size(p1));
for i = 1:numel(profile_scores)
    % The size of each element of profile_scores should be the
    % same as the size of tau_weights.
    profile_scores{i} = NaN(size(options.tau_weights));
end

if ~isfield(parameters, 'baseline_params')
    error('baseline_params must be provided in parameters');
else
    % The field names of baseline_params should be the same as the field names of parameters.
    baseline_params_names = fieldnames(parameters.baseline_params);
    if ~all(ismember(baseline_params_names, param_names))
        error('The field names of baseline_params should be the same as the field names of parameters.');
    end
end
baseline_params = parameters.baseline_params;
options.baseline_params = baseline_params;

if ~isfield(options, 'tau_weights')
    error('tau_weights must be provided in options');
else
    if ~(isnumeric(options.tau_weights) && isequal(size(options.tau_weights), [2, 10, 2, 3]))
        error('tau_weights must be a 2x10x2x3 numeric array');
    end
end
tau_weights = options.tau_weights;
options = rmfield(options, 'tau_weights');

% We save the results in the `data_path` folder. 
current_path = fileparts(mfilename("fullpath"));
% Create the folder if it does not exist.
data_path = fullfile(current_path, "tuning_data");
if ~exist(data_path, 'dir')
    mkdir(data_path);
end

% Create a subfolder stamped with the current time for the current test. 
time_str = char(datetime('now', 'Format', 'yy_MM_dd_HH_mm'));
if isfield(options, 'dim')
    if strcmpi(options.dim, 'small')
        options.mindim = 2;
        options.maxdim = 5;
    elseif strcmpi(options.dim, 'big')
        options.mindim = 6;
        options.maxdim = 50;
    end
    options = rmfield(options, 'dim');
end
feature_str = [num2str(options.mindim), '_', ...
                num2str(options.maxdim), '_', char(options.feature_name), '_', char(options.p_type)];

% Remove 'baseline_params' from param_names to decrease the length of the feature_str.
param_names = param_names(~strcmp(param_names, 'baseline_params'));
% Check if 'grad_tol_ratio' exists in param_names
if ismember('grad_tol_ratio', param_names) && ismember('grad_window_size', param_names)
    % Find the index of 'grad_tol_ratio'
    idx = strcmp(param_names, 'grad_tol_ratio');   
    % Append the value of grad_tol_ratio to the corresponding entry
    param_names{idx} = ['ratio_', sprintf('0%d', int32(-log10(parameters.grad_tol_ratio)))];
    % Remove 'grad_window_size' from param_names
    param_names = param_names(~strcmp(param_names, 'grad_window_size'));
elseif ismember('func_tol_ratio', param_names) && ismember('func_window_size', param_names)
    % Find the index of 'func_tol_ratio'
    idx = strcmp(param_names, 'func_tol_ratio');   
    % Append the value of func_tol_ratio to the corresponding entry
    param_names{idx} = ['ratio_', sprintf('0%d', int32(-log10(parameters.func_tol_ratio)))];
    % Remove 'func_window_size' from param_names
    param_names = param_names(~strcmp(param_names, 'func_window_size'));
end

param_names_str = strjoin(param_names, '_');
feature_str = [feature_str, '_', param_names_str];
data_path_name = [feature_str, '_', time_str];
data_path = fullfile(data_path, data_path_name);
mkdir(data_path);
options.savepath = data_path;

% Get performance for each parameter combination
parfor ip = 1:numel(p1)
    % Set solver options
    solver_options = struct();
    solver_options.(param1_name) = p1(ip);
    solver_options.(param2_name) = p2(ip);

    % Pass solver_options to the performance function via local_options. The performance function
    % should then pass solver_options to the solver.
    local_options = options;
    local_options.solver_options = solver_options;
    if ~isempty(grad_tol_ratio)
        local_options.grad_tol_ratio = grad_tol_ratio;
    end
    if ~isempty(func_tol_ratio)
        local_options.func_tol_ratio = func_tol_ratio;
    end
    
    % Compute performance
    fprintf('Evaluating performance for %s = %f, %s = %f\n', param1_name, p1(ip), param2_name, p2(ip));
    profile_scores{ip} = eval_performance_optiprofiler(local_options);
    perfs(ip) = tuning_score(profile_scores{ip}, tau_weights);

end

% Save performance data 
save(fullfile(data_path, 'performance_data.mat'), 'p1', 'p2', 'perfs','profile_scores')

% Save options into a mat file.
save(fullfile(data_path, 'options.mat'), 'options');
% Save options into a txt file.
fileID = fopen(fullfile(data_path, 'options.txt'), 'w');
fprintf(fileID, 'options.mindim = %d;\n', options.mindim);
fprintf(fileID, 'options.maxdim = %d;\n', options.maxdim);
fprintf(fileID, 'options.p_type = "%s";\n', options.p_type);
fprintf(fileID, 'options.feature_name = "%s";\n', options.feature_name);
fprintf(fileID, 'options.n_runs = %d;\n', options.n_runs);
fprintf(fileID, 'options.max_tol_order = [%s];\n', num2str(options.max_tol_order));
fprintf(fileID, 'options.draw_plots = %d;\n', options.draw_plots);
fclose(fileID);

% Save tau_weights into a txt file.
fileID = fopen(fullfile(data_path, 'tau_weights.txt'), 'w');
for i = 1:size(tau_weights, 2)
    fprintf(fileID, 'tau_weights(:, %d, :, :) = [\n', i);
    for j = 1:size(tau_weights, 1)
        for k = 1:size(tau_weights, 3)
            fprintf(fileID, '    [');
            for l = 1:size(tau_weights, 4)
                fprintf(fileID, '%.2f', tau_weights(j, i, k, l));
                if l < size(tau_weights, 4)
                    fprintf(fileID, ', ');
                end
            end
            fprintf(fileID, ']');
            if k < size(tau_weights, 3)
                fprintf(fileID, ',\n');
            else
                fprintf(fileID, '\n');
            end
        end
    end
    fprintf(fileID, '];\n');
end
fclose(fileID);

% Save the parameters into a mat file.
save(fullfile(data_path, 'parameters.mat'), 'parameters');
% Save the parameters into a txt file.
fileID = fopen(fullfile(data_path, 'parameters.txt'), 'w');
fprintf(fileID, 'parameters.%s = [%s];\n', param1_name, num2str(parameters.(param1_name)));
fprintf(fileID, 'parameters.%s = [%s];\n', param2_name, num2str(parameters.(param2_name)));
if length(param_names) > 2 && any(ismember('window_size', param_names))
    fprintf(fileID, 'parameters.window_size = %d;\n', window_size);
end
fclose(fileID);

% Write all the points to a txt file
fileID = fopen(fullfile(data_path, 'points.txt'), 'w');
fprintf(fileID, '%-20s %-20s %-20s\n', param1_name, param2_name, 'perf');
for i = 1:numel(p1)
    fprintf(fileID, '%-20.16f %-20.16f %-20.16f\n', p1(i), p2(i), perfs(i));
end
fclose(fileID);

% Plot the performance data
tuning_plot(perfs, p1, p2, param1_name, param2_name, options.mindim, options.maxdim, options.feature_name, data_path, feature_str);

end




