function bds_forcing_slow_rates_experiment()
%BDS_FORCING_SLOW_RATES_EXPERIMENT Numerical experiments for bds_forcing_slow_rates.tex.
%
% This script runs two BDS examples from bds_forcing_slow_rates.tex.
%
% Example 1 uses a fixed strongly convex quadratic objective and a qualitative
% C^1 forcing function.  It compares opportunistic and complete polling.
%
% Example 2 uses the standard quadratic forcing rule on the radial polynomial
% objectives f_q(x) = ||x||^q/q.  It runs opportunistic BDS for several q values
% to show that the observed decay approaches the 1/k boundary as q increases.
%
% Important implementation detail:
% In src/bds.m, the accepted-base test uses
%
%     reduction_factor(1) * forcing_function(alpha).
%
% Therefore the examples pass reduction_factor = [1 1 1], so accepted base-point
% updates use the same sufficient-decrease threshold as the theoretical note.

fullpath = mfilename("fullpath");
path_examples = fileparts(fullpath);
path_bds = fileparts(path_examples);
path_src = fullfile(path_bds, "src");
addpath(path_src);
cleanup = onCleanup(@() rmpath(path_src));

qualitative_results = run_qualitative_forcing_example();
print_qualitative_results(qualitative_results);
qualitative_fig = plot_qualitative_forcing_example(qualitative_results);
export_figure(qualitative_fig, fullfile(path_examples, ...
    'bds_forcing_slow_rates_qualitative_forcing.pdf'));

quadratic_results = run_quadratic_forcing_example();
print_quadratic_results(quadratic_results);
quadratic_fig = plot_quadratic_forcing_example(quadratic_results);
export_figure(quadratic_fig, fullfile(path_examples, ...
    'bds_forcing_slow_rates_quadratic_forcing.pdf'));

end

function results = run_qualitative_forcing_example()
% Strongly convex quadratic with the qualitative forcing function.

% The theory asks for x0 = (s,s) with s small.  If s is chosen too small, the
% slow mechanism may look like numerical stagnation in double precision.
s = 1e-2;
x0 = [s; s];
fstar = 0;

base_options = struct();
base_options.Algorithm = 'cbds';
base_options.direction_set = eye(2);
base_options.forcing_function = @slow_forcing_rho;
base_options.reduction_factor = [1, 1, 1];
base_options.expand = 2;
base_options.shrink = 0.5;
base_options.alpha_init = [1; 1];
base_options.StepTolerance = 0;
base_options.ftarget = -inf;
base_options.MaxFunctionEvaluations = 20000;
base_options.output_alpha_hist = true;
base_options.output_xhist = true;
base_options.output_block_hist = true;
base_options.iprint = 0;
base_options.seed = 0;

polling_list = {'opportunistic', 'complete'};
results = struct();

for p = 1:numel(polling_list)
    options = base_options;
    options.polling_inner = polling_list{p};

    [xopt, fopt, exitflag, output] = bds(@slow_forcing_objective, x0, options);

    results(p).polling = polling_list{p};
    results(p).xopt = xopt;
    results(p).fopt = fopt;
    results(p).exitflag = exitflag;
    results(p).output = output;
    results(p).fbest = cummin(output.fhist) - fstar;
end
end

function results = run_quadratic_forcing_example()
% Quadratic forcing on f_q(x) = ||x||^q/q for increasing q.

q_list = [4, 8, 16, 32];
c = 1;
radius_power = 0.45;
alpha_scale = 0.5;

base_options = struct();
base_options.Algorithm = 'cbds';
base_options.direction_set = eye(2);
base_options.forcing_function = @(alpha) c * alpha.^2;
base_options.reduction_factor = [1, 1, 1];
base_options.polling_inner = 'opportunistic';
base_options.cycling_inner = 3;
base_options.expand = 2;
base_options.shrink = 0.5;
base_options.StepTolerance = 0;
base_options.ftarget = -inf;
base_options.MaxFunctionEvaluations = 100000;
base_options.output_alpha_hist = false;
base_options.output_xhist = false;
base_options.output_block_hist = false;
base_options.iprint = 0;
base_options.seed = 0;

results = struct();

for j = 1:numel(q_list)
    q = q_list(j);
    r0 = radius_power^(1 / (q - 2));
    x0 = r0 / sqrt(2) * [1; 1];
    options = base_options;
    options.alpha_init = initial_quadratic_forcing_alpha(r0, q, c, alpha_scale) * ones(2, 1);

    [xopt, fopt, exitflag, output] = bds( ...
        @(x) polynomial_radial_objective(x, q), x0, options);

    fbest = cummin(output.fhist);
    normalized_fbest = fbest / max(fbest(1), realmin);

    results(j).q = q;
    results(j).theoretical_exponent = q / (q - 2);
    results(j).initial_radius = r0;
    results(j).radius_power = radius_power;
    results(j).initial_alpha = options.alpha_init(1);
    results(j).xopt = xopt;
    results(j).fopt = fopt;
    results(j).exitflag = exitflag;
    results(j).output = output;
    results(j).fbest = fbest;
    results(j).normalized_fbest = normalized_fbest;
    results(j).fitted_exponent = -estimate_loglog_slope(normalized_fbest);
