clear all
% parameters.window_size = 10:5:20;
parameters.window_size = 15;
% parameters.dist_tol = 10.^(-6:-2:-12);
% parameters.func_tol = 10.^(-6:-2:-12);
parameters.grad_tol_1 = 10.^(-6:-2:-12);
parameters.grad_tol_2 = 10.^(-6:-2:-12);
options.mindim = 6;
options.maxdim = 50;
if ~isfield(options, 'n_runs')
    options.n_runs = 1;
end
options.p_type = 'u';
options.max_tol_order = 10;
options.tau_weights = [0.12*ones(1, 8) 0.02 0.02];
if sum(options.tau_weights) ~= 1
    error('Sum of tau_weights must be 1');
end
if  (options.max_tol_order ~= length(options.tau_weights))
    error('max_tol_order must be equal to the length of tau_weights');
end
options.is_stopping_criterion = true;

options.feature_name = 'plain';
fprintf('Feature:\t %s\n', options.feature_name);
tuning_script_optiprofiler(parameters, options);

options.feature_name = 'linearly_transformed';
fprintf('Feature:\t %s\n', options.feature_name);
tuning_script_optiprofiler(parameters, options);

% options.feature_name = 'noisy_1e-3';
% fprintf('Feature:\t %s\n', options.feature_name);
% tuning_script_optiprofiler(parameters, options);

% options.feature_name = 'rotation_noisy_1e-3';
% fprintf('Feature:\t %s\n', options.feature_name);
% tuning_script_optiprofiler(parameters, options);

