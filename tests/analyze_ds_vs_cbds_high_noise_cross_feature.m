function output_file = analyze_ds_vs_cbds_high_noise_cross_feature(analysis_file)
%ANALYZE_DS_VS_CBDS_HIGH_NOISE_CROSS_FEATURE compares feature-level rankings.

loaded = load(analysis_file, 'analysis');
analysis = loaded.analysis;
plain = feature_by_name(analysis, 'plain');
noise_2 = feature_by_name(analysis, 'noisy_1e-2');
noise_1 = feature_by_name(analysis, 'noisy_1e-1');

problem_names = plain.problem_table.problem;
rows = cell(numel(problem_names), 18);
for i = 1:numel(problem_names)
    name = problem_names{i};
    p = row_by_problem(plain.problem_table, name);
    n2 = row_by_problem(noise_2.problem_table, name);
    n1 = row_by_problem(noise_1.problem_table, name);
    rows(i, :) = {name, p.n, classify_problem(name), ...
        p.ds_wins, p.cbds_wins, p.ties, ...
        n2.ds_wins, n2.cbds_wins, n2.ties, ...
        n1.ds_wins, n1.cbds_wins, n1.ties, ...
        p.median_best_true_advantage_ds, ...
        n2.median_best_true_advantage_ds, ...
        n1.median_best_true_advantage_ds, ...
        n2.profile_gap_contribution, n1.profile_gap_contribution, ...
        sign(n1.median_best_true_advantage_ds) ...
            ~= sign(p.median_best_true_advantage_ds)};
end
cross_feature = cell2table(rows, 'VariableNames', ...
    {'problem', 'n', 'family_flag', 'plain_ds_wins', 'plain_cbds_wins', ...
    'plain_ties', 'noise_1e_2_ds_wins', 'noise_1e_2_cbds_wins', ...
    'noise_1e_2_ties', 'noise_1e_1_ds_wins', 'noise_1e_1_cbds_wins', ...
    'noise_1e_1_ties', 'plain_median_gap_ds', 'noise_1e_2_median_gap_ds', ...
    'noise_1e_1_median_gap_ds', 'noise_1e_2_profile_contribution', ...
    'noise_1e_1_profile_contribution', 'plain_to_1e_1_sign_reversal'});

output_dir = fileparts(analysis_file);
output_file = fullfile(output_dir, 'cross_feature_analysis.mat');
save(output_file, 'cross_feature', '-v7.3');
writetable(cross_feature, fullfile(output_dir, 'cross_feature_problem_table.csv'));
write_report(cross_feature, analysis, fullfile(output_dir, 'cross_feature_analysis.md'));
fprintf('Cross-feature analysis: %s\n', output_file);
end

function feature = feature_by_name(analysis, name)
index = find(strcmp({analysis.features.name}, name), 1);
assert(~isempty(index), 'Feature %s was not found.', name);
feature = analysis.features(index);
end

function row = row_by_problem(table, name)
index = find(strcmp(table.problem, name), 1);
assert(~isempty(index), 'Problem %s was not found.', name);
row = table(index, :);
end

function flag = classify_problem(name)
if ismember(name, {'INDEF', 'INDEFM', 'FLETCHBV', 'FLETBV3M', ...
        'CURLY10', 'CURLY20', 'CURLY30', 'SCURLY10', 'SCURLY20', ...
        'SCURLY30'})
    flag = 'unknown_or_unbounded_below';
elseif endsWith(name, 'LS') || startsWith(name, 'PALMER') ...
        || ismember(name, {'EXTROSNB', 'SBRYBND', 'SSBRYBND', ...
        'BRYBND', 'BROYDNBDLS', 'MSQRTALS', 'MSQRTBLS'})
    flag = 'least_squares_or_residual';
else
    flag = 'other';
end
end

function write_report(table, analysis, filename)
fid = fopen(filename, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# DS vs CBDS Cross-Feature Analysis\n\n');
fprintf(fid, '## Aggregate scores\n\n');
fprintf(fid, '| Feature | DS | CBDS | DS run wins | CBDS run wins | Ties |\n');
fprintf(fid, '| --- | ---: | ---: | ---: | ---: | ---: |\n');
for i = 1:numel(analysis.features)
    feature = analysis.features(i);
    T = feature.problem_table;
    fprintf(fid, '| `%s` | %.6f | %.6f | %d | %d | %d |\n', ...
        feature.name, feature.full_scores(1), feature.full_scores(2), ...
        sum(T.ds_wins), sum(T.cbds_wins), sum(T.ties));
end

reversals = table(table.plain_to_1e_1_sign_reversal, :);
reversals = sortrows(reversals, 'noise_1e_1_profile_contribution', 'descend');
fprintf(fid, '\n## Largest plain-to-1e-1 sign reversals\n\n');
fprintf(fid, '| Problem | Family | Plain gap | 1e-1 gap | 1e-1 contribution |\n');
fprintf(fid, '| --- | --- | ---: | ---: | ---: |\n');
for i = 1:min(30, height(reversals))
    fprintf(fid, '| `%s` | `%s` | %.6g | %.6g | %+.6g |\n', ...
        reversals.problem{i}, reversals.family_flag{i}, ...
        reversals.plain_median_gap_ds(i), ...
        reversals.noise_1e_1_median_gap_ds(i), ...
        reversals.noise_1e_1_profile_contribution(i));
end

fprintf(fid, '\n## Family-level high-noise run outcomes\n\n');
families = unique(table.family_flag, 'stable');
fprintf(fid, '| Family | Problems | 1e-2 DS/CBDS/tie | 1e-1 DS/CBDS/tie |\n');
fprintf(fid, '| --- | ---: | ---: | ---: |\n');
for i = 1:numel(families)
    selected = strcmp(table.family_flag, families{i});
    fprintf(fid, '| `%s` | %d | %d/%d/%d | %d/%d/%d |\n', ...
        families{i}, sum(selected), ...
        sum(table.noise_1e_2_ds_wins(selected)), ...
        sum(table.noise_1e_2_cbds_wins(selected)), ...
        sum(table.noise_1e_2_ties(selected)), ...
        sum(table.noise_1e_1_ds_wins(selected)), ...
        sum(table.noise_1e_1_cbds_wins(selected)), ...
        sum(table.noise_1e_1_ties(selected)));
end
end