end
end

function alpha0 = initial_quadratic_forcing_alpha(r0, q, c, alpha_scale)
% Accepted steps for f_q and c*alpha^2 have natural scale r0^(q-1)/c.
alpha0 = alpha_scale * r0^(q - 1) / c;
end

function f = slow_forcing_objective(x)
% Objective from the qualitative-forcing counterexample.
x = x(:);
f = 0.5 * (x(1)^2 + x(2)^2 + x(1) * x(2));
end

function f = polynomial_radial_objective(x, q)
% Objective from the quadratic-forcing counterexamples.
x = x(:);
f = norm(x)^q / q;
end

function rho = slow_forcing_rho(alpha)
% C^1 forcing function rho on [0, infinity).
%
% rho(0) = 0,
% rho(alpha) = alpha / log(e / alpha), 0 < alpha <= 1,
% rho(alpha) = 2*alpha - 1, alpha > 1.

rho = zeros(size(alpha));

positive = alpha > 0;
small = positive & (alpha <= 1);
large = alpha > 1;

rho(small) = alpha(small) ./ log(exp(1) ./ alpha(small));
rho(large) = 2 * alpha(large) - 1;
end

function print_qualitative_results(results)
fprintf('\nExample 1: qualitative forcing on a strongly convex quadratic\n');
for p = 1:numel(results)
    fprintf('  %-13s: fopt = %.4e, funcCount = %d, exitflag = %d\n', ...
        results(p).polling, results(p).fopt, results(p).output.funcCount, ...
        results(p).exitflag);
end
print_fhist_difference(results);
end

function print_quadratic_results(results)
fprintf('\nExample 2: quadratic forcing on f_q(x) = ||x||^q/q\n');
for j = 1:numel(results)
    fprintf(['  q = %-2d: theory exponent = %.4f, fitted exponent = %.4f, ' ...
        'fopt = %.4e, funcCount = %d, exitflag = %d, alpha0 = %.4e\n'], ...
        results(j).q, results(j).theoretical_exponent, results(j).fitted_exponent, ...
        results(j).fopt, results(j).output.funcCount, results(j).exitflag, ...
        results(j).initial_alpha);
end
end

function fig = plot_qualitative_forcing_example(results)
fig = figure('Name', 'Qualitative forcing example', ...
    'Position', [100, 100, 760, 820]);
t = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
fig.UserData.ExportTarget = t;

nexttile;
plot_qualitative_objective_history(results);

nexttile;
plot_qualitative_forcing_function();
end

function plot_qualitative_objective_history(results)
colors = lines(numel(results));

for p = 1:numel(results)
    y = max(results(p).fbest, realmin);
    nfev = 0:(numel(y)-1);
    x_axis = nfev + 1;
    loglog(x_axis, y, 'LineWidth', 1.5, ...
        'Color', colors(p, :), ...
        'DisplayName', results(p).polling);
    hold on;
end

max_points = max(arrayfun(@(r) numel(r.fbest), results));
ref_nfev = 0:(max_points-1);
ref_x = ref_nfev + 1;
ref_y0 = max(results(1).fbest(1), realmin);
ref_log = ref_y0 ./ log(exp(1) + ref_nfev).^2;
ref_poly = ref_y0 ./ ref_x;

loglog(ref_x, ref_log, 'k--', 'LineWidth', 1.1, ...
    'DisplayName', '$1/\log^2 N$ reference');
loglog(ref_x, ref_poly, 'Color', [0.45, 0.45, 0.45], ...
    'LineStyle', ':', 'LineWidth', 1.1, ...
    'DisplayName', '$1/N$ reference');

set(gca, 'XScale', 'log', 'YScale', 'log');
grid on;
xlabel('$N+1$', 'Interpreter', 'latex');
ylabel('$\min_{0\le j\le N} f(y_j)$', 'Interpreter', 'latex');
title('Evaluated best-so-far objective history', 'Interpreter', 'latex');
legend('Location', 'southwest', 'Interpreter', 'latex');
hold off;
end

function plot_qualitative_forcing_function()
alpha = logspace(-8, 0, 1000);
rho = slow_forcing_rho(alpha);

loglog(alpha, rho, 'LineWidth', 1.6, ...
    'DisplayName', '$\rho(\alpha)$');
