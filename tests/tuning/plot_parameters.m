function plot_parameters(parameters, solver, competitor, options)
% parameters: a structure with two fields; the field names are the names of the parameters; for each
% field, the value is a vector representing the values of the corresponding parameter.
% solver: a string representing the solver whose performance is to be evaluated.
% competitor: a string representing the competitor solver.
% options: a structure representing the options to be passed to the performance function.

% Get parameter names
param_names = fieldnames(parameters);
assert(length(param_names) == 2, 'There should be two parameters.');
param1_name = param_names{1};
param2_name = param_names{2};

% Create a grid of parameter values
[p1, p2] = meshgrid(parameters.(param1_name), parameters.(param2_name));

% Initialize performance matrix
perfs = NaN(size(p1));
% Initialize performance matrix for saving
perfs_saved = cell(size(p1, 1), size(p1, 2));

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

    % Compute performance
    fprintf('Evaluating performance for %s = %f, %s = %f\n', param1_name, p1(ip), param2_name, p2(ip));
    [perfs(ip), perfs_saved{ip}] = eval_performance(solver, competitor, local_options);
end

% We save the results in the `data_path` folder. 
current_path = fileparts(mfilename("fullpath"));
% Create the folder if it does not exist.
data_path = fullfile(current_path, "tuning_data");
if ~exist(data_path, 'dir')
    mkdir(data_path);
end
% Creat a subfolder stamped with the current time for the current test. 
time_str = char(datetime('now', 'Format', 'yy_MM_dd_HH_mm'));
feature_str = [char(solver), '_vs_', char(competitor), '_', num2str(options.mindim), '_', ...
                num2str(options.maxdim), '_', char(options.feature), '_', char(options.test_type)];
data_path_name = [feature_str, '_', time_str];
data_path = fullfile(data_path, data_path_name);
mkdir(data_path);

% Save performance data 
save(fullfile(data_path, 'performance_data.mat'), 'p1', 'p2', 'perfs', 'perfs_saved');

% Save options into a mat file.
save(fullfile(data_path, 'options.mat'), 'options');
% Save options into a txt file.
fileID = fopen(fullfile(data_path, 'options.txt'), 'w');
fprintf(fileID, 'options.mindim = %d;\n', options.mindim);
fprintf(fileID, 'options.maxdim = %d;\n', options.maxdim);
fprintf(fileID, 'options.test_type = "%s";\n', options.test_type);
fprintf(fileID, 'options.tau_weights = [%s];\n', num2str(options.tau_weights));
fprintf(fileID, 'options.feature = "%s";\n', options.feature);
fprintf(fileID, 'options.num_random = %d;\n', options.num_random);
fprintf(fileID, 'options.tau_indices = [%s];\n', num2str(options.tau_indices));
fprintf(fileID, 'options.plot_weights = %s;\n', func2str(options.plot_weights));
fclose(fileID);

% Save the parameters into a mat file.
save(fullfile(data_path, 'parameters.mat'), 'parameters');
% Save the parameters into a txt file.
fileID = fopen(fullfile(data_path, 'parameters.txt'), 'w');
fprintf(fileID, 'parameters.%s = [%s];\n', param1_name, num2str(parameters.(param1_name)));
fprintf(fileID, 'parameters.%s = [%s];\n', param2_name, num2str(parameters.(param2_name)));
fclose(fileID);

% Plot
FigHandle=figure('Name', ['(', param1_name, ', ', param2_name, ')', ' v.s. performance']);
hold on;

colormap(jet);

if isfield(options, 'log_color') && options.log_color
    % Use log scale of perfs for a better usage of the color spectrum.
    max_perf = max(perfs(:));
    min_perf = min(perfs(:));
    C = min_perf + (max_perf - min_perf) .* log(perfs - min_perf + 1) ./ log(max_perf - min_perf + 1);
    surf(p1, p2, perfs, C, 'FaceColor','interp');
else
    surf(p1, p2, perfs, 'FaceColor','interp');
end

title(gca, strrep(feature_str, '_', '-')); 
xlabel(param1_name);
ylabel(param2_name);

colorbar; 

% Find the top 10 maximum values
[~, idx] = maxk(perfs(:), 10); % Find the indices of the top 10 maximum values

% Set larger marker size
markerSize = 12; % Increase marker size
plot3(p1(idx), p2(idx), perfs(idx), 'o', 'MarkerSize', markerSize, ...
      'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k'); % Black solid circle

% Set larger font size for the labels
labelFontSize = 12; % Increase font size for the labels

% Add text labels for the top 10 points at the center of the markers
for i = 1:length(idx)
    % Place the label exactly on the point
    text(p1(idx(i)), p2(idx(i)), perfs(idx(i)), num2str(i), ...
         'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center', ...
         'Color', 'w', 'FontSize', labelFontSize, 'FontWeight', 'bold');
end

view(3) % 3D view
% Save fig
saveas(FigHandle, fullfile(data_path, [param1_name, '_', param2_name, '_vs_performance_3d.fig']), 'fig');
% Use openfig to open the fig file.
% openfig('my3DPlot.fig');
% Save eps of 3d plot 
saveas(FigHandle, fullfile(data_path, [param1_name, '_', param2_name, '_vs_performance_3d.eps']), 'epsc');
% Try converting the eps to pdf.
epsPath = fullfile(data_path, [param1_name, '_', param2_name, '_vs_performance_3d.eps']);
% One way to convert eps to pdf, without showing the output of the command.
system(('epstopdf '+epsPath+' 2> /dev/null'));

% Save eps of 2d plot 
view(2); % Top-down view
% Save fig
saveas(FigHandle, fullfile(data_path, [param1_name, '_', param2_name, '_vs_performance_2d.fig']), 'fig');
% Save eps of 2d plot
saveas(FigHandle, fullfile(data_path, [param1_name, '_', param2_name, '_vs_performance_2d.eps']), 'epsc');
% Try converting the eps to pdf.
epsPath = fullfile(data_path, [param1_name, '_', param2_name, '_vs_performance_2d.eps']);
% One way to convert eps to pdf, without showing the output of the command.
system(('epstopdf '+epsPath+' 2> /dev/null'));


fprintf('Performance data and plots saved in \n %s\n', data_path);

end
