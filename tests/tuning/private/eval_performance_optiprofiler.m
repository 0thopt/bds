function perf = eval_performance_optiprofiler(solver, competitor, options)

    % perf = rand();
    % return

    parameters = struct();

    parameters.n_jobs = 1;
    parameters.mindim = options.mindim;
    parameters.maxdim = options.maxdim;
    parameters.n_runs = options.n_runs;
    parameters.p_type = options.p_type;
    parameters.feature_name = options.feature_name;
    % parameters.draw_plots = options.draw_plots;
    parameters.draw_plots = true;
    currentFilePath = mfilename('fullpath');
    parameters.savepath = fullfile(fileparts(fileparts(currentFilePath)), 'tuning_data');
    solver_options_list = ["expand", "shrink", "window_size", "func_tol", "dist_tol", "grad_tol_1", "grad_tol_2"];
    for i = 1:numel(solver_options_list)
        fieldName = solver_options_list(i);
        
        if isfield(options.solver_options, fieldName)
            fieldValue = options.solver_options.(fieldName);
            if fieldValue < 1
                fieldValue = strcat(char(strrep(fieldName, '_', '-')), '-', int2str(int32(-log10(fieldValue))));
            else
                fieldValue = int2str(int32(fieldValue));
            end
            solver = strcat(solver, '-', fieldValue);
        end
    end
    parameters.solver_names = {solver, competitor};
    [~, profile_scores] = profile_optiprofiler(parameters);
    if options.is_stopping_criterion
        perf = 0.5 * sum(profile_scores(1, :, 1, 1).*options.tau_weights) + 0.5 * sum(profile_scores(1, :, 2, 1).*options.tau_weights);
    else
        perf = sum(profile_scores(1, :, 1, 1).*options.tau_weights);
    end
    
end

