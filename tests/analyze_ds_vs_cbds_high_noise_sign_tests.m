function output_file = analyze_ds_vs_cbds_high_noise_sign_tests(analysis_file)
%ANALYZE_DS_VS_CBDS_HIGH_NOISE_SIGN_TESTS tests problem-majority outcomes.

loaded = load(analysis_file, 'analysis');
analysis = loaded.analysis;
rows = {};

for i_feature = 1:numel(analysis.features)
    feature = analysis.features(i_feature);
    table = feature.problem_table;
    filters = build_filters(table);
    for i_filter = 1:numel(filters)
        selected = filters(i_filter).selected;
        ds_majority = sum(table.ds_wins(selected) > table.cbds_wins(selected));
        cbds_majority = sum(table.cbds_wins(selected) > table.ds_wins(selected));
        problem_ties = sum(table.ds_wins(selected) == table.cbds_wins(selected));
        p_value = exact_two_sided_sign_test(ds_majority, cbds_majority);
        rows(end + 1, :) = {feature.name, filters(i_filter).name, ...
            sum(selected), ds_majority, cbds_majority, problem_ties, ...
            p_value, sum(table.ds_wins(selected)), ...
            sum(table.cbds_wins(selected)), sum(table.ties(selected))}; %#ok<AGROW>
    end
end

sign_tests = cell2table(rows, 'VariableNames', ...
    {'feature', 'filter', 'n_problems', 'ds_problem_majorities', ...
    'cbds_problem_majorities', 'problem_ties', 'exact_sign_test_p_value', ...
    'ds_run_wins', 'cbds_run_wins', 'run_ties'});

output_dir = fileparts(analysis_file);
output_file = fullfile(output_dir, 'problem_majority_sign_tests.mat');
save(output_file, 'sign_tests');
writetable(sign_tests, fullfile(output_dir, 'problem_majority_sign_tests.csv'));
write_report(sign_tests, fullfile(output_dir, 'problem_majority_sign_tests.md'));
fprintf('Problem-majority sign tests: %s\n', output_file);

end

function filters = build_filters(table)
flags = table.family_flag;
filters(1).name = 'all';
filters(1).selected = true(height(table), 1);
filters(2).name = 'exclude_unknown_or_unbounded';
filters(2).selected = ~strcmp(flags, 'unknown_or_unbounded_below');
filters(3).name = 'unknown_or_unbounded_below';
filters(3).selected = strcmp(flags, 'unknown_or_unbounded_below');
filters(4).name = 'least_squares_or_residual';
filters(4).selected = strcmp(flags, 'least_squares_or_residual');
filters(5).name = 'other';
filters(5).selected = strcmp(flags, 'other');
end

function p_value = exact_two_sided_sign_test(ds_wins, cbds_wins)
n = ds_wins + cbds_wins;
if n == 0
    p_value = 1;
    return;
end
k = 0:min(ds_wins, cbds_wins);
log_probabilities = gammaln(n + 1) - gammaln(k + 1) ...
    - gammaln(n - k + 1) - n * log(2);
p_value = min(1, 2 * sum(exp(log_probabilities)));
end

function write_report(sign_tests, filename)
fid = fopen(filename, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Problem-Majority Exact Sign Tests\n\n');
fprintf(fid, 'Tied problems are excluded from the exact two-sided sign test.\n\n');
fprintf(fid, '| Feature | Filter | Problem majority DS/CBDS/tie | Run wins DS/CBDS/tie | Exact p |\n');
fprintf(fid, '| --- | --- | ---: | ---: | ---: |\n');
for i = 1:height(sign_tests)
    fprintf(fid, '| `%s` | `%s` | %d/%d/%d | %d/%d/%d | %.6g |\n', ...
        sign_tests.feature{i}, sign_tests.filter{i}, ...
        sign_tests.ds_problem_majorities(i), ...
        sign_tests.cbds_problem_majorities(i), sign_tests.problem_ties(i), ...
        sign_tests.ds_run_wins(i), sign_tests.cbds_run_wins(i), ...
        sign_tests.run_ties(i), sign_tests.exact_sign_test_p_value(i));
end
end
