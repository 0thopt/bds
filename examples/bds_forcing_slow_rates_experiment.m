function bds_forcing_slow_rates_experiment()
%BDS_FORCING_SLOW_RATES_EXPERIMENT Numerical experiment for bds_forcing_slow_rates.tex.
%
% This script runs the current construction from bds_forcing_slow_rates.tex
% with the BDS solver.  The objective is the fixed strongly convex quadratic
%
%     f(x1,x2) = 0.5*(x1^2 + x2^2 + x1*x2),
%
% and the forcing function is
%
%     rho(alpha) = alpha/log(e/alpha), 0 < alpha <= 1.
%
% We compare the classical direct-search setting, implemented by Algorithm='ds',
% with the cyclic blockwise direct-search setting, implemented by Algorithm='cbds'.
% The histories plotted below are best evaluated histories: bds.m records all
% evaluated trial points, not only the accepted base-point path used in the
% proof.
%
% Implementation detail:
% In src/bds.m, accepted base-point updates use
%
%     reduction_factor(1) * forcing_function(alpha).
%
% We set reduction_factor = [1 1 1], so accepted base-point updates use the
% same sufficient-decrease threshold as in the note.

fullpath = mfilename('fullpath');
path_examples = fileparts(fullpath);
path_bds = fileparts(path_examples);
path_src = fullfile(path_bds, 'src');
addpath(path_src);
cleanup = onCleanup(@() rmpath(path_src));

results = run_paper_construction_experiments();
print_results(results);

ds_fig = plot_single_objective_history(results(1));
export_figure(ds_fig, fullfile(path_examples, ...
    'bds_forcing_slow_rates_ds_objective.pdf'));

cbds_fig = plot_single_objective_history(results(2));
export_figure(cbds_fig, fullfile(path_examples, ...
    'bds_forcing_slow_rates_cbds_objective.pdf'));

forcing_fig = plot_forcing_function_figure();
export_figure(forcing_fig, fullfile(path_examples, ...
    'bds_forcing_slow_rates_forcing_function.pdf'));

end

function results = run_paper_construction_experiments()
% Run DS and CBDS on the construction in the paper.

% The theorem allows arbitrarily small s.  For a numerical demonstration, s
% should not be so small that accepted steps are below double precision.
s = 1e-1;
x0 = [s; s];

theta = 0.5;
gamma = 1;
alpha0 = 1e-1;
max_evals = 50000;

base_options = struct();
base_options.direction_set = eye(2);
base_options.forcing_function = @slow_forcing_rho;
base_options.reduction_factor = [1, 1, 1];
base_options.polling_inner = 'opportunistic';
base_options.cycling_inner = 3;
base_options.expand = gamma;
base_options.shrink = theta;
base_options.StepTolerance = 0;
base_options.ftarget = -inf;
base_options.MaxFunctionEvaluations = max_evals;
base_options.output_alpha_hist = true;
base_options.output_xhist = true;
base_options.output_block_hist = true;
base_options.iprint = 0;
base_options.seed = 0;

experiment_list = {
    'Direct Search (DS)', 'ds', alpha0;
    'Cyclic BDS (CBDS)', 'cbds', alpha0 * ones(2, 1)
    };

results = struct();
for j = 1:size(experiment_list, 1)
    options = base_options;
    options.Algorithm = experiment_list{j, 2};
    options.alpha_init = experiment_list{j, 3};

    [xopt, fopt, exitflag, output] = bds(@slow_forcing_objective, x0, options);

    diagnostic = evaluated_history_diagnostic(output);

    results(j).name = experiment_list{j, 1};
    results(j).algorithm = experiment_list{j, 2};
    results(j).x0 = x0;
    results(j).s = s;
    results(j).theta = theta;
    results(j).gamma = gamma;
    results(j).alpha0 = alpha0;
    results(j).xopt = xopt;
    results(j).fopt = fopt;
    results(j).exitflag = exitflag;
    results(j).output = output;
    results(j).diagnostic = diagnostic;
