clear all;
parameters = struct();
% parameters.expand = 1.25:0.25:5;
% parameters.shrink = [0.2:0.1:0.5, 0.55:0.05:0.9];
% parameters.window_size = 10:5:20;
parameters.window_size = 10;
% parameters.func_tol = 10.^(-6:-2:-12);
% parameters.dist_tol = 10.^(-6:-2:-12);
% parameters.func_tol = 10.^(-6:-2:-8);
parameters.grad_tol_1 = 10.^(-6:-2:-12);
parameters.grad_tol_2 = 10.^(-6:-2:-12);
fields = fieldnames(parameters);
for i = 1:length(fields)
    field = fields{i};
    fprintf('num_%s = %d;\n', field, length(parameters.(field)));
end

solver = 'cbds';
competitor = 'cbds-development';

options = struct();
options.mindim = 1;
options.maxdim = 1;
options.tau_indices = 1:10;
options.p_type = 'u';
options.tau_weights = [0.12*ones(1, 8) 0.02 0.02];
if sum(options.tau_weights) ~= 1
    error('Sum of tau_weights must be 1');
end
if  length(options.tau_indices) ~= length(options.tau_weights)
    error('Length of tau_indices and tau_weights must be the same');
end
options.is_stopping_criterion = true;
options.draw_plots = false;

options.feature_name = 'plain';
fprintf('Feature:\t %s\n', options.feature_name);
options.n_runs = 1;
plot_parameters_optiprofiler(parameters, solver, competitor, options);   

% options.feature_name = 'linearly_transformed';
% fprintf('Feature:\t %s\n', options.feature_name);
% options.n_runs = 3;
% plot_parameters_optiprofiler(parameters, solver, competitor, options);   

% options.feature_name = 'noisy_1e-3';
% fprintf('Feature:\t %s\n', options.feature_name);
% options.n_runs = 3;
% plot_parameters_optiprofiler(parameters, solver, competitor, options);   

% options.feature_name = 'rotation_noisy_1e-3';
% fprintf('Feature:\t %s\n', options.feature_name);
% options.n_runs = 3;
% plot_parameters_optiprofiler(parameters, solver, competitor, options);   

