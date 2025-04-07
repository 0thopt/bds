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
    if ~isfield(options, 'draw_plots')
        options.draw_plots = false;
    end

    baseline_params_defaults = struct(...
        'func_window_size', 1e8, ...
        'func_tol', 1e-30, ...
        'func_tol_ratio', 1e-30, ...
        'func_tol_1', 1e-30, ...
        'func_tol_2', 1e-30, ...
        'grad_window_size', 1e8, ...
        'grad_tol', 1e-30, ...
        'grad_tol_ratio', 1e-30, ...
        'grad_tol_1', 1e-30, ...
        'grad_tol_2', 1e-30, ...
        'expand', 2, ...
        'shrink', 0.5);
    fields_to_check = {'func_window_size', 'func_tol', 'func_tol_ratio', 'func_tol_1', ...
        'func_tol_2', 'grad_window_size', 'grad_tol', 'grad_tol_ratio', ...
        'grad_tol_1', 'grad_tol_2', 'expand', 'shrink'};
    for i = 1:length(fields_to_check)
        field = fields_to_check{i};
        if isfield(parameters, field)
            if ~isfield(parameters, 'baseline_params')
                parameters.baseline_params = struct();
            end
            if ~isfield(parameters.baseline_params, field)
                parameters.baseline_params.(field) = baseline_params_defaults.(field);
            end
        end
    end
    
    plot_parameters_optiprofiler(parameters, options);
end