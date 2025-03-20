function tuning_script_optiprofiler(parameters, options)

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
    options.feature_name = 'plain';
    switch options.feature_name
        case 'plain'
            if ~isfield(parameters, 'n_runs')
                options.n_runs = 1;
            end
        case 'linearly_transformed'
            if ~isfield(parameters, 'n_runs')
                options.n_runs = 3;
            end
        case 'noisy_1e-3'
            if ~isfield(parameters, 'n_runs')
                options.n_runs = 3;
            end
        case 'rotation_noisy_1e-3'
            if ~isfield(parameters, 'n_runs')
                options.n_runs = 3;
            end
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
    options.draw_plots = false;
    options.feature_name = 'plain';
    fprintf('Feature:\t %s\n', options.feature_name);
    % parameters.expand = [1.25 1.5];
    % parameters.shrink = [0.75 0.5];
    parameters.window_size = [10 15];
    % parameters.func_tol = [1e-4 1e-6];
    parameters.dist_tol = [1e-4 1e-6];
    % parameters.grad_tol_1 = [1e-4 1e-6];
    % parameters.grad_tol_2 = [1e-4 1e-6];
    % tuning_optiprofiler(parameters, options);
    if isfield(parameters, 'window_size') && isfield(parameters, 'func_tol')
        if ~isfield(parameters, 'baseline_params')
            parameters.baseline_params = struct('window_size', 1e5, 'func_tol', eps);
        end
    end
    if isfield(parameters, 'window_size') && isfield(parameters, 'dist_tol')
        if ~isfield(parameters, 'baseline_params')
            parameters.baseline_params = struct('window_size', 1e5, 'dist_tol', eps);
        end
    end
    if isfield(parameters, 'window_size') && isfield(parameters, 'grad_tol_1') && isfield(parameters, 'grad_tol_2')
        if ~isfield(parameters, 'baseline_params')
            parameters.baseline_params = struct('window_size', 1e5, 'grad_tol_1', eps, 'grad_tol_2', eps);
        end
    end
    if isfield(parameters, 'expand') && isfield(parameters, 'shrink')
        if ~isfield(parameters, 'baseline_params')
            parameters.baseline_params = struct('expand', 2, 'shrink', 0.5);
        end
    end
    plot_parameters_optiprofiler(parameters, options);
end