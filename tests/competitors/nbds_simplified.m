function [xopt, fopt, exitflag, output] = nbds_simplified(fun, x0, options)
%NBDS_SIMPLIFIED Minimal nonmonotone BDS prototype for experiments.
%
% This solver intentionally stays close to bds_simplified.m.  The only
% algorithmic change is the reference value in the acceptance test:
%
%     f(xbase + alpha*d) + c*alpha^2 < C,
%
% where C is the Zhang-Hager average reference value.  A step that also
% satisfies the ordinary BDS test relative to fbase is treated as a strong
% success and expands the block step.  A step accepted only by the
% nonmonotone reference is a weak success and keeps the block step unchanged
% by default.

if nargin < 3
    options = struct();
end

x0 = x0(:);
n = length(x0);
maxfun = get_option(options, "maxfun", 500 * n);
maxit = maxfun;
alpha_tol = get_option(options, "alpha_tol", 1e-6);
alpha_all = get_option(options, "alpha_init", ones(1, n));
if isscalar(alpha_all)
    alpha_all = alpha_all * ones(1, n);
end
expand = get_option(options, "expand", 2);
shrink = get_option(options, "shrink", 0.5);
weak_factor = get_option(options, "weak_factor", 1);
forcing_coeff = get_option(options, "forcing_coeff", eps);
eta = get_option(options, "eta", 0.85);
slack_coeff = get_option(options, "slack_coeff", Inf);
best_slack_coeff = get_option(options, "best_slack_coeff", Inf);
weak_min_failures = get_option(options, "weak_min_failures", 0);
weak_accept_resets_failures = get_option(options, "weak_accept_resets_failures", false);
weak_accept_resets_reference = get_option(options, "weak_accept_resets_reference", false);
max_weak_per_cycle = get_option(options, "max_weak_per_cycle", Inf);
weak_min_stalled_cycles = get_option(options, "weak_min_stalled_cycles", 0);
weak_min_failed_block_fraction = get_option(options, "weak_min_failed_block_fraction", 0);
weak_min_failed_blocks_in_cycle = get_option(options, "weak_min_failed_blocks_in_cycle", 0);

if eta < 0 || eta >= 1
    error("options.eta must satisfy 0 <= eta < 1 for this prototype.");
end

D = zeros(n, 2 * n);
D(:, 1:2:2*n-1) = eye(n);
D(:, 2:2:2*n) = -eye(n);
grouped_direction_indices = arrayfun(@(i) [2*i-1, 2*i], 1:n, "UniformOutput", false);

fopt_all = nan(1, n);
xopt_all = nan(n, n);
exitflag = 0;
terminate = false;

f0 = fun(x0);
fhist = f0;
xhist = x0;
nf = 1;
xbase = x0;
fbase = f0;
xopt = x0;
fopt = f0;

C = f0;
Q = 1;
C_hist = C;
Q_hist = Q;
fbase_hist = fbase;
fbest_hist = fopt;
alpha_min_hist = min(alpha_all);
alpha_max_hist = max(alpha_all);
block_failure_count = zeros(1, n);

strong_success_count = 0;
weak_success_count = 0;
failure_count = 0;
cycle_failure_count = 0;

for iter = 1:maxit
    cycle_strong_success = false;
    cycle_weak_count = 0;
    cycle_failed_block_count = 0;
    failed_block_gate = max(weak_min_failed_blocks_in_cycle, ...
        ceil(weak_min_failed_block_fraction * n));
    for i = 1:n
        direction_indices = grouped_direction_indices{i};
        allow_weak = block_failure_count(i) >= weak_min_failures ...
            && cycle_failure_count >= weak_min_stalled_cycles ...
            && cycle_failed_block_count >= failed_block_gate ...
            && cycle_weak_count < max_weak_per_cycle;
        [sub_x, sub_f, sub_exitflag, sub_output] = inner_nonmonotone_search( ...
            fun, xbase, fbase, fopt, C, D(:, direction_indices), direction_indices, ...
            alpha_all(i), maxfun - nf, forcing_coeff, slack_coeff, ...
            best_slack_coeff, allow_weak);

        nf = nf + sub_output.nf;
        fhist = [fhist, sub_output.fhist]; %#ok<AGROW>
        xhist = [xhist, sub_output.xhist]; %#ok<AGROW>
        grouped_direction_indices{i} = sub_output.direction_indices;

        if sub_output.accepted
            xbase = sub_x;
            fbase = sub_f;
            reset_reference = false;
            if sub_output.strong_success
                alpha_all(i) = expand * alpha_all(i);
                strong_success_count = strong_success_count + 1;
                cycle_strong_success = true;
                block_failure_count(i) = 0;
            else
                alpha_all(i) = weak_factor * alpha_all(i);
                weak_success_count = weak_success_count + 1;
                cycle_weak_count = cycle_weak_count + 1;
                if weak_accept_resets_failures
                    block_failure_count(i) = 0;
                end
                reset_reference = weak_accept_resets_reference;
            end
        else
            alpha_all(i) = shrink * alpha_all(i);
            failure_count = failure_count + 1;
            cycle_failed_block_count = cycle_failed_block_count + 1;
            block_failure_count(i) = block_failure_count(i) + 1;
            reset_reference = false;
        end

        if sub_f < fopt_all(i) || isnan(fopt_all(i))
            fopt_all(i) = sub_f;
            xopt_all(:, i) = sub_x;
        end
        if fbase < fopt
            fopt = fbase;
            xopt = xbase;
        end
        [~, index] = min(fopt_all, [], "omitnan");
        if ~isempty(index) && fopt_all(index) < fopt
            fopt = fopt_all(index);
            xopt = xopt_all(:, index);
        end

        if reset_reference
            C = fbase;
            Q = 1;
        else
            [C, Q] = update_reference(C, Q, fbase, eta);
        end
        C_hist(end+1) = C; %#ok<AGROW>
        Q_hist(end+1) = Q; %#ok<AGROW>
        fbase_hist(end+1) = fbase; %#ok<AGROW>
        fbest_hist(end+1) = fopt; %#ok<AGROW>
        alpha_min_hist(end+1) = min(alpha_all); %#ok<AGROW>
        alpha_max_hist(end+1) = max(alpha_all); %#ok<AGROW>

        if sub_output.terminate
            terminate = true;
            exitflag = sub_exitflag;
            break;
        end
        if all(alpha_all < alpha_tol)
            terminate = true;
            exitflag = 3;
            break;
        end
        if nf >= maxfun
            terminate = true;
            exitflag = 1;
            break;
        end
    end
    if cycle_strong_success
        cycle_failure_count = 0;
    else
        cycle_failure_count = cycle_failure_count + 1;
    end
    if terminate
        break;
    end
