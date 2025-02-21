function profile_optiprofiler(options)

    clc

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Example 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % solvers = {@fminsearch_test, @fminunc_test};
    % benchmark(solvers)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Example 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % solvers = {@fminsearch_test, @fminunc_test};
    % benchmark(solvers, 'noisy')

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Example 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % solvers = {@fminsearch_test, @fminunc_test};
    % options.feature_name = 'noisy';
    % options.n_runs = 5;
    % options.problem = s_load('LIARWHD');
    % options.seed = 1;
    % benchmark(solvers, options)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Example 4 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if ~isfield(options, 'feature_name')
        error('Please provide the feature name');
    end
    if startsWith(options.feature_name, 'noisy')
        if sum(options.feature_name == '_') > 0
            options.noise_level = 10.^(str2double(options.feature_name(end-1:end)));
        else
            options.noise_level = 1e-3;
        end
        options.feature_name = 'noisy';
    end 
    if startsWith(options.feature_name, 'rotation_noisy')
        options.noise_level = 10.^(str2double(options.feature_name(end-1:end)));
        options.feature_name = 'custom';
    end
    if startsWith(options.feature_name, 'permuted_noisy')
        if sum(options.feature_name == '_') > 0
            options.noise_level = 10.^(str2double(options.feature_name(end-1:end)));
        else
            options.noise_level = 1e-3;
        end
        options.feature_name = 'custom';
        options.permuted = true;
    end
    if startsWith(options.feature_name, 'truncated')
        if sum(options.feature_name == '_') > 0
            options.significant_digits = str2double(options.feature_name(end));
        else
            options.significant_digits = 6;
        end
        switch options.significant_digits
            % Why we set the noise level like this? See the link below:
            % https://github.com/Lht97/to_do_list. 
            case 1
                options.noise_level = 10^(-1) / (2 * sqrt(3));
            case 2
                options.noise_level = 10^(-2) / (2 * sqrt(3));
            case 3
                options.noise_level = 10^(-3) / (2 * sqrt(3));
            case 4
                options.noise_level = 10^(-4) / (2 * sqrt(3));
            otherwise
                error('Unknown significant digits');
        end
        options.feature_name = 'truncated';
    end
    if startsWith(options.feature_name, 'quantized')
        if sum(options.feature_name == '_') > 0
            options.mesh_size = 10.^(-str2double(options.feature_name(end)));
        else
            options.mesh_size = 1e-3;
        end
        options.feature_name = 'quantized';
    end
    if startsWith(options.feature_name, 'random_nan')
        options.nan_rate = str2double(options.feature_name(find(options.feature_name == '_', 1, 'last') + 1:end)) / 100;
        options.feature_name = 'random_nan';
    end
    if startsWith(options.feature_name, 'perturbed_x0')
        if sum(options.feature_name == '_') > 1
            str = split(options.feature_name, '_');
            options.noise_level = str2double(str{end});
        else
            options.noise_level = 1e-3;
        end
        options.feature_name = 'perturbed_x0';
    end
    if ~isfield(options, 'solver_names')
        error('Please provide the solver_names for the solvers');
    end
    if isfield(options, 'test_blocks') && options.test_blocks
        options.solver_names(strcmpi(options.solver_names, 'cbds')) = {'cbds-block'};
        options.solver_names(strcmpi(options.solver_names, 'cbds-half')) = {'cbds-half-block'};
        options.solver_names(strcmpi(options.solver_names, 'cbds-quarter')) = {'cbds-quarter-block'};
        options.solver_names(strcmpi(options.solver_names, 'cbds-eighth')) = {'cbds-eighth-block'};
        options.solver_names(strcmpi(options.solver_names, 'ds')) = {'ds-block'};
        options = rmfield(options, 'test_blocks');
    end
    % Why we remove the truncated form feature adaptive? Fminunc do not know the noise level
    % such that it can not decide the step size.
    feature_adaptive = {'noisy', 'custom', 'truncated'};
    if ismember(options.feature_name, feature_adaptive)
        if ismember('fminunc', options.solver_names)
            options.solver_names(strcmpi(options.solver_names, 'fminunc')) = {'fminunc-adaptive'};
        end
        bds_Algorithms = {'ds', 'pbds', 'rbds', 'pads', 'scbds', 'cbds', 'cbds-randomized-orthogonal', 'cbds-randomized-gaussian', 'cbds-permuted', 'cbds-rotated-initial-point'};
        if any(ismember(bds_Algorithms, options.solver_names))
            options.solver_names(strcmpi(options.solver_names, 'ds')) = {'ds-noisy'};
            options.solver_names(strcmpi(options.solver_names, 'pbds')) = {'pbds-noisy'};
            options.solver_names(strcmpi(options.solver_names, 'rbds')) = {'rbds-noisy'};
            options.solver_names(strcmpi(options.solver_names, 'pads')) = {'pads-noisy'};
            options.solver_names(strcmpi(options.solver_names, 'scbds')) = {'scbds-noisy'};
            options.solver_names(strcmpi(options.solver_names, 'cbds')) = {'cbds-noisy'};
            options.solver_names(strcmpi(options.solver_names, 'cbds-randomized-orthogonal')) = {'cbds-randomized-orthogonal-noisy'};
            options.solver_names(strcmpi(options.solver_names, 'cbds-randomized-gaussian')) = {'cbds-randomized-gaussian-noisy'};
            options.solver_names(strcmpi(options.solver_names, 'cbds-permuted')) = {'cbds-permuted-noisy'};
            options.solver_names(strcmpi(options.solver_names, 'cbds-rotated-initial-point')) = {'cbds-rotated-initial-point-noisy'};
        end
    end

    if ~isfield(options, 'n_runs')
        if strcmpi(options.feature_name, 'plain') || strcmpi(options.feature_name, 'quantized')
            options.n_runs = 1;
        else
            options.n_runs = 3;
        end
    end
    if ~isfield(options, 'solver_verbose')
        options.solver_verbose = 2;
    end
    time_str = char(datetime('now', 'Format', 'yy_MM_dd_HH_mm'));
    options.silent = false;
    options.keep_pool = true;
    options.p_type = 'u';
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
    if ~isfield(options, 'mindim')
        options.mindim = 2;
    end
    if ~isfield(options, 'maxdim')
        options.maxdim = 5;
    end
    if ~isfield(options, 'run_plain')
        options.run_plain = false;
    end
    solvers = cell(1, length(options.solver_names));
    for i = 1:length(options.solver_names)
        switch options.solver_names{i}
            case 'fminunc-adaptive'
                solvers{i} = @(fun, x0) fminunc_adaptive(fun, x0, options.noise_level);
            case 'fminunc'
                solvers{i} = @fminunc_test;
            case 'fminsearch'
                solvers{i} = @fminsearch_test;
            case 'ds'
                solvers{i} = @ds_test;
            case 'ds-block'
                solvers{i} = @ds_block_test;
            case 'ds-noisy'
                solvers{i} = @(fun, x0) ds_test_noisy(fun, x0, true);
            case 'pbds'
                solvers{i} = @pbds_test;
            case 'pbds-noisy'
                solvers{i} = @(fun, x0) pbds_test_noisy(fun, x0, true);
            case 'pbds-orig'
                solvers{i} = @pbds_orig_test;
            case 'rbds'
                solvers{i} = @rbds_test;
            case 'rbds-noisy'
                solvers{i} = @(fun, x0) rbds_test_noisy(fun, x0, true);
            % r0d means the replacement delay is zero.
            case 'r0d'
                solvers{i} = @rbds_zero_delay_test;
            % r1d means the replacement delay is one.
            case 'r1d'
                solvers{i} = @rbds_one_delay_test;
            % rend means the replacement delay is equal to the eighth of the dimension of the problem.
            case 'rend'
                solvers{i} = @rbds_eighth_delay_test;
            % rqnd means the replacement delay is equal to the quarter of the dimension of the problem.
            case 'rqnd'
                solvers{i} = @rbds_quarter_delay_test;
            % rhnd means the replacement delay is equal to the half of the dimension of the problem.
            case 'rhnd'
                solvers{i} = @rbds_half_delay_test;
            % rnm1d means the replacement delay is equal to the dimension of the problem minus one.
            case 'rnm1d'
                solvers{i} = @rbds_n_minus_1_delay_test;
            % rnb means the number of selected blocks is equal to the dimension of the problem.
            case 'rnb'
                solvers{i} = @rbds_num_selected_blocks_n_test;
            % rhnb means the number of selected blocks is equal to the half of the dimension of the problem.
            case 'rhnb'
                solvers{i} = @rbds_num_selected_blocks_half_n_test;
            % rqnb means the number of selected blocks is equal to the quarter of the dimension of the problem.
            case 'rqnb'
                solvers{i} = @rbds_num_selected_blocks_quarter_n_test;
            % renb means the number of selected blocks is equal to the eighth of the dimension of the problem.
            case 'renb'
                solvers{i} = @rbds_num_selected_blocks_eighth_n_test;
            % r1b means the number of selected blocks is equal to 1.
            case 'r1b'
                solvers{i} = @rbds_num_selected_blocks_one_test;
            case 'pads'
                solvers{i} = @pads_test;
            case 'pads-noisy'
                solvers{i} = @(fun, x0) pads_test_noisy(fun, x0, true);
            case 'scbds'
                solvers{i} = @scbds_test;
            case 'scbds-noisy'
                solvers{i} = @(fun, x0) scbds_test_noisy(fun, x0, true);
            case 'cbds'
                solvers{i} = @cbds_test;
            case 'cbds-development'
                solvers{i} = @cbds_development_test;
            case 'cbds-cycle-all'
                solvers{i} = @cbds_cycle_all_test;
            case 'cbds-cycle-1'
                solvers{i} = @cbds_cycle_single_1_test;
            case 'cbds-cycle-2'
                solvers{i} = @cbds_cycle_single_2_test;
            case 'cbds-cycle-3'
                solvers{i} = @cbds_cycle_single_3_test;
            case 'cbds-cycle-4'
                solvers{i} = @cbds_cycle_single_4_test;
            case 'cbds-block'
                solvers{i} = @cbds_block_test;
            case 'cbds-orig'
                solvers{i} = @cbds_orig_test;
            case 'cbds-noisy'
                solvers{i} = @(fun, x0) cbds_test_noisy(fun, x0, true);
            case 'cbds-half-block'
                solvers{i} = @cbds_half_block_test;
            case 'cbds-quarter-block'
                solvers{i} = @cbds_quarter_block_test;
            case 'cbds-eighth-block'
                solvers{i} = @cbds_eighth_block_test;
            case 'cbds-randomized-orthogonal'
                solvers{i} = @cbds_randomized_orthogonal_test;
            case 'cbds-randomized-orthogonal-noisy'
                solvers{i} = @(fun, x0) cbds_randomized_orthogonal_test_noisy(fun, x0, true);
            case 'cbds-randomized-gaussian'
                solvers{i} = @cbds_randomized_gaussian_test;
            case 'cbds-randomized-gaussian-noisy'
                solvers{i} = @(fun, x0) cbds_randomized_gaussian_test_noisy(fun, x0, true);
            case 'cbds-permuted'
                solvers{i} = @cbds_permuted_test;
            case 'cbds-permuted-noisy'
                solvers{i} = @(fun, x0) cbds_permuted_test_noisy(fun, x0, true);
            case 'cbds-rotated-initial-point'
                solvers{i} = @cbds_rotated_initial_point_test;
            case 'cbds-rotated-initial-point-noisy'
                solvers{i} = @(fun, x0) cbds_rotated_initial_point_test_noisy(fun, x0, true);
            case 'pds'
                solvers{i} = @pds_test;
            case 'bfo'
                solvers{i} = @bfo_test;
            case 'newuoa'
                solvers{i} = @newuoa_test;
            case 'lam'
                solvers{i} = @lam_test;
            case 'nomad'
                solvers{i} = @nomad_test;
            case 'nomad-6'
                solvers{i} = @nomad_6_test;
            otherwise
                error('Unknown solver');
        end
    end
    options.benchmark_id = [];
    for i = 1:length(solvers)
        if i == 1
            options.benchmark_id = strrep(options.solver_names{i}, '-', '_');
        else
            options.benchmark_id = [options.benchmark_id, '_', strrep(options.solver_names{i}, '-', '_')];
        end
    end
    options.benchmark_id = [options.benchmark_id, '_', num2str(options.mindim), '_', num2str(options.maxdim), '_', num2str(options.n_runs)];
    switch options.feature_name
        case 'noisy'
            options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_', int2str(int32(-log10(options.noise_level))), '_no_rotation'];
        case 'custom'
            if isfield(options, 'permuted') && options.permuted
                options.benchmark_id = [options.benchmark_id, '_', 'permuted_noisy', '_', int2str(int32(-log10(options.noise_level)))];
            else
                options.benchmark_id = [options.benchmark_id, '_', 'rotation_noisy', '_', int2str(int32(-log10(options.noise_level)))];
            end
        case 'truncated'
            options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_', int2str(options.significant_digits)];
            options = rmfield(options, 'noise_level');
        case 'quantized'
            options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_', int2str(int32(-log10(options.mesh_size)))];
        case 'random_nan'
            if 100*options.nan_rate < 10
                options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_0', int2str(int32(options.nan_rate * 100))];
            else
                options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_', int2str(int32(options.nan_rate * 100))];
            end
        case 'perturbed_x0'
            if abs(options.noise_level - 1e-3) < eps
                options.benchmark_id = [options.benchmark_id, '_', options.feature_name];
            elseif abs(options.noise_level - 1) < eps
                options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_', '01'];
            elseif abs(options.noise_level - 10) < eps
                options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_', '10'];
            elseif abs(options.noise_level - 100) < eps
                options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_', '100'];
            end
    otherwise
        options.benchmark_id = [options.benchmark_id, '_', options.feature_name];
    end
    if options.run_plain
        options.benchmark_id = [options.benchmark_id, '_plain'];
    end
    options.benchmark_id = [options.benchmark_id, '_', time_str];
    options.excludelist = {'DIAMON2DLS',...
            'DIAMON2D',...
            'DIAMON3DLS',...
            'DIAMON3D',...
            'DMN15102LS',...
            'DMN15102',...
            'DMN15103LS',...
            'DMN15103',...
            'DMN15332LS',...
            'DMN15332',...
            'DMN15333LS',...
            'DMN15333',...
            'DMN37142LS',...
            'DMN37142',...
            'DMN37143LS',...
            'DMN37143',...
            'ROSSIMP3_mp',...
            'BAmL1SPLS',...
            'FBRAIN3LS',...
            'GAUSS1LS',...
            'GAUSS2LS',...
            'GAUSS3LS',...
            'HYDC20LS',...
            'HYDCAR6LS',...
            'LUKSAN11LS',...
            'LUKSAN12LS',...
            'LUKSAN13LS',...
            'LUKSAN14LS',...
            'LUKSAN17LS',...
            'LUKSAN21LS',...
            'LUKSAN22LS',...
            'METHANB8LS',...
            'METHANL8LS',...
            'SPINLS',...
            'VESUVIALS',...
            'VESUVIOLS',...
            'VESUVIOULS',...
            'YATP1CLS'};

    if strcmp(options.feature_name, 'custom')

        if ~isfield(options, 'permuted')
            % We need mod_x0 to make sure that the linearly transformed problem is mathematically equivalent
            % to the original problem.
            options.mod_x0 = @mod_x0;
            options.mod_affine = @mod_affine;
            options.feature_stamp = strcat('rotation_noisy_', int2str(int32(-log10(options.noise_level))));
        else
            options.mod_x0 = @mod_x0_permuted;
            options.mod_affine = @perm_affine;
            options.feature_stamp = strcat('permuted_noisy_', int2str(int32(-log10(options.noise_level))));
            options = rmfield(options, 'permuted');
        end
        % We only modify mod_fun since we are dealing with unconstrained problems.
        switch options.noise_level
            case 1e-1
                options.mod_fun = @mod_fun_1;
            case 1e-2
                options.mod_fun = @mod_fun_2;
            case 1e-3
                options.mod_fun = @mod_fun_3;
            case 1e-4
                options.mod_fun = @mod_fun_4;
            otherwise
                error('Unknown noise level');
        end
            options = rmfield(options, 'noise_level');

    end
    benchmark(solvers, options)

