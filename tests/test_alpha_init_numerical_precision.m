clc; clear; close all;

%% TEST CASE: Machine Precision Limit Verification
% -------------------------------------------------------------------------
% Objective: 
%   To demonstrate the phenomenon of "Numerical Blindness" or "Step Absorption"
%   in unscaled optimization problems using double-precision floating-point arithmetic.
%
% Theoretical Background:
%   In IEEE 754 double precision, the machine epsilon at 1e16 is greater than 1.0.
%   Specifically, numerically (1e16 + 1.0) == 1e16 holds true.
%   Consequently, a default step size of 1.0 will result in zero change in the 
%   variable, causing the algorithm to incorrectly terminate due to "Small Step"
%   or "Small Gradient".
% -------------------------------------------------------------------------

% --- Problem Setup ---
% x_opt: The optimal solution.
% x(1) represents a "Macro" variable (e.g., stiffness in Pa, distance in m).
% x(2) represents a "Unit" variable.
problem = alpha_init_numerical_precision_problem();
x_opt = [1e16; 1];

% x0: Starting point with significant offsets.
% Offset for x(1) is 5e14.
% Offset for x(2) is 0.1.
x0 = problem.x0;

% Objective Function:
% We use the Euclidean norm to measure distance. 
fun = problem.fun;

% Problem dimensions
n = length(x0);

% --- CRITICAL ADJUSTMENT ---
% Convergence threshold (ftarget).
% Why 0.5?
% At the scale of 1e16, machine epsilon is approx 2.0. 
% The previous error was 5e14. Reducing it to < 0.5 is a 15-order-of-magnitude 
% improvement and represents the limit of what x(2) can achieve while 
% dominated by x(1)'s noise.
ftarget = 0.5; 
f0 = fun(x0);

fprintf('============================================================\n');
fprintf('TEST CASE: Machine Precision Limit (Scale ~ 1e16)\n');
fprintf('Objective: Compare Default Strategy vs. Smart Initialization\n');
fprintf('============================================================\n');

%% 1. Run Default Strategy
% The default initial step size is 1.0 for all blocks.
% This is expected to fail due to precision limits.
opts_def = struct();
opts_def.num_blocks = n;
opts_def.alpha_init = 1.0; % Default setting
opts_def.iprint = 1;       % Enable printing to observe exit flags

fprintf('\n--- [1] Running Default Strategy (alpha_init = 1.0) ---\n');
[x_def, f_def, exit_def, out_def] = bds(fun, x0, opts_def);

%% 2. Run Smart Initialization Strategy
% % Strategy: Scale the initial step size based on the magnitude of x0.

alpha_vec = zeros(n, 1);
step_tolerance = 1e-6 * ones(n, 1);

% Extract nonzero elements to compute the initial-point scale ratio.
abs_x0 = abs(x0);
nonzero_abs_x0 = abs_x0(abs_x0 > 0);
if isempty(nonzero_abs_x0)
    x0_scale_ratio = 1;
else
    x0_scale_ratio = max(nonzero_abs_x0) / min(nonzero_abs_x0);
end
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
opts_new.iprint = 1;
opts_new.alpha_init = alpha_vec; % Use the calculated smart alpha vector

fprintf('\n--- [2] Running Smart Init Strategy (Scaled Alpha) ---\n');
[x_new, f_new, exit_new, out_new] = bds(fun, x0, opts_new);

%% 3. Results Analysis & Visualization

fprintf('\n============================================================\n');
fprintf('                  COMPARATIVE RESULTS                       \n');
fprintf('============================================================\n');

% Calculate improvement ratio (avoid division by zero)
improvement_ratio = f_def / max(f_new, 1e-16);

% Formatted Output Table
fprintf('\n%-15s | %-10s | %-15s | %-s\n', 'Strategy', 'Func Evals', 'Final Error', 'Status');
fprintf('%s\n', repmat('-', 1, 90));

fprintf('%-15s | %-10d | %-15.4e | %s\n', ...
    'Default (1.0)', out_def.funcCount, f_def, out_def.message);

fprintf('%-15s | %-10d | %-15.4e | %s\n', ...
    'Smart Init', out_new.funcCount, f_new, out_new.message);

fprintf('%s\n', repmat('-', 1, 90));

