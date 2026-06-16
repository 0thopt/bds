function tests = test_iseqiv_seed
%TEST_ISEQIV_SEED tests the random seed generation used by iseqiv.

tests = functiontests(localfunctions);

end

function test_algorithm_name_seed_is_valid(testCase)

seed = make_iseqiv_seed('ARWHEAD', 10, 3, -12.345, 'cbds', [1; -2; 3]);

verifyFalse(testCase, isnan(seed));
verifyEqual(testCase, rem(seed, 1), 0);
verifyGreaterThanOrEqual(testCase, seed, 0);
verifyLessThanOrEqual(testCase, seed, 2^32 - 1);

end

function test_algorithm_name_changes_seed(testCase)

seed_cbds = make_iseqiv_seed('ARWHEAD', 10, 3, -12.345, 'cbds', [1; -2; 3]);
seed_pbds = make_iseqiv_seed('ARWHEAD', 10, 3, -12.345, 'pbds', [1; -2; 3]);

verifyNotEqual(testCase, seed_cbds, seed_pbds);

end

function test_seed_is_clamped(testCase)

seed = make_iseqiv_seed('ARWHEAD', 10, 3, realmax, 'cbds', [1; -2; 3]);

verifyEqual(testCase, seed, 2^32 - 1);

end

function test_nan_real_component_keeps_seed_valid(testCase)

seed = make_iseqiv_seed('ARWHEAD', 10, 3, NaN, 'cbds', [1; -2; 3]);

verifyFalse(testCase, isnan(seed));
verifyEqual(testCase, rem(seed, 1), 0);
verifyGreaterThanOrEqual(testCase, seed, 0);
verifyLessThanOrEqual(testCase, seed, 2^32 - 1);

end
