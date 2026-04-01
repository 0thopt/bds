function profile_problem_case(options)

options.n_jobs = 1;

solvers = cell(1, 2);
for i = 1:length(options.solver_names)
    switch options.solver_names{i}
        case 'cbds-default'
            solvers{i} = @cbds_default;
        case 'cbds-orig-smart-alpha-init'
            solvers{i} = @cbds_orig_smart_alpha_init_test;
        case 'cbds-tmp'
            solvers{i} = @cbds_tmp;
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

opts_new = struct();
opts_new.alpha_init = 'auto';

x = bds(fun, x0, opts_new);
    
end

function x = cbds_tmp(fun, x0)

opts_def = struct();
opts_def.alpha_init = 1; % Default setting

x = bds_tmp(fun, x0, opts_def);

end