% Verification of Initial Steps
fprintf('\n[Initialization Analysis]\n');
fprintf('  Default Alpha      : 1.0\n');
fprintf('  Smart Alpha        : [%.2e, %.2e]^T\n', alpha_vec(1), alpha_vec(2));
fprintf('  x0 scale ratio     : %.2e\n', x0_scale_ratio);
fprintf('  Smart Alpha (x1)   : %.2e (Logic: 1 + log10(|x0(1)|))\n', alpha_vec(1));
fprintf('  eps(x0(1))         : %.2e\n', eps(x0(1)));

% --- Final Conclusion Logic ---
% Success is defined as:
% 1. Meeting the target threshold OR
% 2. Achieving a massive relative improvement over the default strategy
is_success = (f_new <= ftarget) || (improvement_ratio > 1e6);

if is_success
    fprintf('\nCONCLUSION: SUCCESS. Smart Init correctly handled the scale.\n');
    fprintf('            Error reduced from %.1e to %.1e.\n', f_def, f_new);
else
    fprintf('\nCONCLUSION: FAILED. No significant improvement observed.\n');
end

%% 4. Thesis-Oriented Figure
% A single comparison plot is often clearer in a thesis: the two curves
% directly show the algorithmic consequence, while the annotation explains
% the numerical mechanism behind the gap.

default_alpha = opts_def.alpha_init(1);
smart_alpha = alpha_vec(1);
default_disp = abs((x0(1) + default_alpha) - x0(1));
smart_disp = abs((x0(1) + smart_alpha) - x0(1));

fhist_def_best = cummin(out_def.fhist(:));
fhist_new_best = cummin(out_new.fhist(:));
fhist_def_plot = max(fhist_def_best, realmin);
fhist_new_plot = max(fhist_new_best, realmin);
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
ylabel('$\min\{f_1,\ldots,f_m\}$', 'Interpreter', 'latex', 'FontSize', 16);
title('Initial-step scaling avoids numerical blindness', ...
    'FontSize', 15, 'FontWeight', 'bold');
legend([h_def, h_scaled], {'Default alpha = 1.0', 'Scaled alpha'}, ...
    'Location', 'northeast', 'FontSize', 14);

ax = gca;
ax.YScale = 'log';
ax.FontSize = 13;
ax.Position = [0.11, 0.16, 0.84, 0.76];
ax.Toolbar.Visible = 'off';

f_x0_latex = latex_sci(fun(x0), 1);
xopt1_latex = latex_sci(x_opt(1), 1);
x01_latex = latex_sci(x0(1), 2);
alpha_scaled_1_latex = latex_sci(alpha_vec(1), 2);
disp_scaled_latex = latex_sci(smart_disp, 2);

annotation_text = sprintf([ ...
    '$f(x)=\\|x-x_{\\mathrm{opt}}\\|_2$, \\quad $x_{\\mathrm{opt}}=[%s,\\,%g]^T$\n' ...
    '$x_0=[%s,\\,%g]^T$, \\quad $f(x_0)=%s$, \\quad $x_0(1)+1=x_0(1)$\n' ...
    '$f_m$: function value at the $m$-th function evaluation\n' ...
    '$\\alpha_{\\mathrm{default}}=(1,1)^T$, \\quad $|(x_0(1)+\\alpha_{\\mathrm{default}}(1))-x_0(1)|=0$\n' ...
    '$\\alpha_{\\mathrm{scaled}}=[%s,\\,%g]^T$, \\quad $|(x_0(1)+\\alpha_{\\mathrm{scaled}}(1))-x_0(1)|=%s$'], ...
    xopt1_latex, x_opt(2), x01_latex, x0(2), f_x0_latex, alpha_scaled_1_latex, alpha_vec(2), disp_scaled_latex);

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
exportgraphics(ax, fullfile(script_dir, 'test_alpha_init_numerical_precision.pdf'), ...
    'ContentType', 'vector', 'BackgroundColor', 'white');
exportgraphics(ax, fullfile(script_dir, 'test_alpha_init_numerical_precision.png'), ...
    'Resolution', 300, 'BackgroundColor', 'white');

fprintf('\n[Figure Export]\n');
fprintf('  PDF : %s\n', fullfile(script_dir, 'test_alpha_init_numerical_precision.pdf'));
fprintf('  PNG : %s\n', fullfile(script_dir, 'test_alpha_init_numerical_precision.png'));

function s = latex_sci(x, digits)
if x == 0
    s = '0';
    return;
end

exponent = floor(log10(abs(x)));
mantissa = x / 10^exponent;
s = sprintf(['%0.', num2str(digits), 'f\\times 10^{%d}'], mantissa, exponent);
end
