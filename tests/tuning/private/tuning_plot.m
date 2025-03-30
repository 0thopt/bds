function tuning_plot(perfs, p1, p2, param1_name, param2_name, mindim, maxdim, feature_name, data_path, feature_str, log_color)

if nargin < 11
    log_color = false;
end

% Plot
param1_name = strrep(param1_name, '_', '-');
param2_name = strrep(param2_name, '_', '-');
FigHandle=figure('Name', ['(', param1_name, ', ', param2_name, ')', ' v.s. performance']);
hold on;

colormap(jet);

if log_color
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

% Set x-axis ticks and labels dynamically based on p1
set_dynamic_ticks(param1_name, p1, 'x');

% Set y-axis ticks and labels dynamically based on p2
set_dynamic_ticks(param2_name, p2, 'y');

titleHandle = title(gca, strrep(feature_str, '_', '-')); 
xlabel(param1_name);
ylabel(param2_name);

% Adjust title position
set(titleHandle, 'Units', 'normalized');
titlePosition = get(titleHandle, 'Position');
titlePosition(2) = titlePosition(2) + 0.015; % Adjust this value as needed
set(titleHandle, 'Position', titlePosition);

colorbar; 

% Fist checkout the number of points to be plotted. If there are more than 10 points, plot the top 10 points.
% If there are less than 10 points more than 5 points, plot the top 5 points.
% If there are less than 5 points, plot the top 3 points.
if numel(perfs) > 10
    [~, idx] = maxk(perfs(:), 10);
elseif numel(perfs) > 5
    [~, idx] = maxk(perfs(:), 5);
else
    [~, idx] = maxk(perfs(:), 3);
end

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
saveas(FigHandle, fullfile(data_path, [param1_name, '_', param2_name, '_', num2str(mindim), '_', num2str(maxdim), '_', feature_name, '.fig']), 'fig');
% Use openfig to open the fig file.
% openfig('my3DPlot.fig');
% Save eps of 3d plot 
saveas(FigHandle, fullfile(data_path, [param1_name, '_', param2_name, '_', num2str(mindim), '_', num2str(maxdim), '_', feature_name, '.eps']), 'epsc');
% Save pdf of 3d plot
print(FigHandle, fullfile(data_path, [param1_name, '_', param2_name, '_', num2str(mindim), '_', num2str(maxdim), '_', feature_name, '.pdf']), '-dpdf');
% Try converting the eps to pdf.
% epsPath = fullfile(data_path, [param1_name, '_', param2_name, '_vs_performance_3d.eps']);
% % One way to convert eps to pdf, without showing the output of the command.
% system(('epstopdf '+epsPath+' 2> /dev/null'));

% Save eps of 2d plot 
view(2); % Top-down view
% Save fig
saveas(FigHandle, fullfile(data_path, [param1_name, '_', param2_name, '_', num2str(mindim), '_', num2str(maxdim), '_', feature_name, '_3d.fig']), 'fig');
% Save eps of 2d plot
saveas(FigHandle, fullfile(data_path, [param1_name, '_', param2_name, '_', num2str(mindim), '_', num2str(maxdim), '_', feature_name, '_3d.eps']), 'epsc');
% Save pdf of 2d plot
print(FigHandle, fullfile(data_path, [param1_name, '_', param2_name, '_', num2str(mindim), '_', num2str(maxdim), '_', feature_name, '_3d.pdf']), '-dpdf');
% Try converting the eps to pdf.
% epsPath = fullfile(data_path, [param1_name, '_', param2_name, '_vs_performance_2d.eps']);
% % One way to convert eps to pdf, without showing the output of the command.
% system(('epstopdf '+epsPath+' 2> /dev/null'));


fprintf('Performance data and plots saved in \n %s\n', data_path);

end

function set_dynamic_ticks(param_name, data, axis)
    switch param_name
        case 'expand'
            ticks = min(data(:)):0.05:max(data(:));
            labels = arrayfun(@(x) sprintf('%.2f', x), ticks, 'UniformOutput', false);
        case 'shrink'
            ticks = min(data(:)):0.05:max(data(:));
            labels = arrayfun(@(x) sprintf('%.2f', x), ticks, 'UniformOutput', false);
        case 'window-size'
            % Set the ticks to be integers
            ticks = min(data(:)):1:max(data(:));
            labels = arrayfun(@(x) sprintf('%d', x), ticks, 'UniformOutput', false);
        case {'func-tol', 'dist-tol', 'grad-tol-1', 'grad-tol-2'}
            % Set the ticks to be powers of 10
            ticks = logspace(log10(min(data(:))), log10(max(data(:))), 9);
            labels = arrayfun(@(x) sprintf('10^{%d}', round(log10(x))), ticks, 'UniformOutput', false);
        otherwise
            ticks = linspace(min(data(:)), max(data(:)), 5);
            labels = arrayfun(@(x) sprintf('%.2g', x), ticks, 'UniformOutput', false);
    end

    if strcmp(axis, 'x')
        xticks(ticks);
        xticklabels(labels);
    elseif strcmp(axis, 'y')
        yticks(ticks);
        yticklabels(labels);
    else
        error('Unknown axis: %s', axis);
    end
end