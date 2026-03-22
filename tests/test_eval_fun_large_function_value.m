clc; clear; close all;

% =========================================================================
% Test Scenario: NaN handling with very large valid function values
%
% Goal:
%   Compare two NaN-handling rules on the same direct-search example:
%   1. bds:     NaN -> Inf
%   2. bds_tmp: NaN -> 1e30
%
% Design principle:
%   Valid function values are chosen to be only moderately larger than 1e30
%   near x0. Then NaN -> 1e30 creates a visible false-improvement plateau,
%   while NaN -> Inf continues to move toward the true minimizer.
% =========================================================================

% The true objective: the global minimizer is x_opt = [0; 0] with f(x_opt)=0.
% If x(1) >= 2.5, the evaluation fails and returns NaN.
scale = 3e29;
fun_test = @(x) trap_fun(x, scale);

x_opt = [0; 0];
x0 = [2; 2];
f0 = scale * sum(x0.^2);

fprintf('============================================================\n');
fprintf('TEST CASE: NaN handling with moderately large valid values\n');
fprintf('x0 = [%g, %g]^T,    f(x0) = %.1e\n', x0(1), x0(2), f0);
fprintf('Trap region: x(1) >= 2.5  -->  f(x) = NaN\n');
fprintf('True minimizer: x_opt = [0, 0]^T,    f(x_opt) = 0\n');
fprintf('Reference barrier: NaN -> 1e30 corresponds to %g * f(x0)\n', 1e30 / f0);
fprintf('============================================================\n');

%% 1. Run bds: NaN -> Inf
fprintf('\n--- [1] Running bds (NaN -> Inf) ---\n');
options = struct();
options.iprint = 0;
options.MaxFunctionEvaluations = 500;
[xopt_inf, fopt_inf, exitflag_inf, output_inf] = bds(fun_test, x0, options);

%% 2. Run bds_tmp: NaN -> 1e30
fprintf('\n--- [2] Running bds_tmp (NaN -> 1e30) ---\n');
options = struct();
options.iprint = 0;
options.MaxFunctionEvaluations = 500;
[xopt_large, fopt_large, exitflag_large, output_large] = bds_tmp(fun_test, x0, options);

%% 3. Results Analysis
fprintf('\n============================================================\n');
fprintf('                  COMPARATIVE RESULTS                       \n');
fprintf('============================================================\n');

dist_inf = norm(xopt_inf - x_opt);
dist_large = norm(xopt_large - x_opt);

fprintf('\n%-22s | %-10s | %-15s | %-15s\n', ...
    'Method', 'Func Evals', 'Final Value', 'Distance to x_opt');
fprintf('%s\n', repmat('-', 1, 80));
fprintf('%-22s | %-10d | %-15.4e | %-15.4e\n', ...
    'bds (NaN -> Inf)', output_inf.funcCount, fopt_inf, dist_inf);
fprintf('%-22s | %-10d | %-15.4e | %-15.4e\n', ...
    'bds_tmp (NaN -> 1e30)', output_large.funcCount, fopt_large, dist_large);
fprintf('%s\n', repmat('-', 1, 80));

nan_count_inf = sum(isnan(output_inf.fhist));
nan_count_large = sum(isnan(output_large.fhist));
fprintf('\nNaN evaluations in bds      : %d\n', nan_count_inf);
fprintf('NaN evaluations in bds_tmp  : %d\n', nan_count_large);

if fopt_inf < 1e-8 && fopt_large > 1e29
    fprintf('\nCONCLUSION: SUCCESS. NaN -> Inf rejects the trap, while NaN -> 1e30 accepts it.\n');
else
    fprintf('\nCONCLUSION: The separation is weaker than expected. Please inspect the histories.\n');
end

%% 4. Thesis-Oriented Figure
% We plot the cumulative minimum of all valid function values encountered
% up to each function evaluation. NaN values are ignored in the cumulative
% minimum. In this test, f(x0) is valid, so the curve starts from 1 after
% normalization by f(x0).

best_inf_plot = normalized_valid_cummin(output_inf.fhist(:), f0);
best_large_plot = normalized_valid_cummin(output_large.fhist(:), f0);
eval_axis_inf = 1:length(best_inf_plot);
eval_axis_large = 1:length(best_large_plot);