end

output.funcCount = nf;
output.fhist = fhist;
output.xhist = xhist;
output.C_hist = C_hist;
output.Q_hist = Q_hist;
output.fbase_hist = fbase_hist;
output.fbest_hist = fbest_hist;
output.alpha_min_hist = alpha_min_hist;
output.alpha_max_hist = alpha_max_hist;
output.strong_success_count = strong_success_count;
output.weak_success_count = weak_success_count;
output.failure_count = failure_count;
output.eta = eta;
output.weak_factor = weak_factor;
output.forcing_coeff = forcing_coeff;
output.slack_coeff = slack_coeff;
output.best_slack_coeff = best_slack_coeff;
output.weak_min_failures = weak_min_failures;
output.weak_accept_resets_failures = weak_accept_resets_failures;
output.weak_accept_resets_reference = weak_accept_resets_reference;
output.max_weak_per_cycle = max_weak_per_cycle;
output.weak_min_stalled_cycles = weak_min_stalled_cycles;
output.weak_min_failed_block_fraction = weak_min_failed_block_fraction;
output.weak_min_failed_blocks_in_cycle = weak_min_failed_blocks_in_cycle;
output.block_failure_count = block_failure_count;
output.cycle_failure_count = cycle_failure_count;
output.iterations = iter;

end

function [xaccepted, faccepted, exitflag, output] = inner_nonmonotone_search( ...
    fun, xbase, fbase, fbest, C, D, direction_indices, alpha, submaxfun, ...
    forcing_coeff, slack_coeff, best_slack_coeff, allow_weak)

exitflag = nan;
terminate = false;
nf = 0;
fhist = [];
xhist = [];
xaccepted = xbase;
faccepted = fbase;
accepted = false;
strong_success = false;
fnew = fbase;

for j = 1:length(direction_indices)
    if nf >= submaxfun
        terminate = true;
        break;
    end

    xnew = xbase + alpha * D(:, j);
    fnew = fun(xnew);
    nf = nf + 1;
    fhist = [fhist, fnew]; %#ok<AGROW>
    xhist = [xhist, xnew]; %#ok<AGROW>

    strong_success = (fnew + forcing_coeff * alpha^2 < fbase);
    if allow_weak
        reference_value = min(C, fbase + slack_coeff * alpha^2);
        best_slack = best_slack_coeff * max(1, abs(fbest)) * alpha^2;
        reference_value = min(reference_value, fbest + best_slack);
    else
        reference_value = fbase;
    end
    accepted = (fnew + forcing_coeff * alpha^2 < reference_value);
    if accepted
        xaccepted = xnew;
        faccepted = fnew;
        direction_indices(1:j) = direction_indices([j, 1:j-1]);
        break;
    end
end

if nf >= submaxfun
    terminate = true;
    exitflag = 1;
end

output.nf = nf;
output.direction_indices = direction_indices;
output.terminate = terminate;
output.fhist = fhist;
output.xhist = xhist;
output.accepted = accepted;
output.strong_success = accepted && strong_success;
end

function [Cnew, Qnew] = update_reference(C, Q, fnew, eta)
Qnew = eta * Q + 1;
Cnew = (eta * Q * C + fnew) / Qnew;
end

function value = get_option(options, name, default_value)
if isfield(options, name)
    value = options.(name);
else
    value = default_value;
end
end
