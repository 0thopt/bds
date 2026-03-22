clc; clear; close all;

%% TEST CASE: 3D "Deep Trap" Basin
% -------------------------------------------------------------------------
% Objective:
%   To demonstrate failure of Default Strategy in a landscape where local 
%   gradients OVERWHELM global gradients at the micro-scale.
%
% Configuration:
%   - Global Gradient: ~ 20,000 (Pushing to optimum)
%   - Local Gradient:  ~ 200,000 (Resisting motion)
%   
%   Ratio ~ 10:1. The "Default Step (1.0)" faces a wall 10x steeper than 
%   the downward slope. It MUST get trapped.
%   The "Smart Step (5500)" sees the global drop of ~10^10 over its stride,
%   ignoring the local oscillation of ~10^5.
% -------------------------------------------------------------------------

% --- Problem Setup ---
n = 3;
x_opt = 100000 * ones(n, 1);
x0    = 110000 * ones(n, 1);

% Define Function: 
% Increased Amplitude 'A' from 4e4 to 2e5.
% Trap is now 5x deeper than before.
% OLD:
% fun = @(x) sum((x - x_opt).^2) + 2e5 * sum(cos(1.0 * x));

% NEW (Rigorous):
% Aligns the cosine valley exactly with the quadratic bottom.
fun = @(x) sum((x - x_opt).^2) + 2e5 * sum(1 - cos(x - x_opt));

fprintf('============================================================\n');
fprintf('TEST CASE: 3D Deep Trap Basin\n');
fprintf('Condition: Local Gradient (200k) >>> Global Gradient (20k)\n');
fprintf('============================================================\n');

%% 1. Run Default Strategy
opts_def = struct();
opts_def.num_blocks = n;
opts_def.alpha_init = 1.0; 
opts_def.iprint = 1;

fprintf('\n--- [1] Running Default Strategy (alpha = 1.0) ---\n');
[x_def, f_def, exit_def, out_def] = bds(fun, x0, opts_def);

%% 2. Run Smart Initialization Strategy
% Strategy: use the current auto rule from bds.m.
% Since all components of x0 have the same large scale and x0_scale_ratio=1,
% the auto rule returns alpha_init(i)=|x0(i)| for every coordinate here.

abs_x0 = abs(x0);
nonzero_abs_x0 = abs_x0(abs_x0 > 0);
if isempty(nonzero_abs_x0)
    x0_scale_ratio = 1;
else
    x0_scale_ratio = max(nonzero_abs_x0) / min(nonzero_abs_x0);
end

alpha_vec = zeros(n, 1);
step_tolerance = 1e-6 * ones(n, 1);
for i = 1:n
    abs_x0_i = abs_x0(i);
    if abs_x0_i == 0
        alpha_vec(i) = 1;
    elseif abs_x0_i <= 1
        alpha_vec(i) = max(abs_x0_i, step_tolerance(i));
    else
        if x0_scale_ratio <= 100
            alpha_vec(i) = abs_x0_i;
        else
            alpha_vec(i) = 1 + log10(abs_x0_i);
        end
    end
end

opts_new = struct();
opts_new.num_blocks = n;
opts_new.alpha_init = alpha_vec;
opts_new.iprint = 1;

fprintf('\n--- [2] Running Smart Init Strategy (Scaled Alpha) ---\n');
[x_new, f_new, exit_new, out_new] = bds(fun, x0, opts_new);

%% 3. Results Analysis

fprintf('\n============================================================\n');
fprintf('                  COMPARATIVE RESULTS (DEEP TRAP)           \n');
fprintf('============================================================\n');

dist_def = norm(x_def - x_opt);
dist_new = norm(x_new - x_opt);

% Threshold for "Global Basin" is looser due to high noise amplitude
status_def = "TRAPPED (Local Min)";
if dist_def < 5000, status_def = "SUCCESS (Global Basin)"; end

status_new = "TRAPPED (Local Min)";
if dist_new < 5000, status_new = "SUCCESS (Global Basin)"; end

fprintf('%-15s | %-10s | %-15s | %-s\n', 'Strategy', 'Func Evals', 'Final Dist', 'Result');
fprintf('%s\n', repmat('-', 1, 90));

fprintf('%-15s | %-10d | %-15.4e | %s\n', ...
    'Default (1.0)', out_def.funcCount, dist_def, status_def);

fprintf('%-15s | %-10d | %-15.4e | %s\n', ...
    'Smart Init', out_new.funcCount, dist_new, status_new);

fprintf('%s\n', repmat('-', 1, 90));

fprintf('\n[Initialization Analysis]\n');
fprintf('  Default Alpha      : (1, 1, 1)^T\n');
fprintf('  x0 scale ratio     : %.2e\n', x0_scale_ratio);
fprintf('  Smart Alpha        : [%.2e, %.2e, %.2e]^T\n', alpha_vec(1), alpha_vec(2), alpha_vec(3));
fprintf('  Logic              : alpha_init(i) = |x0(i)|\n');

