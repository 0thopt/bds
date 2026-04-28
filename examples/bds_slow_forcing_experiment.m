function bds_slow_forcing_experiment()
%BDS_SLOW_FORCING_EXPERIMENT Numerical experiment for bds_slow_forcing.tex.
%
% This script runs BDS on the two-dimensional quadratic counterexample
%
%     f(x1,x2) = 0.5 * (x1^2 + x2^2 + x1*x2),
%
% with the C^1 general forcing function used in bds_slow_forcing.tex.
% It compares opportunistic polling, which is closer to the default efficient
% solver behavior, with complete polling.
%
% Important implementation detail:
% In src/bds.m, the accepted-base test uses
%
%     reduction_factor(1) * forcing_function(alpha).
%
% Therefore we pass forcing_function = rho and reduction_factor = [1 1 1],
% so that accepted base-point updates satisfy the same sufficient-decrease
% threshold as the theoretical note.

fullpath = mfilename("fullpath");
path_examples = fileparts(fullpath);
path_bds = fileparts(path_examples);
path_src = fullfile(path_bds, "src");
addpath(path_src);
cleanup = onCleanup(@() rmpath(path_src));

% Counterexample initialization.  The theory asks for x0 = (s,s) with s small.
% If s is chosen too small, the slow mechanism may look like numerical
% stagnation in double precision.  The value below is a practical compromise.
s = 1e-2;
x0 = [s; s];
fstar = 0;
save_step_size_plot = false;

base_options = struct();
base_options.Algorithm = 'cbds';
base_options.direction_set = eye(2);
base_options.forcing_function = @slow_forcing_rho;
base_options.reduction_factor = [1, 1, 1];
base_options.expand = 2;       % gamma >= 1. Use 1 for the gamma = 1 case.
base_options.shrink = 0.5;     % theta
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

fprintf('\nSlow-forcing BDS experiment\n');
for p = 1:numel(results)
    fprintf('  %-13s: fopt = %.4e, funcCount = %d, exitflag = %d\n', ...
        results(p).polling, results(p).fopt, results(p).output.funcCount, ...
        results(p).exitflag);
end
print_fhist_difference(results);

objective_fig = plot_objective_history(results);

export_figure(objective_fig, fullfile(path_examples, ...
    'bds_slow_forcing_objective_history.pdf'));

if save_step_size_plot
    step_fig = plot_step_size_history(results);
    export_figure(step_fig, fullfile(path_examples, ...
        'bds_slow_forcing_step_sizes.pdf'));
end

end

function f = slow_forcing_objective(x)
% Objective from bds_slow_forcing.tex.
x = x(:);
f = 0.5 * (x(1)^2 + x(2)^2 + x(1) * x(2));
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

function fig = plot_objective_history(results)
fig = figure('Name', 'Slow forcing: best objective history');

for p = 1:numel(results)
    y = max(results(p).fbest, realmin);
    nfev = 0:(numel(y)-1);
    loglog(nfev + 1, y, 'LineWidth', 1.5, ...
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
    'DisplayName', 'reference 1/log^2(k)');
loglog(ref_x, ref_poly, 'Color', [0.45, 0.45, 0.45], ...
    'LineStyle', ':', 'LineWidth', 1.1, ...
    'DisplayName', 'reference 1/k');

set(gca, 'XScale', 'log', 'YScale', 'log');
grid on;
xlabel('Number of function evaluations + 1');
ylabel('Best-so-far objective value');
title('Best objective value among evaluated points');
legend('Location', 'southwest');
hold off;
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

function fig = plot_step_size_history(results)
fig = figure('Name', 'Slow forcing: block step sizes');
tiledlayout(numel(results), 1);

for p = 1:numel(results)
    nexttile;
    alpha_hist = results(p).output.alpha_hist;
    cycle_index = 0:(size(alpha_hist, 2)-1);

    semilogy(cycle_index, alpha_hist(1, :), 'LineWidth', 1.5, ...
        'DisplayName', '\alpha^1');
    hold on;
    semilogy(cycle_index, alpha_hist(2, :), 'LineWidth', 1.5, ...
        'DisplayName', '\alpha^2');
    hold off;

    grid on;
    xlabel('Outer iterations / full coordinate cycles');
    ylabel('Block step size');
    title(sprintf('Step sizes, %s polling', results(p).polling));
    legend('Location', 'best');
end
end

function export_figure(fig, filename)
% Export a figure to PDF, using exportgraphics when available.

set(fig, 'Color', 'w');

if exist('exportgraphics', 'file') == 2
    exportgraphics(fig, filename, 'ContentType', 'vector');
else
    set(fig, 'PaperPositionMode', 'auto');
    print(fig, filename, '-dpdf', '-painters');
end

fprintf('Saved figure to %s\n', filename);
end
