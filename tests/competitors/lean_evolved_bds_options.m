function [xopt, fopt, exitflag, output] = lean_evolved_bds_options(fun, x0, options)
%LEAN_EVOLVED_BDS_OPTIONS Experimental options-enabled Lean Evolved BDS.
%
% This file starts as an exact copy of lean_evolved_bds.m, with only the
% function name changed. It is intended for options/switch experiments while
% keeping lean_evolved_bds.m as the fixed reference implementation.
%
% The reference solver mirrors tests/competitors/evolved_bds_solver_lean.py
% in bds_python and keeps only:
%   - ordinary direction cycling within each coordinate block;
%   - explicit productive displacement memory;
%   - sweep-level pattern / momentum extrapolation.

if nargin < 3 || isempty(options)
    options = struct();
end

if should_use_bds_compatible_core(options)
    [xopt, fopt, exitflag, output] = run_bds_compatible_core(fun, x0, options);
    return;
end

x0 = x0(:);
n = numel(x0);
options = default_options(n, options);
MaxFunctionEvaluations = options.MaxFunctionEvaluations;
maxit = MaxFunctionEvaluations;
StepTolerance = options.StepTolerance;
alpha_all = options.alpha_init;
expand = options.expand;
shrink = options.shrink;
eps_m = eps;

D = zeros(n, 2 * n);
D(:, 1:2:end) = eye(n);
D(:, 2:2:end) = -eye(n);
grouped_direction_indices = cell(n, 1);
for k = 1:n
    grouped_direction_indices{k} = [2 * k - 1, 2 * k];
end

productive_direction_memory_size = options.productive_direction_memory_size;
prod_memory = struct('direction', {}, 'step', {});
momentum = zeros(n, 1);
momentum_decay = options.momentum_decay;

fopt_all = nan(n, 1);
xopt_all = nan(n, n);

f0 = evaluate_objective(fun, x0);
nf = 1;
xbase = x0;
fbase = f0;
xopt = x0;
fopt = f0;
exitflag = 0;
terminate = false;

for iter = 1:maxit
    xbase_sweep_start = xbase;
    fbase_sweep_start = fbase;
    sweep_improved = false;

    % Explicit productive displacement memory beyond cycling.
    if options.use_productive_direction_memory && ~isempty(prod_memory) && nf < MaxFunctionEvaluations
        avg_alpha = mean(alpha_all);
        for m_idx = 1:numel(prod_memory)
            if nf >= MaxFunctionEvaluations
                break;
            end
            dir_vec = prod_memory(m_idx).direction;
            stored_step = prod_memory(m_idx).step;
            step = max(avg_alpha, stored_step);
            x_cand = xbase + step * dir_vec;
            f_cand = evaluate_objective(fun, x_cand);
            nf = nf + 1;
            if f_cand < fbase
                xbase = x_cand;
                fbase = f_cand;
                sweep_improved = true;
                [xbase, fbase, nf] = try_extrapolation( ...
                    fun, xbase, fbase, dir_vec, step * 2.0, nf, MaxFunctionEvaluations);
                prod_memory(m_idx) = [];
                prod_memory = insert_memory_front(prod_memory, dir_vec, step);
                break;
            end
        end
    end

    % Baseline coordinate order.  Ordinary direction cycling is retained in
    % grouped_direction_indices exactly as in the Python solver.
    for i = 1:n
        if terminate || nf >= MaxFunctionEvaluations
            break;
        end
        direction_indices = grouped_direction_indices{i};
        [sub_xopt, sub_fopt, ~, sub_output] = inner_direct_search( ...
            fun, xbase, fbase, D, direction_indices, alpha_all(i), ...
            max(0, MaxFunctionEvaluations - nf));
        nf = nf + sub_output.nf;
        fopt_all(i) = sub_fopt;
        xopt_all(:, i) = sub_xopt;
        grouped_direction_indices{i} = sub_output.direction_indices;

        xold = xbase;
        is_expand = sub_fopt + eps_m * (alpha_all(i) ^ 2) < fbase;
        if is_expand
            alpha_all(i) = alpha_all(i) * expand;
        else
            alpha_all(i) = alpha_all(i) * shrink;
        end

        if sub_output.terminate
            terminate = true;
            break;
        end
        if sub_fopt < fbase
            xbase = sub_xopt;
            fbase = sub_fopt;
            displacement_i = sub_xopt - xold;
            disp_norm_i = norm(displacement_i);
            if options.use_productive_direction_memory && disp_norm_i > StepTolerance(i)
                prod_memory = remember_direction( ...
                    prod_memory, displacement_i, disp_norm_i, productive_direction_memory_size);
            end
        end
        if all(alpha_all < StepTolerance) || nf >= MaxFunctionEvaluations
            terminate = true;
            break;
        end
    end

    displacement = xbase - xbase_sweep_start;
    disp_norm = norm(displacement);
    if fbase < fbase_sweep_start
        sweep_improved = true;
    end

    % Sweep-level pattern / momentum extrapolation.
    if ~terminate && sweep_improved && disp_norm > max(StepTolerance) && nf < MaxFunctionEvaluations ...
            && (options.use_sweep_pattern_direction || options.use_momentum_extrapolation)
        pattern_dir = displacement / disp_norm;
        alpha_pat = max(disp_norm, max(StepTolerance));

        if options.use_momentum_extrapolation
            momentum = momentum_decay * momentum + (1.0 - momentum_decay) * pattern_dir;
            momentum_norm = norm(momentum);
            if momentum_norm > max(StepTolerance)
                momentum_dir = momentum / momentum_norm;
            else
                momentum_dir = [];
            end
        else
            momentum_dir = [];
        end

        factors = [1.0, 2.0, 4.0];
        x_pat = xbase;
        f_pat = fbase;
        best_dir = [];
        pat_improved = false;

        if options.use_sweep_pattern_direction
            for idx = 1:numel(factors)
                if nf >= MaxFunctionEvaluations
                    break;
                end
                factor = factors(idx);
                x_candidate = xbase + factor * alpha_pat * pattern_dir;
                f_candidate = evaluate_objective(fun, x_candidate);
                nf = nf + 1;
                if f_candidate < f_pat
                    x_pat = x_candidate;
                    f_pat = f_candidate;
                    best_dir = pattern_dir;
                    pat_improved = true;
                else
                    break;
                end
            end
        end

        if options.use_momentum_extrapolation && ~pat_improved && ~isempty(momentum_dir) ...
                && nf < MaxFunctionEvaluations
            for idx = 1:numel(factors)
                if nf >= MaxFunctionEvaluations
                    break;
                end
                factor = factors(idx);
                x_candidate = xbase + factor * alpha_pat * momentum_dir;
                f_candidate = evaluate_objective(fun, x_candidate);
                nf = nf + 1;
                if f_candidate < f_pat
                    x_pat = x_candidate;
                    f_pat = f_candidate;
                    best_dir = momentum_dir;
                else
                    break;
                end
            end
        end

        if f_pat < fbase
            xbase = x_pat;
            fbase = f_pat;
            if options.use_productive_direction_memory && ~isempty(best_dir)
                prod_memory = remember_direction( ...
                    prod_memory, best_dir, alpha_pat, productive_direction_memory_size);
            end
        end
    end

    [fopt, xopt] = best_recorded_point(fopt_all, xopt_all, fopt, xopt);
    if fbase < fopt
        fopt = fbase;
        xopt = xbase;
    end

    if nf >= MaxFunctionEvaluations || all(alpha_all < StepTolerance)
        terminate = true;
    end
    if terminate
        break;
    end