end

function x0 = mod_x0(rand_stream, problem)

    [Q, R] = qr(rand_stream.randn(problem.n));
    Q(:, diag(R) < 0) = -Q(:, diag(R) < 0);
    x0 = Q * problem.x0;
end

function x0 = mod_x0_permuted(rand_stream, problem)

    P = eye(problem.n);
    P = P(rand_stream.randperm(problem.n), :);
    x0 = P * problem.x0;
end

function f = mod_fun_1(x, rand_stream, problem)

    f = problem.fun(x);
    f = f + max(1, abs(f)) * 1e-1 * rand_stream.randn(1);
end

function f = mod_fun_2(x, rand_stream, problem)

    f = problem.fun(x);
    f = f + max(1, abs(f)) * 1e-2 * rand_stream.randn(1);
end

function f = mod_fun_3(x, rand_stream, problem)

    f = problem.fun(x);
    f = f + max(1, abs(f)) * 1e-3 * rand_stream.randn(1);
end

function f = mod_fun_4(x, rand_stream, problem)

    f = problem.fun(x);
    f = f + max(1, abs(f)) * 1e-4 * rand_stream.randn(1);
end

function [A, b, inv] = mod_affine(rand_stream, problem)

    [Q, R] = qr(rand_stream.randn(problem.n));
    Q(:, diag(R) < 0) = -Q(:, diag(R) < 0);
    A = Q';
    b = zeros(problem.n, 1);
    inv = Q;
