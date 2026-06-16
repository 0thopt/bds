function tests = test_scalar_function
%TEST_SCALAR_FUNCTION tests the ScalarFunction wrapper.

tests = functiontests(localfunctions);

end

function test_non_noisy_two_outputs(testCase)

problem.objective = @(x) sum(x.^2);
scalar_fun = ScalarFunction(problem, false);

[f, g] = scalar_fun.fun([1; 2]);

verifyEqual(testCase, f, 5);
verifyEmpty(testCase, g);
verifyEqual(testCase, scalar_fun.nEval, 1);

end

function test_non_noisy_two_outputs_with_explicit_flag(testCase)

problem.objective = @(x) sum(x.^2);
scalar_fun = ScalarFunction(problem, false);

[f, g] = scalar_fun.fun([1; 2], false);

verifyEqual(testCase, f, 5);
verifyEmpty(testCase, g);
verifyEqual(testCase, scalar_fun.nEval, 1);

end

function test_noisy_gradient_still_returned(testCase)

problem.objective = @(x) sum(x.^2);
scalar_fun = ScalarFunction(problem, false);

options.noise_type = "gaussian";
options.is_abs_noise = true;
options.noise_level = 1e-6;
options.with_gradient = true;

[~, g] = scalar_fun.fun([1; 2], true, 1, options);

verifySize(testCase, g, [2, 1]);
verifyFalse(testCase, any(isnan(g)));
verifyEqual(testCase, scalar_fun.nEval, 3);

end