end

if nf >= MaxFunctionEvaluations
    exitflag = 1;
elseif all(alpha_all < StepTolerance)
    exitflag = 3;
end

output.funcCount = nf;
output.alpha_all = alpha_all;
output.fbase = fbase;
output.xbase = xbase;
output.iterations = iter;

end

function options = default_options(n, options)
defaults.MaxFunctionEvaluations = 200 * n;
defaults.StepTolerance = 1e-6;
defaults.alpha_init = ones(n, 1);
defaults.expand = 2.0;
defaults.shrink = 0.5;
defaults.productive_direction_memory_size = max(1, min(n, 5));
defaults.momentum_decay = 0.6;
defaults.use_productive_direction_memory = true;
defaults.use_sweep_pattern_direction = true;
defaults.use_momentum_extrapolation = true;

names = fieldnames(defaults);
for i = 1:numel(names)
    name = names{i};
    if ~isfield(options, name) || isempty(options.(name))
        options.(name) = defaults.(name);
    end
end

options.MaxFunctionEvaluations = max(1, floor(options.MaxFunctionEvaluations));
options.StepTolerance = normalize_step_tolerance(options.StepTolerance, n);
options.alpha_init = normalize_alpha_init(options.alpha_init, n);
options.productive_direction_memory_size = max(1, floor(options.productive_direction_memory_size));
end

function [xopt, fopt, exitflag, output] = inner_direct_search(fun, xbase, fbase, D, direction_indices, alpha, submaxfun)
exitflag = nan;
terminate = false;
nf = 0;
fopt = fbase;
xopt = xbase;
fnew = fopt;

for j = 1:numel(direction_indices)
    if nf >= submaxfun
        terminate = true;
        break;
    end
    di = direction_indices(j);
    xnew = xbase + alpha * D(:, di);
    fnew = evaluate_objective(fun, xnew);
    nf = nf + 1;
    if fnew < fopt
        xopt = xnew;
        fopt = fnew;
    end
    if fnew <= -inf || nf >= submaxfun
        terminate = true;
        break;
    end
    if fnew < fbase
        direction_indices(1:j) = direction_indices([j, 1:j-1]);
        break;
    end
end

