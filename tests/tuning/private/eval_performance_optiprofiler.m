function perf = eval_performance_optiprofiler(options)

    % perf = rand();
    % return

    options.n_jobs = 1;
    % parameters.draw_plots = options.draw_plots;
    options.draw_plots = false;
    parameters = options.solver_options;
    options = rmfield(options, 'solver_options');
    is_stopping_criterion = options.is_stopping_criterion;
    options = rmfield(options, 'is_stopping_criterion');
    tau_weights = options.tau_weights;
    options = rmfield(options, 'tau_weights');
    % For each field in options.baseline_params, if the field exists in parameters,
    % concatenate the baseline parameter value to the existing parameter value in parameters.
    baseline_fields = fieldnames(options.baseline_params);
    for i = 1:length(baseline_fields)
        field = baseline_fields{i};
        if isfield(parameters, field)
            % Concatenate the baseline parameter value to the existing parameter value
            parameters.(field) = [parameters.(field), options.baseline_params.(field)];
        end
    end
    options = rmfield(options, 'baseline_params');
    currentFilePath = mfilename('fullpath');
    options.savepath = fullfile(fileparts((fileparts(currentFilePath))), 'tuning_data');
    % If the field window_size exists in options, it means that we are tuning the grad_tol_1 and grad_tol_2 parameters.
    % In this case, we need to set the window_size parameter to a large value to avoid the window_size parameter to be tuned.
    if isfield(options, 'window_size')
        parameters.window_size = [options.window_size, 1e8];
        options = rmfield(options, 'window_size');
    end
    [~, profile_scores] = tuning_optiprofiler(parameters, options);
    if is_stopping_criterion
        perf = 0.5 * sum(profile_scores(1, :, 1, 1).*tau_weights) + 0.5 * sum(profile_scores(1, :, 2, 1).*tau_weights);
    else
        perf = sum(profile_scores(1, :, 1, 1).*tau_weights);
    end
    
end

