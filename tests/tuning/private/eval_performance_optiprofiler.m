function [profile_scores] = eval_performance_optiprofiler(options)

    options.n_jobs = 1;
    % parameters.draw_plots = options.draw_plots;
    if ~isfield(options, 'draw_plots')
        options.draw_plots = false;
    end
    parameters = options.solver_options;
    options = rmfield(options, 'solver_options');
    % For each field in options.baseline_params, if the field exists in parameters,
    % concatenate the baseline parameter value to the existing parameter value in parameters.
    % Why we should do this here? Consider the parallel computing case, we need to pass the
    % baseline parameters to every worker. However, we can't pass the baseline parameters to
    % every worker directly, because the baseline parameters are not used in the solver. So we
    % need to concatenate the baseline parameters to the existing parameters in the worker.
    baseline_fields = fieldnames(options.baseline_params);
    for i = 1:length(baseline_fields)
        field = baseline_fields{i};
        if isfield(parameters, field)
            % Concatenate the baseline parameter value to the existing parameter value
            parameters.(field) = [parameters.(field), options.baseline_params.(field)];
        end
    end
    options = rmfield(options, 'baseline_params');
    if isfield(options, 'grad_tol_ratio') && isscalar(options.grad_tol_ratio)
        parameters.grad_tol_ratio = options.grad_tol_ratio;
        options = rmfield(options, 'grad_tol_ratio');
    end
    
    [~, profile_scores] = tuning_optiprofiler(parameters, options);
    
end