if fnew <= -inf
    exitflag = 0;
elseif nf >= submaxfun
    exitflag = 1;
end

output.nf = nf;
output.direction_indices = direction_indices;
output.terminate = terminate;
end

function [xbest, fbest, nf] = try_extrapolation( ...
    fun, xbase, fbase, direction, step, nf, MaxFunctionEvaluations)
xbest = xbase;
fbest = fbase;
for k = 1:2
    if nf >= MaxFunctionEvaluations
        break;
    end
    xcand = xbest + step * direction;
    fcand = evaluate_objective(fun, xcand);
    nf = nf + 1;
    if fcand < fbest
        xbest = xcand;
        fbest = fcand;
        step = step * 2.0;
    else
        break;
    end
end
end

function f = evaluate_objective(fun, x)
% Use the BDS eval_fun algorithmic value while ignoring history-only metadata.
[f, ~, ~] = eval_fun(fun, x);
end

function StepTolerance = normalize_step_tolerance(StepTolerance, n)
if isscalar(StepTolerance)
    StepTolerance = StepTolerance * ones(n, 1);
else
    StepTolerance = StepTolerance(:);
end
if numel(StepTolerance) ~= n || any(StepTolerance < 0)
    error('lean_evolved_bds_options:InvalidStepTolerance', ...
        'options.StepTolerance must be a nonnegative scalar or an n-vector.');
end
end

function alpha_init = normalize_alpha_init(alpha_init, n)
if isscalar(alpha_init)
    alpha_init = alpha_init * ones(n, 1);
else
    alpha_init = alpha_init(:);
end
if numel(alpha_init) ~= n || any(alpha_init <= 0)
    error('lean_evolved_bds_options:InvalidAlphaInit', ...
        'options.alpha_init must be a positive scalar or an n-vector.');
end
end

function prod_memory = remember_direction(prod_memory, direction, step, mem_size)
direction = direction(:);
norm_direction = norm(direction);
if norm_direction == 0
    return;
end
direction = direction / norm_direction;

is_dup = false;
for k = 1:numel(prod_memory)
    if abs(prod_memory(k).direction' * direction) > 0.95
        is_dup = true;
        break;
    end
end
if is_dup
    return;
end

if numel(prod_memory) >= mem_size
    prod_memory(end) = [];
end
prod_memory = insert_memory_front(prod_memory, direction, step);
end

function prod_memory = insert_memory_front(prod_memory, direction, step)
entry.direction = direction(:);
entry.step = double(step);
if isempty(prod_memory)
    prod_memory = entry;
else
    prod_memory = [entry, prod_memory];
end
end

function [fopt, xopt] = best_recorded_point(fopt_all, xopt_all, fopt, xopt)
valid = ~isnan(fopt_all);
if any(valid)
    valid_indices = find(valid);
    [best_value, rel_idx] = min(fopt_all(valid));
    idx = valid_indices(rel_idx);
    if best_value < fopt
        fopt = best_value;
        xopt = xopt_all(:, idx);
    end
end
end

function tf = should_use_bds_compatible_core(options)
tf = false;

if isfield(options, 'mode')
    mode = options.mode;
    if isstring(mode)
        mode = char(mode);
    end
    tf = ischar(mode) && any(strcmpi(mode, {'bds-compatible', 'bds'}));
end

strategy_fields = {'use_productive_direction_memory', ...
    'use_sweep_pattern_direction', 'use_momentum_extrapolation'};
if ~tf && all(isfield(options, strategy_fields))
    tf = is_false_scalar(options.use_productive_direction_memory) ...
        && is_false_scalar(options.use_sweep_pattern_direction) ...
        && is_false_scalar(options.use_momentum_extrapolation);
end
end

function tf = is_false_scalar(value)
tf = (islogical(value) || isnumeric(value)) && isscalar(value) && ~logical(value);
end

function [xopt, fopt, exitflag, output] = run_bds_compatible_core(fun, x0, options)
ensure_bds_on_path();
bds_options = strip_lean_options_for_bds(options);
[xopt, fopt, exitflag, output] = bds(fun, x0, bds_options);
end

function ensure_bds_on_path()
if exist('bds', 'file') == 2
    return;
end

competitors_dir = fileparts(mfilename('fullpath'));
tests_dir = fileparts(competitors_dir);
repo_dir = fileparts(tests_dir);
src_dir = fullfile(repo_dir, 'src');
if exist(fullfile(src_dir, 'bds.m'), 'file') == 2
    addpath(src_dir);
end
end

function bds_options = strip_lean_options_for_bds(options)
bds_options = options;

lean_only_fields = {'mode', 'productive_direction_memory_size', ...
    'momentum_decay', 'use_productive_direction_memory', ...
    'use_sweep_pattern_direction', 'use_momentum_extrapolation'};
present = intersect(fieldnames(bds_options), lean_only_fields);
if ~isempty(present)
    bds_options = rmfield(bds_options, present);
end
end