end

function [A, b, inv] = perm_affine(rand_stream, problem)

    p = rand_stream.randperm(problem.n);
    P = eye(problem.n);
    P = P(p,:);
    A = P';
    b = zeros(problem.n, 1);    
    inv = P;
end

function x = fminsearch_test(fun, x0)

    % Dimension
    n = numel(x0);

    % Set MAXFUN to the maximum number of function evaluations.
    MaxFunctionEvaluations = 500*n;

    % Set the value of StepTolerance. The default value is 1e-4.
    tol = 1e-6;

    options = optimset("MaxFunEvals", MaxFunctionEvaluations, "maxiter", 10^20, "tolfun", eps, "tolx", tol);    

    x = fminsearch(fun, x0, options);
    
end

function x = fminunc_test(fun, x0)

    options = struct();
    
    % Set MAXFUN to the maximum number of function evaluations.
    if isfield(options, "MaxFunctionEvaluations")
        MaxFunctionEvaluations = options.MaxFunctionEvaluations;
    else
        MaxFunctionEvaluations = 500 * length(x0);
    end
    
    % Set the value of StepTolerance.
    if isfield(options, "StepTolerance")
        tol = options.StepTolerance;
    else
        tol = 1e-6;
    end
    
    % Set the target of the objective function.
    if isfield(options, "ftarget")
        ftarget = options.ftarget;
    else
        ftarget = -inf;
    end
    
    % Set the options of fminunc.
    options = optimoptions("fminunc", ...
        "Algorithm", "quasi-newton", ...
        "HessUpdate", "bfgs", ...
        "MaxFunctionEvaluations", MaxFunctionEvaluations, ...
        "MaxIterations", 10^20, ...
        "ObjectiveLimit", ftarget, ...
        "StepTolerance", tol, ...
        "OptimalityTolerance", eps);

    x = fminunc(fun, x0, options);