fig = figure('Color', 'w', 'Position', [100, 100, 980, 640]);
hold on;
grid on;
box on;

plot(eval_axis_inf, best_inf_plot, 'LineWidth', 2.8, ...
    'Color', [0.00, 0.45, 0.74]);
plot(eval_axis_large, best_large_plot, 'LineWidth', 2.8, ...
    'Color', [0.85, 0.33, 0.10]);

scatter(eval_axis_inf(end), best_inf_plot(end), 80, ...
    'MarkerFaceColor', [0.00, 0.45, 0.74], ...
    'MarkerEdgeColor', 'k', 'LineWidth', 0.8);
scatter(eval_axis_large(end), best_large_plot(end), 80, ...
    'MarkerFaceColor', [0.85, 0.33, 0.10], ...
    'MarkerEdgeColor', 'k', 'LineWidth', 0.8);

xlabel('$m$ (function evaluation index)', 'Interpreter', 'latex', 'FontSize', 16);
ylabel('$\phi_m/f(x_0)$', 'Interpreter', 'latex', 'FontSize', 16);
title('NaN $\rightarrow \infty$ avoids a false-improvement plateau', ...
    'Interpreter', 'latex', 'FontSize', 15, 'FontWeight', 'bold');
legend({'bds: NaN to Inf', 'bds\_tmp: NaN to 1e30'}, ...
    'Interpreter', 'tex', 'Location', 'northeast', 'FontSize', 14);
ylim([-0.03, 1.05]);

ax = gca;
ax.FontSize = 13;
ax.Position = [0.11, 0.16, 0.84, 0.76];
ax.Toolbar.Visible = 'off';

f0_latex = latex_sci(f0, 1);

annotation_text = sprintf([ ...
    '$f(x)=\\left\\{\\begin{array}{ll}3\\times 10^{29}\\|x\\|_2^2, & x(1)<2.5,\\\\ \\mathrm{NaN}, & x(1)\\ge 2.5,\\end{array}\\right.$\n' ...
    '$x_{\\mathrm{opt}}=[0,0]^T$, \\quad $x_0=[%g,\\,%g]^T$, \\quad $f(x_0)=%s$\n' ...
    '$f_m$: function value at the $m$-th function evaluation\n' ...
    '$\\phi_m:=\\min\\{f_i:1\\le i\\le m,\\ f_i\\neq \\mathrm{NaN}\\}$'], ...
    x0(1), x0(2), f0_latex);

text(0.18 * max([eval_axis_inf(end), eval_axis_large(end)]), ...
    0.90 * max([best_inf_plot(1), best_large_plot(1)]), ...
    annotation_text, ...
    'FontSize', 12.5, ...
    'BackgroundColor', [1.0, 1.0, 1.0], ...
    'EdgeColor', [0.35, 0.35, 0.35], ...
    'Margin', 12, ...
    'VerticalAlignment', 'top', ...
    'Interpreter', 'latex');

script_dir = fileparts(mfilename('fullpath'));
exportgraphics(ax, fullfile(script_dir, 'test_eval_fun_large_function_value.pdf'), ...
    'ContentType', 'vector', 'BackgroundColor', 'white');
exportgraphics(ax, fullfile(script_dir, 'test_eval_fun_large_function_value.png'), ...
    'Resolution', 300, 'BackgroundColor', 'white');

fprintf('\n[Figure Export]\n');
fprintf('  PDF : %s\n', fullfile(script_dir, 'test_eval_fun_large_function_value.pdf'));
fprintf('  PNG : %s\n', fullfile(script_dir, 'test_eval_fun_large_function_value.png'));

%% Helper function
function f = trap_fun(x, scale)
    f = scale * sum(x.^2);
    if x(1) >= 2.5
        f = nan;
    end
end

function best_plot = normalized_valid_cummin(fhist, baseline)
    best_plot = nan(size(fhist));
    current_best = baseline;
    for i = 1:length(fhist)
        if ~isnan(fhist(i))
            current_best = min(current_best, fhist(i));
        end
        best_plot(i) = current_best / baseline;
    end
end

function s = latex_sci(x, digits)
    if x == 0
        s = '0';
        return;
    end

    exponent = floor(log10(abs(x)));
    mantissa = x / 10^exponent;
    s = sprintf(['%0.', num2str(digits), 'f\\times 10^{%d}'], mantissa, exponent);
end
