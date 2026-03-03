function fval = eval_profile_obj(x, plibs, mindim, maxdim, is_noisy)

    % Define parameters for both tuning and default solvers
    tune_params.expand = [x(1), 2.0];
    tune_params.shrink = [x(2), 0.5];
    
    % Configure options for the profiler
    options = struct();
    options.solver_names = {'cbds-tuning', 'cbds-default'};
    options.plibs = plibs;
    options.mindim = mindim;
    options.maxdim = maxdim;
    options.score_only = true;

    if ~is_noisy
        % Evaluate the no noise features
        options.feature_name = 'plain';
        scores_plain = tuning_optiprofiler(tune_params, options);
        ratio_plain = scores_plain(1) / scores_plain(2);

        % Evaluate the linearly transformed feature
        options.feature_name = 'linearly_transformed';
        scores_trans = tuning_optiprofiler(tune_params, options);
        ratio_trans = scores_trans(1) / scores_trans(2);

        % Return the objective value for minimization. 
        fval = -min(ratio_plain, ratio_trans);
    else
        % Evaluate the noisy features
        options_perfprof.n_runs = 3;

        options_perfprof.feature_name = 'noisy_1e-3';
        scores_noisy_1e_3 = tuning_optiprofiler(parameters_perfprof, options_perfprof);
        ratio_noisy_1e_3 = scores_noisy_1e_3(1) / scores_noisy_1e_3(2);

        options_perfprof.feature_name = 'noisy_1e-7';
        scores_noisy_1e_7 = tuning_optiprofiler(parameters_perfprof, options_perfprof);
        ratio_noisy_1e_7 = scores_noisy_1e_7(1) / scores_noisy_1e_7(2);

        options_perfprof.feature_name = 'rotation_noisy_1e-3';
        scores_rotation_noisy_1e_3 = tuning_optiprofiler(parameters_perfprof, options_perfprof);
        ratio_rotation_noisy_1e_3 = scores_rotation_noisy_1e_3(1) / scores_rotation_noisy_1e_3(2);

        options_perfprof.feature_name = 'rotation_noisy_1e-7';
        scores_rotation_noisy_1e_7 = tuning_optiprofiler(parameters_perfprof, options_perfprof);
        ratio_rotation_noisy_1e_7 = scores_rotation_noisy_1e_7(1) / scores_rotation_noisy_1e_7(2);

        % Return the objective value for minimization.
        fval = -min([ratio_noisy_1e_3, ratio_noisy_1e_7, ratio_rotation_noisy_1e_3, ratio_rotation_noisy_1e_7]);
    end

end