end

function x = fminunc_adaptive(fun, x0, noise_level)

    options.with_gradient = true;
    options.noise_level = noise_level;
    x = fminunc_wrapper(fun, x0, options);

end

function x = ds_test(fun, x0)

    option.Algorithm = 'ds';
    x = bds(fun, x0, option);

end

function x = ds_block_test(fun, x0)

    option.Algorithm = 'ds';
    option.expand = 2;
    option.shrink = 0.5;
    x = bds(fun, x0, option);
end

function x = ds_test_noisy(fun, x0, is_noisy)

    option.Algorithm = 'ds';
    option.is_noisy = is_noisy;
    x = bds(fun, x0, option);
end

function x = pbds_test(fun, x0)

    option.Algorithm = 'pbds';
    x = bds(fun, x0, option);
    
end

function x = pbds_test_noisy(fun, x0, is_noisy)

    option.Algorithm = 'pbds';
    option.is_noisy = is_noisy;
    x = bds(fun, x0, option);

end

function x = pbds_orig_test(fun, x0)

    option.Algorithm = 'pbds';
    option.expand = 2;
    option.shrink = 0.5;
    option.permuting_period = 0;
    x = bds(fun, x0, option);
    
end

function x = cbds_test(fun, x0)

    option.Algorithm = 'cbds';
    x = bds(fun, x0, option);
    
