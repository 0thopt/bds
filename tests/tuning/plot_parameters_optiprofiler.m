function plot_parameters_optiprofiler(parameters, solver, competitor, options)
% parameters: a structure with two fields; the field names are the names of the parameters; for each
% field, the value is a vector representing the values of the corresponding parameter.
% solver: a string representing the solver whose performance is to be evaluated.
% competitor: a string representing the competitor solver.
% options: a structure representing the options to be passed to the performance function.

% Get parameter names
param_names = fieldnames(parameters);
if ismember('window_size', param_names)
    % If there are more than two parameters, and one of them is 'window_size', the
    % length of 'window_size' should be 1.
    if length(param_names) > 2
        assert(isscalar(parameters.window_size), 'The length of window_size should be 1.');
        param_names = [param_names(~strcmp(param_names, 'window_size')); 'window_size'];
    end
    window_size = parameters.window_size;
end
param1_name = param_names{1};
param2_name = param_names{2};

% Create a grid of parameter values
[p1, p2] = meshgrid(parameters.(param1_name), parameters.(param2_name));

% Initialize performance matrix
perfs = NaN(size(p1));

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
    if length(param_names) > 2 && ismember('window_size', param_names)
        local_options.solver_options.window_size = window_size;
    end

    % Compute performance
    fprintf('Evaluating performance for %s = %f, %s = %f\n', param1_name, p1(ip), param2_name, p2(ip));
    perfs(ip) = eval_performance_optiprofiler(solver, competitor, local_options);
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
                num2str(options.maxdim), '_', char(options.feature_name), '_', char(options.p_type)];
param_names = strjoin(param_names, '_');
feature_str = [feature_str, '_', param_names];
data_path_name = [feature_str, '_', time_str];
data_path = fullfile(data_path, data_path_name);
mkdir(data_path);

% Save performance data 
save(fullfile(data_path, 'performance_data.mat'), 'p1', 'p2', 'perfs');

% Save options into a mat file.
save(fullfile(data_path, 'options.mat'), 'options');
% Save options into a txt file.
fileID = fopen(fullfile(data_path, 'options.txt'), 'w');
fprintf(fileID, 'options.mindim = %d;\n', options.mindim);
fprintf(fileID, 'options.maxdim = %d;\n', options.maxdim);
fprintf(fileID, 'options.p_type = "%s";\n', options.p_type);
fprintf(fileID, 'options.tau_weights = [%s];\n', num2str(options.tau_weights));
fprintf(fileID, 'options.feature_name = "%s";\n', options.feature_name);
fprintf(fileID, 'options.n_runs = %d;\n', options.n_runs);
fprintf(fileID, 'options.tau_indices = [%s];\n', num2str(options.tau_indices));
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

% Plot
param1_name = strrep(param1_name, '_', '-');
param2_name = strrep(param2_name, '_', '-');
FigHandle=figure('Name', ['(', param1_name, ', ', param2_name, ')', ' v.s. performance']);
hold on;

colormap(jet);

if isfield(options, 'log_color') && options.log_color
    % Use log scale of perfs for a better usage of the color spectrum.
    max_perf = max(perfs(:));
    min_perf = min(perfs(:));
    C = min_perf + (max_perf - min_perf) .* log(perfs - min_perf + 1) ./ log(max_perf - min_perf + 1);
    surf(p1, p2, perfs, C, 'FaceColor','interp', 'FaceAlpha', 0.8, ...
         'EdgeColor', [0.2 0.2 0.2], 'LineWidth', 0.5);
else
    surf(p1, p2, perfs, 'FaceColor','interp', 'FaceAlpha', 0.8, ...
         'EdgeColor', [0.2 0.2 0.2], 'LineWidth', 0.5);
end

% Set the title, x-axis and y-axis ticks
set(gca, 'XScale', 'log', 'YScale', 'log');

switch param1_name
    case 'expand'
        xticks(10.^(0:1:5));
        xticklabels(arrayfun(@(x) sprintf('10^{%d}', x), 0:1:5, 'UniformOutput', false));
    case 'shrink'
        xticks(10.^(-1:0.1:0.9));
        xticklabels(arrayfun(@(x) sprintf('10^{%d}', x), -1:0.1:0.9, 'UniformOutput', false));
    case 'window-size'
        xticks(10:5:20);
    case 'func-tol'
        xticks(10.^(-12:1:-6));
        xticklabels(arrayfun(@(x) sprintf('10^{%d}', x), -12:1:-6, 'UniformOutput', false));
    case 'dist-tol'
        xticks(10.^(-12:1:-6));
        xticklabels(arrayfun(@(x) sprintf('10^{%d}', x), -12:1:-6, 'UniformOutput', false));
    case 'grad-tol-1'
        xticks(10.^(-12:1:-6));
        xticklabels(arrayfun(@(x) sprintf('10^{%d}', x), -12:1:-6, 'UniformOutput', false));
    case 'grad-tol-2'
        xticks(10.^(-12:1:-6));
        xticklabels(arrayfun(@(x) sprintf('10^{%d}', x), -12:1:-6, 'UniformOutput', false));
    otherwise
        xticks(parameters.(param1_name));
