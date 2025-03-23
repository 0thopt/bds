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
    switch options.feature_name
        case 'plain'
            if ~isfield(options, 'n_runs')
                options.n_runs = 1;
            end
        case 'linearly_transformed'
            if ~isfield(options, 'n_runs')
                options.n_runs = 3;
            end
        case 'noisy_1e-3'
            if ~isfield(options, 'n_runs')
                options.n_runs = 3;
            end
        case 'rotation_noisy_1e-3'
            if ~isfield(options, 'n_runs')
                options.n_runs = 3;
            end
    end
   
    if ~isfield(options, 'p_type')
        options.p_type = 'u';
    end
    if sum(options.tau_weights(:)) ~= 1
        error('Sum of tau_weights must be 1');
    end
    if  (options.max_tol_order ~= size(options.tau_weights, 2))
        error('max_tol_order must be equal to the length of tau_weights');
    end
    options.draw_plots = false;
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