end

function x = cbds_development_test(fun, x0)

    option.Algorithm = 'cbds';
    option.expand = 2;
    option.shrink = 0.5;
    x = bds_development(fun, x0, option);
    
end

function x = cbds_cycle_all_test(fun, x0)

    option.Algorithm = 'cycle_all';
    option.expand = 2;
    option.shrink = 0.5;
    x = bds_development(fun, x0, option);
    
end

function x = cbds_cycle_single_1_test(fun, x0)

    option.Algorithm = 'cycle_single_1';
    option.expand = 2;
    option.shrink = 0.5;
    x = bds_development(fun, x0, option);
    
end

function x = cbds_cycle_single_2_test(fun, x0)

    option.Algorithm = 'cycle_single_2';
    option.expand = 2;
    option.shrink = 0.5;
    x = bds_development(fun, x0, option);
    
end

function x = cbds_cycle_single_3_test(fun, x0)

    option.Algorithm = 'cycle_single_3';
    option.expand = 2;
    option.shrink = 0.5;
    x = bds_development(fun, x0, option);
    
end

function x = cbds_cycle_single_4_test(fun, x0)

    option.Algorithm = 'cycle_single_4';
    option.expand = 2;
    option.shrink = 0.5;
    x = bds_development(fun, x0, option);
    