end

end

function diagnostic = evaluated_history_diagnostic(output)
% Compute best evaluated histories from bds output.

fhist = output.fhist(:).';
xhist = output.xhist;

[fbest, best_indices] = best_so_far_indices(fhist);
xbest = xhist(:, best_indices);

grad_best = quadratic_gradient(xbest);
grad_norm_best = sqrt(sum(grad_best.^2, 1));
radius_best = sum(abs(xbest), 1);

diagnostic.fhist = fhist;
diagnostic.fbest = fbest;
diagnostic.best_indices = best_indices;
diagnostic.xbest = xbest;
diagnostic.grad_norm_best = grad_norm_best;
diagnostic.radius_best = radius_best;
end

function [best_values, best_indices] = best_so_far_indices(values)
% Return cumulative minima and their first attaining indices.

values = values(:).';
best_values = zeros(size(values));
best_indices = zeros(size(values));

current_best = inf;
current_index = 1;
for j = 1:numel(values)
    if values(j) < current_best
        current_best = values(j);
        current_index = j;
    end
    best_values(j) = current_best;
    best_indices(j) = current_index;
end

end

function f = slow_forcing_objective(x)
% Objective from the qualitative-forcing construction.

x = x(:);
f = 0.5 * (x(1)^2 + x(2)^2 + x(1) * x(2));
end

function g = quadratic_gradient(x)
% Gradient of the quadratic objective.  Columns of x are points.

g = [x(1, :) + 0.5 * x(2, :);
     0.5 * x(1, :) + x(2, :)];
end

function rho = slow_forcing_rho(alpha)
% Forcing function rho on [0, infinity).
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

function print_results(results)
fprintf('\nQualitative forcing on the strongly convex quadratic\n');
for j = 1:numel(results)
    d = results(j).diagnostic;
    fprintf(['  %-22s: best f = %.4e, best ||grad f|| = %.4e, ' ...
        'best R = %.4e, funcCount = %d, exitflag = %d\n'], ...
        results(j).name, d.fbest(end), d.grad_norm_best(end), ...
        d.radius_best(end), results(j).output.funcCount, results(j).exitflag);
end
fprintf('\nThe plotted histories are best evaluated histories, not accepted-path histories.\n');
end

function fig = plot_single_objective_history(result)
fig = figure('Name', [result.name, ' objective history'], ...
    'Visible', 'off', 'Position', [100, 100, 430, 320]);

y = max(result.diagnostic.fbest, realmin);
x_axis = 1:numel(y);
loglog(x_axis, y, 'LineWidth', 1.6, ...
    'DisplayName', result.name);
hold on;

x_ref = x_axis;
y0 = max(result.diagnostic.fbest(1), realmin);
ref_log = y0 ./ log(exp(1) + x_ref - 1).^2;
ref_poly = y0 ./ x_ref;

loglog(x_ref, ref_log, 'k--', 'LineWidth', 1.1, ...
    'DisplayName', '$1/\log^2 N$ reference');
loglog(x_ref, ref_poly, 'Color', [0.45, 0.45, 0.45], ...
    'LineStyle', ':', 'LineWidth', 1.1, ...
    'DisplayName', '$1/N$ reference');

set(gca, 'XScale', 'log', 'YScale', 'log');
grid on;
xlabel('Number of evaluations', 'Interpreter', 'latex');
ylabel('Best evaluated $f$', 'Interpreter', 'latex');
legend('Location', 'southwest', 'Interpreter', 'latex');
hold off;
end

function fig = plot_forcing_function_figure()
fig = figure('Name', 'Qualitative forcing function', ...
    'Visible', 'off', 'Position', [100, 100, 430, 320]);

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
legend('Location', 'northwest', 'Interpreter', 'latex');
hold off;
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
