function tests = test_parse_feature_value
%TEST_PARSE_FEATURE_VALUE tests numeric suffix parsing for profiler features.

tests = functiontests(localfunctions);

end

function test_default_value(testCase)

verifyEqual(testCase, parse_feature_value('noisy', 1e-3), 1e-3);
verifyEqual(testCase, parse_feature_value('rotation_noisy', 1e-3), 1e-3);
verifyEqual(testCase, parse_feature_value('noisy_', 1e-3), 1e-3);
verifyEqual(testCase, parse_feature_value('truncated', 6), 6);
verifyEqual(testCase, parse_feature_value('truncated_', 6), 6);

end

function test_noisy_one_e_minus_three_is_unchanged(testCase)

expected_value = 10.^(str2double('-3'));
verifyEqual(testCase, parse_feature_value('noisy_1e-3', 1e-3), expected_value);

end

function test_decimal_notation(testCase)

verifyEqual(testCase, parse_feature_value('noisy_0.001', 1e-3), 1e-3);

end

function test_long_exponent(testCase)

verifyEqual(testCase, parse_feature_value('noisy_1e-10', 1e-3), 1e-10);
verifyEqual(testCase, parse_feature_value('permuted_noisy_1e-10', 1e-3), 1e-10);

end

function test_composite_noisy_feature(testCase)

expected_value = 10.^(str2double('-3'));
verifyEqual(testCase, parse_feature_value('rotation_noisy_1e-3', 1e-3), expected_value);
verifyEqual(testCase, parse_feature_value('permuted_noisy_1e-3', 1e-3), expected_value);

end

function test_truncated_one_digit_is_unchanged(testCase)

expected_value = str2double('3');
verifyEqual(testCase, parse_feature_value('truncated_3', 6), expected_value);

old_noise_level = 10^(-3) / (2 * sqrt(3));
new_noise_level = 10^(-parse_feature_value('truncated_3', 6)) / (2 * sqrt(3));
verifyEqual(testCase, new_noise_level, old_noise_level);

end

function test_truncated_multiple_digits(testCase)

verifyEqual(testCase, parse_feature_value('truncated_12', 6), 12);

end
