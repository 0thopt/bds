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

dims = 1:10;
ir_values = 0:20;
seed_values = [12345, 23456, 34567];
prec = 0;
single_test = true;

run_iseqiv_suite( ...
    'reference-default-algorithmic', ...
    {'lean_evolved_bds_reference_for_iseqiv', ...
    'lean_evolved_bds_options_default_for_iseqiv'}, ...
    dims, ir_values, seed_values, single_test, prec, oldfolder);

verify_bds_style_output_contract();
verify_explicit_direction_set_smoke();

fprintf(['lean_evolved_bds_options passed all iseqiv checks: ', ...
    'default all-on algorithmic behavior vs reference Lean, dims=1:10, ', ...
    'ir=0:20, seeds=[12345 23456 34567], prec=0; ', ...
    'BDS-style output contract and explicit direction_set smoke checks passed.\n']);

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

function verify_bds_style_output_contract()

fprintf('\nRunning BDS-style output contract smoke checks...\n');

fun = @(x) sum((x - [1; -2]).^2);
x0 = [0; 0];

[~, ~, ~, output] = lean_evolved_bds_options(fun, x0);
assert_fields(output, {'funcCount', 'fhist', 'message'});

options = struct('output_xhist', true);
[~, ~, ~, output] = lean_evolved_bds_options(fun, x0, options);
assert_fields(output, {'funcCount', 'xhist', 'invalid_points', 'fhist', 'message'});

options = struct('output_alpha_hist', true);
[~, ~, ~, output] = lean_evolved_bds_options(fun, x0, options);
assert_fields(output, {'funcCount', 'alpha_hist', 'fhist', 'message'});

options = struct('output_block_hist', true);
[~, ~, ~, output] = lean_evolved_bds_options(fun, x0, options);
assert_fields(output, {'funcCount', 'blocks_hist', 'fhist', 'message'});

options = struct('output_grad_hist', true);
[~, ~, ~, output] = lean_evolved_bds_options(fun, x0, options);
assert_fields(output, {'funcCount', 'grad_hist', 'grad_xhist', 'grad_iter', 'fhist', 'message'});

options = struct('output_xhist', true, 'output_alpha_hist', true, ...
    'output_block_hist', true, 'output_grad_hist', true);
[~, ~, ~, output] = lean_evolved_bds_options(fun, x0, options);
assert_fields(output, {'funcCount', 'blocks_hist', 'alpha_hist', 'xhist', ...
    'invalid_points', 'grad_hist', 'grad_xhist', 'grad_iter', 'fhist', 'message'});

fprintf('BDS-style output contract smoke checks passed.\n');

end

function verify_explicit_direction_set_smoke()

fprintf('\nRunning explicit direction_set smoke check...\n');

fun = @(x) sum((x - [1; -2]).^2);
x0 = [0; 0];
theta = pi / 7;
Q = [cos(theta), -sin(theta); sin(theta), cos(theta)];
common = struct('MaxFunctionEvaluations', 400, 'StepTolerance', 1e-6, ...
    'num_blocks', 2, 'direction_set', Q, 'alpha_init', 1, ...
    'expand', 1.8, 'shrink', 0.5, ...
    'forcing_function', @(alpha) alpha^2, ...
    'reduction_factor', [0.1, 0.2, 0.3], ...
    'output_xhist', true);
lean_options = common;
lean_options.use_productive_direction_memory = false;
lean_options.use_sweep_pattern_direction = false;
lean_options.use_momentum_extrapolation = false;

[x_bds, f_bds, exitflag_bds, output_bds] = bds(fun, x0, common);
[x_lean, f_lean, exitflag_lean, output_lean] = lean_evolved_bds_options(fun, x0, lean_options);

if norm(x_bds - x_lean) ~= 0 || f_bds ~= f_lean || exitflag_bds ~= exitflag_lean ...
        || output_bds.funcCount ~= output_lean.funcCount || ~isequal(output_bds.fhist, output_lean.fhist)
    error('verify_lean_evolved_bds_options:DirectionSetSmokeFailure', ...
        'Explicit direction_set all-off smoke check failed.');
end

fprintf('Explicit direction_set smoke check passed.\n');

end

function assert_fields(output, expected_fields)

actual = sort(fieldnames(output));
expected = sort(expected_fields(:));
if ~isequal(actual, expected)
    error('verify_lean_evolved_bds_options:OutputContractFailure', ...
        'Expected fields [%s], got [%s].', ...
        strjoin(expected, ', '), strjoin(actual, ', '));
end

end

function restore_state(oldpath, oldfolder)

path(oldpath);
cd(oldfolder);

end