% Verification
if dist_def > 10000 && dist_new < 5000
    fprintf('\nCONCLUSION: SUCCESS. The deep trap caught the default strategy.\n');
else
    fprintf('\nCONCLUSION: Result is ambiguous. Trap might need frequency adjustment.\n');
end

%% 4. Thesis-Oriented Figure
f0 = fun(x0);
fhist_def_best = cummin(out_def.fhist(:));
fhist_new_best = cummin(out_new.fhist(:));
fhist_def_plot = max(fhist_def_best / f0, realmin);
fhist_new_plot = max(fhist_new_best / f0, realmin);
eval_axis_def = 1:length(fhist_def_plot);
eval_axis_new = 1:length(fhist_new_plot);

fig = figure('Color', 'w', 'Position', [100, 100, 980, 640]);
hold on;
grid on;
box on;

h_scaled = semilogy(eval_axis_new, fhist_new_plot, 'LineWidth', 2.6, ...
    'Color', [0.47, 0.67, 0.19]);
h_def = semilogy(eval_axis_def, fhist_def_plot, 'LineWidth', 3.0, ...
    'Color', [0.85, 0.33, 0.10]);

scatter(eval_axis_def(end), fhist_def_plot(end), 80, ...
    'MarkerFaceColor', [0.85, 0.33, 0.10], ...
    'MarkerEdgeColor', 'k', 'LineWidth', 0.8);
scatter(eval_axis_new(end), fhist_new_plot(end), 80, ...
    'MarkerFaceColor', [0.47, 0.67, 0.19], ...
    'MarkerEdgeColor', 'k', 'LineWidth', 0.8);

xlabel('$m$ (function evaluation index)', 'Interpreter', 'latex', 'FontSize', 16);
ylabel('$\min\{f_1,\ldots,f_m\}/f(x_0)$', 'Interpreter', 'latex', 'FontSize', 16);
title('Scaled initial steps escape the rugged local trap', ...
    'FontSize', 15, 'FontWeight', 'bold');
legend([h_def, h_scaled], {'Default alpha = 1.0', 'Scaled alpha'}, ...
    'Location', 'northeast', 'FontSize', 14);

ax = gca;
ax.FontSize = 13;
ax.Position = [0.11, 0.16, 0.84, 0.76];
ax.Toolbar.Visible = 'off';

f_x0_latex = latex_sci(fun(x0), 1);
alpha_scaled_latex = latex_sci(alpha_vec(1), 1);

annotation_text = sprintf([ ...
    '$f(x)=\\sum_{i=1}^{3}(x_i-10^5)^2 + 2\\times 10^5\\sum_{i=1}^{3}(1-\\cos(x_i-10^5))$\n' ...
    '$x_{\\mathrm{opt}}=10^5(1,1,1)^T$, \\quad $x_0=1.1\\times 10^5(1,1,1)^T$, \\quad $f(x_0)=%s$\n' ...
    '$f_m$: function value at the $m$-th function evaluation\n' ...
    '$\\alpha_{\\mathrm{default}}=(1,1,1)^T$\n' ...
    '$\\alpha_{\\mathrm{scaled}}=%s(1,1,1)^T$'], ...
    f_x0_latex, alpha_scaled_latex);

text(0.40 * max([eval_axis_def(end), eval_axis_new(end)]), ...
    0.84 * max([fhist_def_plot(1), fhist_new_plot(1)]), ...
    annotation_text, ...
    'FontSize', 12.5, ...
    'BackgroundColor', [1.0, 1.0, 1.0], ...
    'EdgeColor', [0.35, 0.35, 0.35], ...
    'Margin', 12, ...
    'VerticalAlignment', 'top', ...
    'Interpreter', 'latex');

script_dir = fileparts(mfilename('fullpath'));
exportgraphics(ax, fullfile(script_dir, 'test_alpha_init_rugged_landscape.pdf'), ...
    'ContentType', 'vector', 'BackgroundColor', 'white');
exportgraphics(ax, fullfile(script_dir, 'test_alpha_init_rugged_landscape.png'), ...
    'Resolution', 300, 'BackgroundColor', 'white');

fprintf('\n[Figure Export]\n');
fprintf('  PDF : %s\n', fullfile(script_dir, 'test_alpha_init_rugged_landscape.pdf'));
fprintf('  PNG : %s\n', fullfile(script_dir, 'test_alpha_init_rugged_landscape.png'));

function s = latex_sci(x, digits)
if x == 0
    s = '0';
    return;
end

exponent = floor(log10(abs(x)));
mantissa = x / 10^exponent;
s = sprintf(['%0.', num2str(digits), 'f\\times 10^{%d}'], mantissa, exponent);
end