hold on;
loglog(alpha, alpha, 'Color', [0.45, 0.45, 0.45], ...
    'LineStyle', '--', 'LineWidth', 1.1, ...
    'DisplayName', '$\alpha$');
loglog(alpha, alpha.^2, 'Color', [0.25, 0.25, 0.25], ...
    'LineStyle', ':', 'LineWidth', 1.1, ...
    'DisplayName', '$\alpha^2$');

set(gca, 'XScale', 'log', 'YScale', 'log');
grid on;
xlabel('$\alpha$', 'Interpreter', 'latex');
ylabel('Value', 'Interpreter', 'latex');
title('Qualitative forcing function', 'Interpreter', 'latex');
legend('Location', 'northwest', 'Interpreter', 'latex');
hold off;
end

function fig = plot_quadratic_forcing_example(results)
fig = figure('Name', 'Quadratic forcing: compensated polynomial objective histories', ...
    'Position', [100, 100, 800, 540]);
t = tiledlayout(fig, 1, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
fig.UserData.ExportTarget = t;
nexttile;
colors = lines(numel(results));

for j = 1:numel(results)
    y = max(results(j).normalized_fbest, realmin);
    nfev = 0:(numel(y)-1);
    x_axis = nfev + 1;
    compensated_y = x_axis .* y;
    loglog(x_axis, compensated_y, 'LineWidth', 1.5, ...
        'Color', colors(j, :), ...
        'DisplayName', sprintf('$q=%d$', results(j).q));
    hold on;
end

max_points = max(arrayfun(@(r) numel(r.normalized_fbest), results));
ref_x = 1:max_points;
loglog(ref_x, ones(size(ref_x)), 'k--', 'LineWidth', 1.2, ...
    'DisplayName', '$1/N$ reference');

set(gca, 'XScale', 'log', 'YScale', 'log');
grid on;
xlabel('$N+1$', 'Interpreter', 'latex');
ylabel('$\frac{(N+1)\min_{0\le j\le N} f(y_j)}{f(x_0)}$', ...
    'Interpreter', 'latex');
title('Quadratic forcing on $f_q(x)=\|x\|^q/q$', 'Interpreter', 'latex');
legend('Location', 'southwest', 'Interpreter', 'latex');
hold off;
end

function slope = estimate_loglog_slope(y)
% Estimate the late-stage log-log slope of a positive history.
y = max(y(:), realmin);
x = (1:numel(y))';
first_index = max(2, floor(0.4 * numel(y)));
idx = first_index:numel(y);
p = polyfit(log(x(idx)), log(y(idx)), 1);
slope = p(1);
end

function print_fhist_difference(results)
% Print the first location where the two polling histories differ.

if numel(results) < 2
    return;
end

fhist_a = results(1).output.fhist;
fhist_b = results(2).output.fhist;
common_length = min(numel(fhist_a), numel(fhist_b));
idx = find(fhist_a(1:common_length) ~= fhist_b(1:common_length), 1, 'first');

fprintf('\nPolling-history comparison\n');
if isempty(idx)
    if numel(fhist_a) == numel(fhist_b)
        fprintf('  The two fhist arrays are exactly identical.\n');
    else
        fprintf('  The common fhist prefix is exactly identical.\n');
        fprintf('  Lengths differ: %s has %d values; %s has %d values.\n', ...
            results(1).polling, numel(fhist_a), ...
            results(2).polling, numel(fhist_b));
    end
else
    fprintf('  First different fhist index: %d\n', idx);
    fprintf('  %-13s fhist(idx) = %.16e\n', results(1).polling, fhist_a(idx));
    fprintf('  %-13s fhist(idx) = %.16e\n', results(2).polling, fhist_b(idx));
    fprintf('  Absolute difference       = %.16e\n', abs(fhist_a(idx) - fhist_b(idx)));
end
end

function export_figure(fig, filename)
% Export a figure to PDF, using exportgraphics when available.

set(fig, 'Color', 'w');

drawnow;
export_target = fig;
if isprop(fig, 'UserData') && isstruct(fig.UserData) && ...
        isfield(fig.UserData, 'ExportTarget')
    export_target = fig.UserData.ExportTarget;
end

if exist('exportgraphics', 'file') == 2
    exportgraphics(export_target, filename, ...
        'ContentType', 'vector', 'BackgroundColor', 'white');
else
    set(fig, 'PaperPositionMode', 'auto');
    fig_position = get(fig, 'Position');
    set(fig, 'PaperUnits', 'points');
    set(fig, 'PaperSize', fig_position(3:4));
    set(fig, 'PaperPosition', [0, 0, fig_position(3:4)]);
    print(fig, filename, '-dpdf', '-painters');
end

fprintf('Saved figure to %s\n', filename);
end
