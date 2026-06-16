function tests = test_iseqiv_row_input
%TEST_ISEQIV_ROW_INPUT tests row-vector input handling in iseqiv.

tests = functiontests(localfunctions);

end

function test_iseqiv_uses_row_input_once(testCase)

path_tests = fileparts(mfilename('fullpath'));
path_root = fileparts(path_tests);
oldpath = path();
cleanup = onCleanup(@() path(oldpath));
addpath(fullfile(path_root, 'src'));

p.name = 'QUAD';
p.objective = @(x) sum(x(:).^2);
p.x0 = (1:4)';

ir = 0;
options = struct();
options.Algorithm = 'cbds';
options.seed = seed_for_row_input(p.name, length(p.x0), ir);
options.MaxFunctionEvaluations = 80;
options.olddir = pwd();
options.sequential = true;

verifyTrue(testCase, iseqiv({'bds', 'bds'}, p, ir, true, 0, options));

end

function yw = seed_for_row_input(pname, n, ir)

for yw = 1:1000
    rseed = max(0, min(2^32 - 1, sum(pname) + n + ir + yw));
    rng_state = rng();
    rng(rseed);
    cleanup = onCleanup(@() rng(rng_state));

    randn(n, 1);
    rand;
    randn;
    rand;
    rand;
    use_row_input = (rand > 0.5);
    delete(cleanup);

    if use_row_input
        return
    end
end

error('Could not find a seed that exercises the row-vector input branch.');

end
