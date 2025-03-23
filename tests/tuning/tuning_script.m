clear all
parameters.window_size = 10:2:20;
% parameters.window_size = 20;
% parameters.dist_tol = 10.^(-6:-2:-12);
parameters.func_tol = 10.^(-4:-2:-16);
% parameters.grad_tol_1 = 10.^(-6:-2:-12);
% parameters.grad_tol_2 = 10.^(-6:-2:-12);
% parameters.expand = 1.2:0.1:1.8;
% parameters.shrink = 0.5:0.1:0.7;
options.mindim = 6;
options.maxdim = 50;
if ~isfield(options, 'n_runs')
    options.n_runs = 1;
end
options.p_type = 'u';
% tau_weights should be a 2xmax_tol_orderx2x3 numeric array, where the sum of all 
% elements is 1. Normally, the max_tol_order is set to be 10.
if ~isfield(options, 'max_tol_order')
    options.max_tol_order = 10;
end
% To improve the score of output-base performance profile, we can set the value of
% last two elements of tau_weights(1, 1:max_tol_order, 2, 1) is 0.02 and the value of
% the first 1:max_tol_order-2 elements is 0.96/(max_tol_order-2). The rest of the elements
% in tau_weights are set to 0.
options.tau_weights = zeros(2, options.max_tol_order, 2, 3);
options.tau_weights(1, 1:options.max_tol_order, 2, 1) = [0.96/(options.max_tol_order-2)*ones(1, options.max_tol_order-2), 0.02, 0.02]; 
if sum(options.tau_weights(:)) ~= 1
    error('Sum of tau_weights must be 1');
end
% Check if max_tol_order is equal to the length of tau_weights.
if  (options.max_tol_order ~= size(options.tau_weights, 2))
    error('max_tol_order must be equal to the length of tau_weights');
end

% options.feature_name = 'plain';
% fprintf('Feature:\t %s\n', options.feature_name);
% tuning_script_optiprofiler(parameters, options);

% options.feature_name = 'linearly_transformed';
% fprintf('Feature:\t %s\n', options.feature_name);
% tuning_script_optiprofiler(parameters, options);

options.feature_name = 'noisy_1e-3';
fprintf('Feature:\t %s\n', options.feature_name);
tuning_script_optiprofiler(parameters, options);

% options.feature_name = 'rotation_noisy_1e-3';
% fprintf('Feature:\t %s\n', options.feature_name);
% tuning_script_optiprofiler(parameters, options);

