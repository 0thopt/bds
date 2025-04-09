clear all
parameters.func_window_size = [3 5 8 10 12 15];
% parameters.window_size = [3 5 8];
% parameters.grad_window_size = 10:2:14;
parameters.func_tol = 10.^([-15 -12 -10 -8 -5 -3]);
parameters.func_tol_ratio = 1e-2;
% parameters.grad_tol = 10.^(-4:-2:-8);
% parameters.grad_tol_ratio = 1e-3;
% parameters.orthogonal_directions = true;
% parameters.grad_tol_1 = 10.^(-4:-2:-14);
% parameters.grad_tol_2 = 10.^(-4:-2:-14);
% parameters.expand = 1.2:0.1:1.8;
% parameters.shrink = 0.5:0.1:0.7;
options.mindim = 1;
options.maxdim = 1;
if ~isfield(options, 'n_runs')
    options.n_runs = 1;
end
options.ptype = 'u';
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
options.tau_weights(1, 1:options.max_tol_order, 2, 1) = [0.9/(options.max_tol_order-4)*ones(1, options.max_tol_order-4), 0.025, 0.025, 0.025, 0.025]; 
if sum(options.tau_weights(:)) ~= 1
    error('Sum of tau_weights must be 1');
end
% Check if max_tol_order is equal to the length of tau_weights.
if  (options.max_tol_order ~= size(options.tau_weights, 2))
    error('max_tol_order must be equal to the length of tau_weights');
end
options.score_only = false;

options.feature_name = 'plain';
fprintf('Feature:\t %s\n', options.feature_name);
tuning_script_optiprofiler(parameters, options);

% options.feature_name = 'linearly_transformed';
% fprintf('Feature:\t %s\n', options.feature_name);
% tuning_script_optiprofiler(parameters, options);

% options.feature_name = 'noisy_1e-3';
% fprintf('Feature:\t %s\n', options.feature_name);
% tuning_script_optiprofiler(parameters, options);

% options.feature_name = 'rotation_noisy_1e-3';
% fprintf('Feature:\t %s\n', options.feature_name);
% tuning_script_optiprofiler(parameters, options);