end

function x = cbds_block_test(fun, x0)

    option.Algorithm = 'cbds';
    option.expand = 2;
    option.shrink = 0.5;
    x = bds(fun, x0, option);
    
end

function x = cbds_orig_test(fun, x0)

    option.Algorithm = 'cbds';
    option.expand = 2;
    option.shrink = 0.5;
    x = bds(fun, x0, option);
    
end

function x = cbds_test_noisy(fun, x0, is_noisy)

    option.Algorithm = 'cbds';
    option.is_noisy = is_noisy;
    x = bds(fun, x0, option);
    
end

function x = cbds_half_block_test(fun, x0)

    option.batch_size = ceil(numel(x0)/2);
    option.expand = 2;
    option.shrink = 0.5;
    option.use_estimated_gradient_stop = false;
    x = bds(fun, x0, option);
    
end

function x = cbds_quarter_block_test(fun, x0)

    option.batch_size = ceil(numel(x0)/4);
    option.expand = 2;
    option.shrink = 0.5;
    option.use_estimated_gradient_stop = false;
    x = bds(fun, x0, option);
    
end

function x = cbds_eighth_block_test(fun, x0)

    option.batch_size = ceil(numel(x0)/8);
    option.expand = 2;
    option.shrink = 0.5;
    option.use_estimated_gradient_stop = false;
    x = bds(fun, x0, option);
    
end

function x = cbds_randomized_orthogonal_test(fun, x0)

    [Q,R] = qr(randn(numel(x0), numel(x0)));
    Q(:, diag(R) < 0) = -Q(:, diag(R) < 0);
    option.direction_set = Q;
    x = bds(fun, x0, option);
    
end

function x = cbds_randomized_orthogonal_test_noisy(fun, x0, is_noisy)

    [Q,R] = qr(randn(numel(x0), numel(x0)));
    Q(:, diag(R) < 0) = -Q(:, diag(R) < 0);
    option.direction_set = Q;
    option.is_noisy = is_noisy;
    x = bds(fun, x0, option);
    
end

function x = cbds_randomized_gaussian_test(fun, x0)

    option.direction_set = randn(numel(x0), numel(x0));
    option.direction_set = option.direction_set ./ vecnorm(option.direction_set);
    x = bds(fun, x0, option);
    
end

function x = cbds_randomized_gaussian_test_noisy(fun, x0, is_noisy)

    option.direction_set = randn(numel(x0), numel(x0));
    option.direction_set = option.direction_set ./ vecnorm(option.direction_set);
    option.is_noisy = is_noisy;
    x = bds(fun, x0, option);
    
end

function x = cbds_permuted_test(fun, x0)

    p = randperm(numel(x0));
    P = eye(numel(x0));
    P = P(p,:);
    option.direction_set = P;
    x = bds(fun, x0, option);
    
end

function x = cbds_permuted_test_noisy(fun, x0, is_noisy)

    p = randperm(numel(x0));
    P = eye(numel(x0));
    P = P(p,:);
    option.direction_set = P;
    option.is_noisy = is_noisy;
    x = bds(fun, x0, option);
    
end

