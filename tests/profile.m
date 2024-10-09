function [path_testdata_perf, frec, fmin] = profile(parameters)
% Draw performance profiles.
%

% Record the current path.
oldpath = path();
% Restore the "right out of the box" path of MATLAB.
restoredefaultpath;
% Record the current directory.
old_dir = pwd();

exception = [];

try

    path_nlopt = "/usr/local/lib/matlab/";

    if ~contains(path, path_nlopt, 'IgnoreCase', true)
        if exist(path_nlopt, 'dir') == 7
            addpath(path_nlopt);
            disp('Add path_nlopt to MATLAB path.');
        else
            disp('path_nlopt does not exist on the local machine.');
        end
    else
        disp('Path_nlopt already exists in MATLAB path.');
    end

    if any(ismember(parameters.solvers_name, "nomad"))
        addpath '/home/lhtian97/Documents/nomad/build/release/lib'
    end

    % Add the paths that we need to use in the performance profile into the MATLAB
    % search path.
    current_path = mfilename("fullpath");
    path_tests = fileparts(current_path);
    path_root = fileparts(path_tests);
    path_src = fullfile(path_root, "src");
    path_competitors = fullfile(path_tests, "competitors");
    addpath(path_root);
    addpath(path_tests);
    addpath(path_src);
    addpath(path_competitors);

    % If the folder of testdata does not exist, make a new one.
    path_testdata = fullfile(path_tests, "testdata");
    if ~exist(path_testdata, "dir")
        mkdir(path_testdata);
    end

    % In case no solvers are input, then throw an error.
    if ~isfield(parameters, "solvers_options") || length(parameters.solvers_options) < 2
        error("There should be at least two solvers.")
    end

    % Get the parameters that the test needs.
    parameters = set_profile_options(parameters);

    % Tell MATLAB where to find MatCUTEst.
    locate_matcutest();

    % Get list of problems
    if isfield(parameters, "test_type") && strcmpi(parameters.test_type, "matcutest")

        s.type = parameters.problem_type; % Unconstrained: 'u'
        s.mindim = parameters.problem_mindim; % Minimum of dimension
        s.maxdim = parameters.problem_maxdim; % Maximum of dimension
        s.blacklist = [];
        %s.blacklist = [s.blacklist, {}];
        % Problems that take too long to solve.
        % {'FBRAIN3LS'} and {'STRATEC'} take too long for fminunc.
        if ismember("matlab_fminunc", parameters.solvers_name)
            s.blacklist = [s.blacklist, {'FBRAIN3LS'}, {'STRATEC'}];
        end
        % {"MUONSINELS"} takes nlopt_newuoa so long to run (even making MATLAB crash).
        % {"LRCOVTYPE"}, {'HIMMELBH'} and {'HAIRY'} take nlopt_cobyla so long
        % to run (even making MATLAB crash).
        % {"MUONSINELS"} takes nlopt_bobyqa so long to run (even making MATLAB crash).
        if ismember("nlopt", parameters.solvers_name)
            s.blacklist = [s.blacklist, {'MUONSINELS'}, {'BENNETT5LS'},...
                {'HIMMELBH'}, {'HAIRY'}];
        end

        %if s.mindim >= 6
        s.blacklist = [s.blacklist, { 'ARGTRIGLS', 'BROWNAL', ...
            'COATING', 'DIAMON2DLS', 'DIAMON3DLS', 'DMN15102LS', ...
            'DMN15103LS', 'DMN15332LS', 'DMN15333LS', 'DMN37142LS', ...
            'DMN37143LS', 'ERRINRSM', 'HYDC20LS', 'LRA9A', ...
            'LRCOVTYPE', 'LUKSAN12LS', 'LUKSAN14LS', 'LUKSAN17LS', 'LUKSAN21LS', ...
            'LUKSAN22LS', 'MANCINO', 'PENALTY2', 'PENALTY3', 'VARDIM',
            }];
        %end

        if isfield(parameters, "problem_names")
            problem_names = parameters.problem_names;
        else
            problem_names = secup(s);
        end
    else
        s = load('probinfo.mat');
        blacklist = ["DIAMON2DLS",...
            "DIAMON2D",...
            "DIAMON3DLS",...
            "DIAMON3D",...
            "DMN15102LS",...
            "DMN15102",...
            "DMN15103LS",...
            "DMN15103",...
            "DMN15332LS",...
            "DMN15332",...
            "DMN15333LS",...
            "DMN15333",...
            "DMN37142LS",...
            "DMN37142",...
            "DMN37143LS",...
            "DMN37143",...
            "ROSSIMP3_mp"];
        blacklist_time_consuming = ["BAmL1SPLS",...
            "FBRAIN3LS",...
            "GAUSS1LS",...
            "GAUSS2LS",...
            "GAUSS3LS",...
            "HYDC20LS",...
            "HYDCAR6LS",...
            "LUKSAN11LS",...
            "LUKSAN12LS",...
            "LUKSAN13LS",...
            "LUKSAN14LS",...
            "LUKSAN17LS",...
            "LUKSAN21LS",...
            "LUKSAN22LS",...
            "METHANB8LS",...
            "METHANL8LS",...
            "SPINLS",...
            "VESUVIALS",...
            "VESUVIOLS",...
            "VESUVIOULS",...
            "YATP1CLS"];
        problem_names = [];
        for i = 2:length(s.problem_data)
            if strcmpi(s.problem_data(i, 2), parameters.problem_type) && ...
                    cell2mat(s.problem_data(i, 3)) >= parameters.problem_mindim && ...
                    cell2mat(s.problem_data(i, 3)) <= parameters.problem_maxdim && ...
                    ~ismember(s.problem_data(i, 1), blacklist) && ...
                    ~ismember(s.problem_data(i, 1), blacklist_time_consuming)
                problem_names = [problem_names, s.problem_data(i, 1)];
            end
        end
        path_S2MPJ_matlab_problems = strcat(fileparts(mfilename('fullpath')), "/matlab_problems/");
        if ~contains(path, path_S2MPJ_matlab_problems, 'IgnoreCase', true)
            if exist(path_S2MPJ_matlab_problems, 'dir') == 7
                addpath(path_S2MPJ_matlab_problems);
                disp('Add path_S2MPJ_matlab_problems to MATLAB path.');
            else
                disp('path_S2MPJ_matlab_problems does not exist on the local machine.');
            end
        else
            disp('Path_S2MPJ_matlab_problems already exists in MATLAB path.');
        end
    end

    fprintf("We will load %d problems\n\n", length(problem_names));

    % Some fixed (relatively) options
    % Read two papers: What Every Computer Scientist Should Know About
    % Floating-Point Arithmetic; stability and accuracy numerical(written by Higham).

    % Initialize the number of solvers.
    num_solvers = length(parameters.solvers_options);
    % Set MaxFunctionEvaluations_frec for performance profile.
    MaxFunctionEvaluations_frec = max(get_default_profile_options("MaxFunctionEvaluations"), ...
        get_default_profile_options("MaxFunctionEvaluations_dim_factor")*parameters.problem_maxdim);
    for i = 1:num_solvers
        if isfield(parameters, "default") && parameters.default
            switch parameters.solvers_options{i}.solver
                case "bfo_wrapper"
                    MaxFunctionEvaluations_frec = max(MaxFunctionEvaluations_frec, 5000*parameters.problem_maxdim);
                case "fminsearch_wrapper"
                    MaxFunctionEvaluations_frec = max(MaxFunctionEvaluations_frec, 200*parameters.problem_maxdim);
                case "fminunc_wrapper"
                    MaxFunctionEvaluations_frec = max(MaxFunctionEvaluations_frec, 100*parameters.problem_maxdim);
                case "prima_wrapper"
                    MaxFunctionEvaluations_frec = max(MaxFunctionEvaluations_frec, 500*parameters.problem_maxdim);
            end
        end
    end

    % Get the number of problems.
    num_problems = length(problem_names);
    % Get Number of random tests(If num_random = 1, it means no random test).
    num_random = parameters.num_random;
    % Record the minimum value of the problems of the random test.
    fmin = NaN(num_problems, num_random);
    frec = NaN(num_problems, num_solvers, num_random, MaxFunctionEvaluations_frec);

    % Set noisy parts of the test.
    test_options.is_noisy = parameters.is_noisy;
    if parameters.is_noisy

        if isfield(parameters, "noise_level")
            test_options.noise_level = parameters.noise_level;
        else
            test_options.noise_level = get_default_profile_options("noise_level");
        end

        % Relative: (1+noise_level*noise)*f; absolute: f+noise_level*noise
        if isfield(parameters, "is_abs_noise")
            test_options.is_abs_noise = parameters.is_abs_noise;
        else
            test_options.is_abs_noise = get_default_profile_options("is_abs_noise");
        end

        if isfield(parameters, "noise_type")
            test_options.noise_type = parameters.noise_type;
        else
            test_options.noise_type = get_default_profile_options("noise_type");
        end

        if isfield(parameters, "num_random")
            test_options.num_random = parameters.num_random;
        else
            test_options.num_random = get_default_profile_options("num_random");
        end

    end

    % Set solvers_options.
    parameters = get_options(parameters);
    solvers_options = parameters.solvers_options;

    % We put time_str and tst here for the sake of plot_fhist.
    % Use time to distinguish.
    time_str = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm'));
    % Trim time string.
    time_str = trim_time(time_str);
    % Rename tst as the mixture of time stamp and pdfname.
    tst = strcat(parameters.pdfname, "_", time_str);


    if isfield(parameters, "plot_fhist") && parameters.plot_fhist
        if ~isfield(parameters, "log_x_axis")
            parameters.log_x_axis = false;
        end

        if parameters.log_x_axis
            parameters.stamp_fhist = strcat(parameters.pdfname, "_", "log_x_axis", "_", time_str, "_fhist");
        else
            parameters.stamp_fhist = strcat(parameters.pdfname, "_", time_str, "_fhist");
        end

        savepath = fullfile(path_testdata, parameters.stamp_fhist);
        mkdir(savepath);
        if num_random == 1
            parameters.savepath = savepath;
        else
            parameters.savepath = cell(1, num_random);
            for i = 1:num_random
                parameters.savepath{i} = fullfile(savepath, sprintf("random_%d", i));
                mkdir(parameters.savepath{i});
            end
        end
    end

    % If parameters.noise_initial_point is true, then the initial point will be
    % selected for each problem num_random times.
    % The default value of parameters.fmin_type is set to be "randomized", then there is
    % no need to test without noise, which makes the curve of the performance profile
    % more higher. If parallel is true, use parfor to calculate (parallel computation),
    % otherwise, use for to calculate (sequential computation).
    if parameters.parallel == true
        parfor i_problem = 1:num_problems
            if isfield(parameters, "test_type") && strcmpi(parameters.test_type, "matcutest")
                p = macup(problem_names(1, i_problem));
            else
                problem_orig = str2func(char(problem_names(i_problem)));
                problem_info = problem_orig('setup');
                p = s2mpj_wrapper(problem_info, problem_names(1, i_problem));
            end
            dim = length(p.x0);
            for i_run = 1:num_random
                % Set scaling matrix.
                if isfield(parameters, "feature") && strcmpi(parameters.feature, "badly_scaled")
                    % Badly_scaled is a flag to indicate whether the problem is badly scaled.
                    if isfield(parameters, "badly_scaled_sigma")
                        scale_matrix = diag(2.^(parameters.badly_scaled_sigma*randn(dim, 1)));
                    else
                        scale_matrix = diag(2.^(dim*randn(dim, 1)));
                    end
                    h = @(x) scale_matrix * x;
                    p.objective = @(x) p.objective(h(x));
                    p.x0 = p.x0 ./ diag(scale_matrix);
                end
                if isfield(parameters, "feature") && strcmpi(parameters.feature, "rotation_badly_scaled")
                    % Rotation_badly_scaled is a flag to indicate whether the problem is rotated and badly scaled.
                    [Q,R] = qr(randn(dim));
                    rotation_matrix = Q*diag(sign(diag(R)));
                    h = @(x) rotation_matrix * x;
                    p.objective = @(x) p.objective(h(x));
                    p.x0 = (qr(rotation_matrix) \ eye(dim)) * p.x0;
                    scale_matrix = diag(2.^(dim*randn(dim, 1)));
                    h = @(x) scale_matrix * x;
                    p.objective = @(x) p.objective(h(x));
                    p.x0 = p.x0 ./ diag(scale_matrix);
                end
                if isfield(parameters, "feature") && (strcmpi(parameters.feature, "rotation") || ...
                        strcmpi(parameters.feature, "rotation_noisy"))
                    % Rotation is a flag to indicate whether the problem is rotated.
                    [Q,R] = qr(randn(dim));
                    rotation_matrix = Q*diag(sign(diag(R)));
                    h = @(x) rotation_matrix * x;
                    p.objective = @(x) p.objective(h(x));
                    p.x0 = (qr(rotation_matrix) \ eye(dim)) * p.x0;
                end
                if isfield(parameters, "feature") && strcmpi(parameters.feature, "structured")
                    % Structured is a flag to indicate whether the problem is added with l-p regularization term.
                    if isfield(parameters, "structured_factor")
                        h = @(x) parameters.structured_factor *  sum(abs(x).^ 1);
                    else
                        h = @(x) sum(abs(x).^ 1);
                    end
                    %h = @(x) parameters.structured_factor *  sum(abs(x).^ parameters.structured_norm)^(1/parameters.structured_norm);
                    p.objective = @(x) p.objective(x) + h(x);
                end
                if isfield(parameters, "feature") && strcmpi(parameters.feature, "rotation_structured")
                    % Rotation_structure is a flag to indicate whether the problem is rotated and added with l-p regularization term.
                    [Q,R] = qr(randn(dim));
                    rotation_matrix = Q*diag(sign(diag(R)));
                    h = @(x) rotation_matrix * x;
                    p.objective = @(x) p.objective(h(x));
                    if isfield(parameters, "structured_factor")
                        h = @(x) parameters.structured_factor *  sum(abs(x).^ 1);
                    else
                        h = @(x) sum(abs(x).^ 1);
                    end
                    p.objective = @(x) p.objective(x) + h(x);
                end
                if isfield(parameters, "plot_fhist") && parameters.plot_fhist
                    fhist_plot = cell(1, num_solvers);
                end
                fval_tmp = NaN(1, num_solvers);
                if parameters.random_initial_point
                    rr = randn(size(p.x0));
                    rr = rr / norm(rr);
                    %p.x0 = p.x0 + 1 * max(1, norm(p.x0)) * rr;
                    p.x0 = p.x0 + parameters.x0_perturbation_level * max(1, norm(p.x0)) * rr;
                end
                fprintf("%d(%d). %s\n", i_problem, i_run, p.name);
                for i_solver = 1:num_solvers
                    [fhist, fhist_perfprof] = get_fhist(p, MaxFunctionEvaluations_frec, i_solver,...
                        i_run, solvers_options, test_options);
                    if isfield(parameters, "plot_fhist") && parameters.plot_fhist
                        fhist_plot{i_solver} = fhist;
                    end
                    if isempty(fhist)
                        fval_tmp(i_solver) = NaN;
                    else
                        fval_tmp(i_solver) = min(fhist);
                    end
                    frec(i_problem,i_solver,i_run,:) = fhist_perfprof;
                end
                fmin(i_problem, i_run) = min(fval_tmp);
                if isfield(parameters, "plot_fhist") && parameters.plot_fhist
                    plot_fhist(dim, fhist_plot, p.name, i_run, parameters);
                end
            end
        end
    else
        for i_problem = 1:num_problems
            if isfield(parameters, "test_type") && strcmpi(parameters.test_type, "matcutest")
                p = macup(problem_names(1, i_problem));
            else
                problem_orig = str2func(char(problem_names(i_problem)));
                problem_info = problem_orig('setup');
                p = s2mpj_wrapper(problem_info, problem_names(1, i_problem));
            end
            dim = length(p.x0);
            for i_run = 1:num_random
                % Set scaling matrix.
                if isfield(parameters, "feature") && strcmpi(parameters.feature, "badly_scaled")
                    % Badly_scaled is a flag to indicate whether the problem is badly scaled.
                    if isfield(parameters, "badly_scaled_sigma")
                        scale_matrix = diag(2.^(parameters.badly_scaled_sigma*randn(dim, 1)));
                    else
                        scale_matrix = diag(2.^(dim*randn(dim, 1)));
                    end
                    h = @(x) scale_matrix * x;
                    p.objective = @(x) p.objective(h(x));
                    p.x0 = p.x0 ./ diag(scale_matrix);
                end
                if isfield(parameters, "feature") && strcmpi(parameters.feature, "rotation_badly_scaled")
                    % Rotation_badly_scaled is a flag to indicate whether the problem is rotated and badly scaled.
                    [Q,R] = qr(randn(dim));
                    rotation_matrix = Q*diag(sign(diag(R)));
                    h = @(x) rotation_matrix * x;
                    p.objective = @(x) p.objective(h(x));
                    p.x0 = (qr(rotation_matrix) \ eye(dim)) * p.x0;
                    scale_matrix = diag(2.^(dim*randn(dim, 1)));
                    h = @(x) scale_matrix * x;
                    p.objective = @(x) p.objective(h(x));
                    p.x0 = p.x0 ./ diag(scale_matrix);
                end
                if isfield(parameters, "feature") && (strcmpi(parameters.feature, "rotation") || ...
                        strcmpi(parameters.feature, "rotation_noisy"))
                    % Rotation is a flag to indicate whether the problem is rotated.
                    [Q,R] = qr(randn(dim));
                    rotation_matrix = Q*diag(sign(diag(R)));
                    h = @(x) rotation_matrix * x;
                    %p.objective = @(x) p.objective(@(x) rotation_matrix * x(x));
                    p.objective = @(x) p.objective(h(x));
                    p.x0 = (qr(rotation_matrix) \ eye(dim)) * p.x0;
                end
                if isfield(parameters, "feature") && strcmpi(parameters.feature, "structured")
                    % Structured is a flag to indicate whether the problem is added with l-p regularization term.
                    if isfield(parameters, "structured_factor")
                        h = @(x) parameters.structured_factor *  sum(abs(x).^ 1);
                    else
                        h = @(x) sum(abs(x).^ 1);
                    end
                    %h = @(x) parameters.structured_factor *  sum(abs(x).^ parameters.structured_norm)^(1/parameters.structured_norm);
                    p.objective = @(x) p.objective(x) + h(x);
                end
                if isfield(parameters, "feature") && strcmpi(parameters.feature, "rotation_structured")
                    % Rotated_structure is a flag to indicate whether the problem is rotated and added with l-p regularization term.
                    [Q,R] = qr(randn(dim));
                    rotation_matrix = Q*diag(sign(diag(R)));
                    h = @(x) rotation_matrix * x;
                    p.objective = @(x) p.objective(h(x));
                    if isfield(parameters, "structured_factor")
                        h = @(x) parameters.structured_factor *  sum(abs(x).^ 1);
                    else
                        h = @(x) sum(abs(x).^ 1);
                    end
                    p.objective = @(x) p.objective(x) + h(x);
                end
                if isfield(parameters, "rotated_badly_scaled")
                    % Rotated_badly_scaled is a flag to indicate whether the problem is rotated and badly scaled.
                    [Q,R] = qr(randn(dim));
                    rotation_matrix = Q*diag(sign(diag(R)));
                    h = @(x) rotation_matrix * x;
                    p.objective = @(x) p.objective(h(x));
                    scale_matrix = diag(2.^(dim*randn(dim, 1)));
                    h = @(x) scale_matrix * x;
                    p.objective = @(x) p.objective(h(x));
                    p.x0 = p.x0 ./ diag(scale_matrix);
                end
                if isfield(parameters, "plot_fhist") && parameters.plot_fhist
                    fhist_plot = cell(1, num_solvers);
                end
                fval_tmp = NaN(1, num_solvers);
                if parameters.random_initial_point
                    rr = randn(size(p.x0));
                    rr = rr / norm(rr);
                    p.x0 = p.x0 + parameters.x0_perturbation_level * max(1, norm(p.x0)) * rr;
                end
                fprintf("%d(%d). %s\n", i_problem, i_run, p.name);
                %fhist_tmp = cell(2, 1);
                BDS_list = ["DS", "CBDS", "PBDS", "RBDS", "PADS", "sCBDS"];
                if ~isempty(intersect(parameters.solvers_name, lower(BDS_list)))
                    % If there is a solver that we invoke existing in BDS_List, set the direction_set of input to be the same
                    % random orthogonal matrix.
                    dim = length(p.x0);
                    [direction_set_base, ~] = qr(randn(dim));
                end
                for i_solver = 1:num_solvers
                    if ismember(lower(parameters.solvers_name{i_solver}), lower(BDS_list)) ...
                            && isfield(solvers_options{i_solver}, "direction_set_type") && ...
                            strcmpi(solvers_options{i_solver}.direction_set_type, "randomized_orthogonal_matrix")
                        solvers_options{i_solver}.direction_set = direction_set_base;
                    end
                    [fhist, fhist_perfprof] = get_fhist(p, MaxFunctionEvaluations_frec, i_solver,...
                        i_run, solvers_options, test_options);
                    % if any(isnan(fhist_perfprof))
                    %     keyboard
                    % end
                    if isfield(parameters, "plot_fhist") && parameters.plot_fhist
                        fhist_plot{i_solver} = fhist;
                    end
                    if isempty(fhist)
                        fval_tmp(i_solver) = NaN;
                    else
                        fval_tmp(i_solver) = min(fhist);
                    end
                    frec(i_problem,i_solver,i_run,:) = fhist_perfprof;
                end
                % if ~isequal(fhist_tmp{1}, fhist_tmp{2})
                %     keyboard
                % end
                fmin(i_problem, i_run) = min(fval_tmp);
                if isfield(parameters, "plot_fhist") && parameters.plot_fhist
                    plot_fhist(dim, fhist_plot, p.name, i_run, parameters);
                end
            end
        end
    end

    % If parameters.fmin_type = "real-randomized", then test with the plain feature
    % should be conducted and fmin might be smaller, which makes curves
    %  of performance profile more lower.
    if strcmpi(parameters.fmin_type, "real-randomized")
        fmin_real = NaN(num_problems, 1);
        test_options.is_noisy = false;
        i_run = 1;
        if parameters.parallel == true
            parfor i_problem = 1:num_problems
                if isfield(parameters, "test_type") && strcmpi(parameters.test_type, "matcutest")
                    p = macup(problem_names(1, i_problem));
                else
                    problem_orig = str2func(char(problem_names(i_problem)));
                    problem_info = problem_orig('setup');
                    p = s2mpj_wrapper(problem_info, problem_names(1, i_problem));
                end
                frec_local = NaN(num_solvers, MaxFunctionEvaluations_frec);
                fprintf("%d. %s\n", i_problem, p.name);
                for i_solver = 1:num_solvers
                    [~, fhist_perfprof] = get_fhist(p, MaxFunctionEvaluations_frec, i_solver,...
                        i_run, solvers_options, test_options);
                    frec_local(i_solver,:) = fhist_perfprof;
                end
                fmin_real(i_problem) = min(frec_local(:, :),[],"all");
            end
        else
            for i_problem = 1:num_problems
                if isfield(parameters, "test_type") && strcmpi(parameters.test_type, "matcutest")
                    p = macup(problem_names(1, i_problem));
                else
                    problem_orig = str2func(char(problem_names(i_problem)));
                    problem_info = problem_orig('setup');
                    p = s2mpj_wrapper(problem_info, problem_names(1, i_problem));
                end
                frec_local = NaN(num_solvers, MaxFunctionEvaluations_frec);
                fprintf("%d. %s\n", i_problem, p.name);
                for i_solver = 1:num_solvers
                    [~, fhist_perfprof] = get_fhist(p, MaxFunctionEvaluations_frec, i_solver,...
                        i_run, solvers_options, test_options);
                    frec_local(i_solver,:) = fhist_perfprof;
                end
                fmin_real(i_problem) = min(frec_local(:, :),[],"all");
            end
        end
    end

    if strcmpi(parameters.fmin_type, "real-randomized")
        fmin_total = [fmin, fmin_real];
        fmin = min(fmin_total, [], 2);
    end

    if ~(isfield(parameters, "tuning") && parameters.tuning)
        % Plot fhist.
        compdf_location = char(fullfile(path_tests, "private", "compdf"));
        if isfield(parameters, "plot_fhist") && parameters.plot_fhist
            if num_random == 1
                outputfile = char(strcat("merged", "_", parameters.stamp_fhist, ".pdf"));
                merge_pdf(parameters.savepath, outputfile, compdf_location);
            else
                for i = 1:num_random
                    outputfile = char(strcat("merged", "_", parameters.stamp_fhist, "_", num2str(i), ".pdf"));
                    merge_pdf(parameters.savepath{i}, outputfile, compdf_location);
                end
            end
            parameters = rmfield(parameters, "savepath");
        end

        path_testdata = fullfile(path_tests, "testdata");
        path_testdata_outdir = fullfile(path_tests, "testdata", tst);

        % Make a new folder to save numerical results and source code.
        mkdir(path_testdata, tst);
        fprintf("The path of the testdata is:\n%s\n", path_testdata_outdir);
        mkdir(path_testdata_outdir, "perf");
        path_testdata_perf = fullfile(path_testdata_outdir, "perf");
        mkdir(path_testdata_perf, parameters.pdfname);
        if isfield(parameters, "log_profile") && parameters.log_profile
            log_profile = strcat(parameters.pdfname, "_", "log_perf");
            path_testdata_log_perf = fullfile(path_testdata_perf, log_profile);
            mkdir(path_testdata_log_perf);
        end
        mkdir(path_testdata_outdir, "src");
        path_testdata_src = fullfile(path_testdata_outdir, "src");
        mkdir(path_testdata_outdir, "tests");
        path_testdata_tests = fullfile(path_testdata_outdir, "tests");
        path_testdata_competitors = fullfile(path_testdata_tests, "competitors");
        mkdir(path_testdata_competitors);
        path_testdata_private = fullfile(path_testdata_tests, "private");
        mkdir(path_testdata_private);

        % Make a Txt file to store the problems that are tested and also record the dimensions of the problems that are tested.
        data_dim = zeros(1, length(problem_names));
        filePath = strcat(path_testdata_perf, "/problem_names.txt");
        fileID = fopen(filePath, 'w');
        if isfield(parameters, "test_type") && strcmpi(parameters.test_type, "matcutest")
            fprintf(fileID, '%-15s %-15s\n', 'Problem_name', 'Matcutest_dim');
        else
            fprintf(fileID, '%-15s %-15s\n', 'Problem_name', 'S2MPJ_dim');
        end
        for i_problem = 1:length(problem_names)
            if isfield(parameters, "test_type") && strcmpi(parameters.test_type, "matcutest")
                p = macup(problem_names{i_problem});
                data_dim(i_problem) = length(p.x0);
                fprintf(fileID, '%-15s %-15s\n', problem_names{i_problem}, num2str(length(p.x0)));
            else
                problem_orig = str2func(char(problem_names(i_problem)));
                problem_info = problem_orig('setup');
                data_dim(i_problem) = length(problem_info.x0);
                fprintf(fileID, '%-15s %-15s\n', problem_names{i_problem}, num2str(length(problem_info.x0)));
            end
        end
        fclose(fileID);

        % Make a bar chart to show the distribution of the dimensions of the problems that are tested.
        % Count the frequency of occurrence of the dimensions of the problems.
        [unique_values, ~, ~] = unique(data_dim);
        frequencies = zeros(size(unique_values));
        for i = 1:length(unique_values)
            frequencies(i) = sum(data_dim == unique_values(i));
        end
        % Draw the bar chart.
        figure;
        bar(unique_values, frequencies);
        xlabel('Dimensions');
        ylabel('Frequency');
        title('Bar Chart of Frequencies');
        % Save the image to the specified path.
        save_path = strcat(path_testdata_perf, "/bar_chart_dimensions.png");
        saveas(gcf, save_path);

        % Make a Txt file to store the parameters that are used.
        filePath = strcat(path_testdata_perf, "/parameters.txt");
        fileID = fopen(filePath, 'w');
        parameters_saved = parameters;
        parameters_saved = trim_struct(parameters_saved);
        % Get the field names of a structure.
        parameters_saved_fields = fieldnames(parameters_saved);
        % Write field names and their corresponding values into a file line by line.
        for i = 1:numel(parameters_saved_fields)
            field = parameters_saved_fields{i};
            value = parameters_saved.(field);
            if ~iscell(value)
                fprintf(fileID, '%s: %s\n', field, value);
            else
                for j = 1:length(value)
                    solvers_options_saved = trim_struct(value{j});
                    solvers_options_saved_fields = fieldnames(solvers_options_saved);
                    for k = 1:numel(solvers_options_saved_fields)
                        solvers_options_saved_field = solvers_options_saved_fields{k};
                        solvers_options_saved_value = solvers_options_saved.(solvers_options_saved_field);
                        fprintf(fileID, '%s: %s ', solvers_options_saved_field, ...
                            solvers_options_saved_value);
                    end
                    fprintf(fileID, '\n');
                end
            end
        end
        fclose(fileID);

        % Copy the source code and test code to path_outdir.
        copyfile(fullfile(path_src, "*"), path_testdata_src);
        copyfile(fullfile(path_competitors, "*"), path_testdata_competitors);
        copyfile(fullfile(path_tests, "private", "*"), path_testdata_private);
        copyfile(fullfile(path_root, "setup.m"), path_testdata_outdir);

        source_folder = path_tests;
        destination_folder = path_testdata_tests;

        % Get all files in the source folder.
        file_list = dir(fullfile(source_folder, '*.*'));
        file_list = file_list(~[file_list.isdir]);

        % Copy all files (excluding subfolders) to the destination folder.
        for i = 1:numel(file_list)
            source_file = fullfile(source_folder, file_list(i).name);
            destination_file = fullfile(destination_folder, file_list(i).name);
            copyfile(source_file, destination_file);
        end

        % Draw performance profiles.
        % Set tolerance of convergence test in the performance profile.
        tau = parameters.tau;
        tau_length = length(tau);

        options_perf.pdfname = parameters.pdfname;
        options_perf.solvers = parameters.solvers_legend;
        options_perf.natural_stop = false;

        % Draw log-profiles if necessary.
        if isfield(parameters, "log_profile") && parameters.log_profile
            options_perf.outdir = path_testdata_log_perf;
            for l = 1:tau_length
                options_perf.tau = tau(l);
                logprof(frec, fmin, parameters.solvers_name, length(problem_names), options_perf);
            end
            outputfile = char(strcat("merged", "_", log_profile, ".pdf"));
            merge_pdf(options_perf.outdir, outputfile, compdf_location);
            movefile(fullfile(options_perf.outdir, outputfile), ...
                fullfile(path_testdata_perf, outputfile));
        end

        options_perf.outdir = fullfile(path_testdata_perf, parameters.pdfname);
        if isfield(options_perf, "tau")
            options_perf = rmfield(options_perf, "tau");
        end

        % Draw profiles.
        if parameters.is_noisy
            options_perf.feature = strcat(parameters.feature, "-", num2str(sprintf('%.1e', parameters.noise_level)));
        else
            options_perf.feature = parameters.feature;
        end
        perfdata(tau, frec, fmin, options_perf);
    end

    message = 'During the tuning process, path_testdata_perf is no needed';
    if ~evalin('base', 'exist(''path_testdata_perf'', ''var'')')
        disp(message);
        path_testdata_perf = " ";
    end

catch exception

    % Do nothing for the moment.

end

% Restore the path to oldpath.
setpath(oldpath);
% Go back to the original directory.
cd(old_dir);

if ~isempty(exception)  % Rethrow any exception caught above.
    rethrow(exception);
end

end