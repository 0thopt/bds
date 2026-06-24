function verify_lean_evolved_bds_options()
%VERIFY_LEAN_EVOLVED_BDS_OPTIONS verifies the options-enabled Lean solver.
%
% This verifier intentionally lives in tests/ so that it can use the
% tests/private/iseqiv.m validation path. It does not modify bds.m.

path_tests = fileparts(mfilename('fullpath'));
path_root = fileparts(path_tests);
oldpath = path();
oldfolder = pwd();
cleanup = onCleanup(@() restore_state(oldpath, oldfolder));

addpath(fullfile(path_tests, 'competitors'));
addpath(fullfile(path_root, 'src'));
cd(path_tests);

dims = 1:5;
ir_values = 0:20;
seed_values = [12345, 23456, 34567];
prec = 0;
single_test = true;

run_iseqiv_suite( ...
    'reference-default', ...
    {'lean_evolved_bds_reference_for_iseqiv', ...
    'lean_evolved_bds_options_default_for_iseqiv'}, ...
    dims, ir_values, seed_values, single_test, prec, oldfolder);

run_iseqiv_suite( ...
    'bds-compatible', ...
    {'bds_for_iseqiv', ...
    'lean_evolved_bds_options_bds_compatible_for_iseqiv'}, ...
    dims, ir_values, seed_values, single_test, prec, oldfolder);

fprintf(['lean_evolved_bds_options passed all iseqiv checks: ', ...
    'dims=1:5, ir=0:20, seeds=[12345 23456 34567], prec=0.\n']);

end

function run_iseqiv_suite(suite_name, solvers, dims, ir_values, seed_values, single_test, prec, oldfolder)

num_cases = numel(dims) * numel(ir_values) * numel(seed_values);
case_count = 0;
fprintf('\nRunning %s iseqiv suite (%d cases)...\n', suite_name, num_cases);

for seed = seed_values
    for n = dims
        p = toy_problem(n);
        for ir = ir_values
            case_count = case_count + 1;
            options = struct();
            options.seed = seed;
            options.olddir = oldfolder;
            options.sequential = false;

            ok = iseqiv(solvers, p, ir, single_test, prec, options);
            if ~ok
                error('verify_lean_evolved_bds_options:IseqivFailure', ...
                    '%s failed for n=%d, ir=%d, seed=%d.', ...
                    suite_name, n, ir, seed);
            end

            fprintf('[%s] case %03d/%03d passed: n=%d, ir=%d, seed=%d\n', ...
                suite_name, case_count, num_cases, n, ir, seed);
        end
    end
end

fprintf('%s iseqiv suite passed.\n', suite_name);

end

function p = toy_problem(n)

p.name = sprintf('LEANREF%d', n);
p.x0 = (1:n)' / 3;
p.objective = @(x) toy_objective(x);

    function f = toy_objective(x)
        x = x(:);
        target = ((-1).^(1:n))' .* (1:n)' / 5;
        A = diag(1:n) + 0.1 * ones(n);
        f = sum((A * (x - target)).^2) + 0.01 * sum(sin(x));
    end

end

function restore_state(oldpath, oldfolder)

path(oldpath);
cd(oldfolder);

end