function x = cbds_rotated_initial_point_test(fun, x0) 

    option.Algorithm = 'cbds';

    % Ensure x0 is a column vector
    x0 = x0(:);
    n = length(x0);

    % Normalize the input vector
    x0_hat = x0 / norm(x0);

    % Construct the first standard basis vector
    e1 = zeros(n, 1);
    e1(1) = 1;

    % Check if x0 is already aligned with e1
    if norm(x0_hat - e1) < 1e-10
        R = eye(n); % If x0 is already aligned with e1, return identity matrix
    else
        % Compute the Householder vector
        u = x0_hat - e1;

        % Avoid numerical instability when u is close to zero
        if norm(u) < 1e-10
            % Use a fallback: set u to a simple direction
            u = zeros(n, 1);
            u(2) = 1; % Choose a valid direction orthogonal to e1
        else
            u = u / norm(u); % Normalize u
        end

        % Compute the Householder reflection matrix implicitly
        % H = I - 2 * (u * u'), but we avoid forming H explicitly
        % Instead, we compute R directly
        R = eye(n) - 2 * (u * u'); % Compute the full rotation matrix
    end

    option.direction_set = R;

    x = bds_development(fun, x0, option);
    
end

function x = cbds_rotated_initial_point_test_noisy(fun, x0, is_noisy)

    option.Algorithm = 'cbds';

    % Ensure x0 is a column vector
    x0 = x0(:);
    n = length(x0);

    % Normalize the input vector
    x0_hat = x0 / norm(x0);

    % Construct the first standard basis vector
    e1 = zeros(n, 1);
    e1(1) = 1;

    % Check if x0 is already aligned with e1
    if norm(x0_hat - e1) < 1e-10
        R = eye(n); % If x0 is already aligned with e1, return identity matrix
    else
        % Compute the Householder vector
        u = x0_hat - e1;

        % Avoid numerical instability when u is close to zero
        if norm(u) < 1e-10
            % Use a fallback: set u to a simple direction
            u = zeros(n, 1);
            u(2) = 1; % Choose a valid direction orthogonal to e1
        else
            u = u / norm(u); % Normalize u
        end

        % Compute the Householder reflection matrix implicitly
        % H = I - 2 * (u * u'), but we avoid forming H explicitly
        % Instead, we compute R directly
        R = eye(n) - 2 * (u * u'); % Compute the full rotation matrix
    end

    option.direction_set = R;
    option.is_noisy = is_noisy;
    x = bds_development(fun, x0, option);

end

function x = rbds_test(fun, x0)

    option.Algorithm = 'rbds';
    x = bds(fun, x0, option);
    
end

function x = rbds_test_noisy(fun, x0, is_noisy)

    option.Algorithm = 'rbds';
    option.is_noisy = is_noisy;
    x = bds(fun, x0, option);
    
end

function x = rbds_zero_delay_test(fun, x0)

    option.Algorithm = 'rbds';
    option.batch_size = 1;
    option.expand = 2;
    option.shrink = 0.5;
    option.replacement_delay = 0;
    x = bds(fun, x0, option);
    
end

function x = rbds_one_delay_test(fun, x0)

    option.Algorithm = 'rbds';
    option.batch_size = 1;
    option.expand = 2;
    option.shrink = 0.5;
    option.replacement_delay = 1;
    x = bds(fun, x0, option);
    
end

function x = rbds_eighth_delay_test(fun, x0)

    option.Algorithm = 'rbds';
    option.batch_size = 1;
    option.expand = 2;
    option.shrink = 0.5;
    option.replacement_delay = ceil(numel(x0)/8);
    x = bds(fun, x0, option);
    
end

function x = rbds_quarter_delay_test(fun, x0)

    option.Algorithm = 'rbds';
    option.batch_size = 1;
    option.expand = 2;
    option.shrink = 0.5;
    option.replacement_delay = ceil(numel(x0)/4);
    x = bds(fun, x0, option);
    
end

function x = rbds_half_delay_test(fun, x0)

    option.Algorithm = 'rbds';
    option.batch_size = 1;
    option.expand = 2;
    option.shrink = 0.5;
    option.replacement_delay = ceil(numel(x0)/2);
    x = bds(fun, x0, option);
    
end

function x = rbds_n_minus_1_delay_test(fun, x0)

    option.Algorithm = 'rbds';
    option.batch_size = 1;
    option.expand = 2;
    option.shrink = 0.5;
    option.replacement_delay = numel(x0) - 1;
    x = bds(fun, x0, option);
    
end

function x = rbds_num_selected_blocks_n_test(fun, x0)

    option.Algorithm = 'rbds';
    option.expand = 2;
    option.shrink = 0.5;
    option.batch_size = numel(x0);
    option.replacement_delay = 0;
    x = bds(fun, x0, option);
    
end

function x = rbds_num_selected_blocks_half_n_test(fun, x0)

    option.Algorithm = 'rbds';
    option.expand = 2;
    option.shrink = 0.5;
    option.batch_size = ceil(numel(x0)/2);
    option.replacement_delay = 0;
    x = bds(fun, x0, option);

end

function x = rbds_num_selected_blocks_quarter_n_test(fun, x0)

    option.Algorithm = 'rbds';
    option.expand = 2;
    option.shrink = 0.5;
    option.batch_size = ceil(numel(x0)/4);
    option.replacement_delay = 0;
    x = bds(fun, x0, option);

end

function x = rbds_num_selected_blocks_eighth_n_test(fun, x0)

    option.Algorithm = 'rbds';
    option.expand = 2;
    option.shrink = 0.5;
    option.batch_size = ceil(numel(x0)/8);
    option.replacement_delay = 0;
    x = bds(fun, x0, option);

end

function x = rbds_num_selected_blocks_one_test(fun, x0)

    option.Algorithm = 'rbds';
    option.expand = 2;
    option.shrink = 0.5;
    option.batch_size = 1;
    option.replacement_delay = 0;
    x = bds(fun, x0, option);

end

function x = pads_test_noisy(fun, x0, is_noisy)

    option.Algorithm = 'pads';
    option.is_noisy = is_noisy;
    x = bds(fun, x0, option);
    
end

function x = scbds_test(fun, x0)

    option.Algorithm = 'scbds';
    x = bds_development(fun, x0, option);
    
end

function x = scbds_test_noisy(fun, x0, is_noisy)

    option.Algorithm = 'scbds';
    option.is_noisy = is_noisy;
    x = bds_development(fun, x0, option);
    
end

function x = pds_test(fun, x0)

    x = pds(fun, x0);
    
end

function x = bfo_test(fun, x0)

    % Dimension
    n = numel(x0);

    StepTolerance = 1e-6;
    maxeval = 500*n;

    [x, ~, ~, ~, ~] = bfo(fun, x0, 'epsilon', StepTolerance, 'maxeval', maxeval);
    
end

function x = newuoa_test(fun, x0)

    options.maxfun = 500*length(x0);
    x = newuoa(fun, x0, options);
    
end

function x = lam_test(fun, x0)

    x = lam(fun, x0);
    
end

function x = nomad_test(fun, x0)
    
    % Dimension:
    n = numel(x0);

    % Set the default bounds.
    lb = -inf(n, 1);
    ub = inf(n, 1);

    % Set MAXFUN to the maximum number of function evaluations.
    MaxFunctionEvaluations = 500*n;

    params = struct('MAX_BB_EVAL', num2str(MaxFunctionEvaluations), 'max_eval',num2str(MaxFunctionEvaluations));

    % As of NOMAD version 4.4.0 and OptiProfiler commit 24d8cc0, the following line is 
    % necessary. Otherwise, NOMAD will throw an error, complaining that the blackbox 
    % evaluation fails. This seems to be because OptiProfiler wraps the function 
    % handle in a way that NOMAD does not expect: NOMAD expects a function handle 
    % `fun` with the signature fun(x), where x is a column vector, while OptiProfiler 
    % produces one with the signature @(varargin)featured_problem.fun(varargin{:}).
    fun = @(x) fun(x(:));

    [x, ~, ~, ~, ~] = nomadOpt(fun,x0,lb,ub,params);
    
end

function x = nomad_6_test(fun, x0)
    
    % Dimension:
    n = numel(x0);

    % Set the default bounds.
    lb = -inf(n, 1);
    ub = inf(n, 1);

    % Set MAXFUN to the maximum number of function evaluations.
    MaxFunctionEvaluations = 500*n;

    params = struct('min_frame_size','* 0.000001', 'min_mesh_size', '* 0.000001', ...
    'MAX_BB_EVAL', num2str(MaxFunctionEvaluations), 'max_eval',num2str(MaxFunctionEvaluations));

    % As of NOMAD version 4.4.0 and OptiProfiler commit 24d8cc0, the following line is 
    % necessary. Otherwise, NOMAD will throw an error, complaining that the blackbox 
    % evaluation fails. This seems to be because OptiProfiler wraps the function 
    % handle in a way that NOMAD does not expect: NOMAD expects a function handle 
    % `fun` with the signature fun(x), where x is a column vector, while OptiProfiler 
    % produces one with the signature @(varargin)featured_problem.fun(varargin{:}).
    fun = @(x) fun(x(:));

    [x, ~, ~, ~, ~] = nomadOpt(fun,x0,lb,ub,params);
    
end