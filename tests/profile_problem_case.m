function profile_problem_case(options)

options.n_jobs = 1;

solvers = cell(1, 2);
for i = 1:length(options.solver_names)
    switch options.solver_names{i}
        case 'cbds-default'
            solvers{i} = @cbds_default;
        case 'cbds-orig-smart-alpha-init'
            solvers{i} = @cbds_orig_smart_alpha_init_test;
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

if ~isfield(options, 'problem_names')
    error('options.problem_names is required');
else
    options.benchmark_id = [options.benchmark_id, '_', strjoin(options.problem_names, '_')];
end

if ~isfield(options, 'savepath')
    options.savepath = fullfile(fileparts(mfilename('fullpath')), 'testdata');
end

benchmark(solvers, options);

end


function x = cbds_default(fun, x0)

opts_def = struct();
opts_def.alpha_init = 1; % Default setting

x = bds(fun, x0, opts_def);

end


function x = cbds_orig_smart_alpha_init_test(fun, x0)

abs_x0 = abs(x0);
nonzero_abs_x0 = abs_x0(abs_x0 > 0);
if isempty(nonzero_abs_x0)
    x0_scale_ratio = 1;
else
    x0_scale_ratio = max(nonzero_abs_x0) / min(nonzero_abs_x0);
end

n = length(x0);

for i = 1:n
    abs_x0_i = abs_x0(i);
    if abs_x0_i == 0
        alpha_vec(i) = 1;
    elseif abs_x0_i <= 1
        alpha_vec(i) = max(abs_x0_i, step_tolerance(i));
    else
        if x0_scale_ratio <= 100
            alpha_vec(i) = abs_x0_i;
        else
            alpha_vec(i) = 1 + log10(abs_x0_i);
        end
    end
end

opts_new = struct();
opts_new.alpha_init = alpha_vec;

x = bds(fun, x0, opts_new);
    
end