end

switch param2_name
    case 'expand'
        yticks(1:5);
    case 'shrink'
        yticks(0.2:0.1:0.9);
    case 'window-size'
        yticks(10:5:20);
    case 'func-tol'
        yticks(10.^(-12:1:-6));
        yticklabels(arrayfun(@(x) sprintf('10^{%d}', x), -12:1:-6, 'UniformOutput', false));
    case 'dist-tol'
        yticks(10.^(-12:1:-6));
        yticklabels(arrayfun(@(x) sprintf('10^{%d}', x), -12:1:-6, 'UniformOutput', false));
    case 'grad-tol-1'
        yticks(10.^(-12:1:-6));
        yticklabels(arrayfun(@(x) sprintf('10^{%d}', x), -12:1:-6, 'UniformOutput', false));
    case 'grad-tol-2'
        yticks(10.^(-12:1:-6));
        yticklabels(arrayfun(@(x) sprintf('10^{%d}', x), -12:1:-6, 'UniformOutput', false));
    otherwise
        yticks(parameters.(param2_name));
end

titleHandle = title(gca, strrep(feature_str, '_', '-')); 
xlabel(param1_name);
ylabel(param2_name);

% Adjust title position
set(titleHandle, 'Units', 'normalized');
titlePosition = get(titleHandle, 'Position');
titlePosition(2) = titlePosition(2) + 0.015; % Adjust this value as needed
set(titleHandle, 'Position', titlePosition);

colorbar; 

% Find the top 3 maximum values
[~, idx] = maxk(perfs(:), 3);

% Write all the points to a txt file
fileID = fopen(fullfile(data_path, 'points.txt'), 'w');
fprintf(fileID, '%-20s %-20s %-20s\n', param1_name, param2_name, 'perf');
for i = 1:numel(p1)
    fprintf(fileID, '%-20.16f %-20.16f %-20.16f\n', p1(i), p2(i), perfs(i));
end
fclose(fileID);

markerSize = 10;  % Set the size of the circles
labelFontSize = 10;  % Set the font size for the labels

% Add a small offset to the z-coordinate of the points to make them visible
z_offset = (max(perfs(:)) - min(perfs(:))) * 0.001;

% Draw the top 3 points with a black circle and a black label
h_points = plot3(p1(idx), p2(idx), perfs(idx) + z_offset, 'o', 'MarkerSize', markerSize, ...
      'MarkerFaceColor', 'none', 'MarkerEdgeColor', [0.1 0.1 0.1], 'LineWidth', 1.5);

% Add labels to the top 3 points
h_text = zeros(length(idx), 1);
for i = 1:length(idx)
    h_text(i) = text(p1(idx(i)), p2(idx(i)), perfs(idx(i)) + z_offset, num2str(i), ...
         'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center', ...
         'Color', 'k', 'FontSize', labelFontSize, 'FontWeight', 'bold');
end

% Move the points and labels to the top
uistack(h_points, 'top');
for i = 1:length(h_text)
    uistack(h_text(i), 'top');
end

view(3) % 3D view
% Save fig
saveas(FigHandle, fullfile(data_path, [param1_name, '_', param2_name, '_vs_performance_3d.fig']), 'fig');
% Use openfig to open the fig file.
% openfig('my3DPlot.fig');
% Save eps of 3d plot 
saveas(FigHandle, fullfile(data_path, [param1_name, '_', param2_name, '_vs_performance_3d.eps']), 'epsc');
% Save pdf of 3d plot
print(FigHandle, fullfile(data_path, [param1_name, '_', param2_name, '_vs_performance_3d.pdf']), '-dpdf');
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
% Save pdf of 2d plot
print(FigHandle, fullfile(data_path, [param1_name, '_', param2_name, '_vs_performance_2d.pdf']), '-dpdf');
% Try converting the eps to pdf.
epsPath = fullfile(data_path, [param1_name, '_', param2_name, '_vs_performance_2d.eps']);
% One way to convert eps to pdf, without showing the output of the command.
system(('epstopdf '+epsPath+' 2> /dev/null'));


fprintf('Performance data and plots saved in \n %s\n', data_path);

end
