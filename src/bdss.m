function [xopt, fopt, exitflag, output] = bdss(fun, x0, options)

n = length(x0);

grad_hist = [];
grad_xhist = [];

if isfield(options, 'options_bds')
    options_bds = options.options_bds;
else
    options_bds = struct();
end

maxit = 500 * length(x0);
MaxFunctionEvaluations = maxit;

dim = 2;

% Initialize the history of function values.
fhist = NaN(1, MaxFunctionEvaluations);
xhist = NaN(n, MaxFunctionEvaluations);

options_bds.subspace = true;
options_bds.output_xhist = true;

for iter = 1:maxit

    [xopt_bds, fopt_bds, ~, output_bds] = bds(fun, x0, options_bds);
    nf = output_bds.funcCount;
    fhist((nf - output_bds.funcCount + 1):nf) = output_bds.fhist;
    xhist(:, (nf - output_bds.funcCount + 1):nf) = output_bds.xhist;
    MaxFunctionEvaluations = MaxFunctionEvaluations - nf;

    x0 = xopt_bds;
    xopt = xopt_bds;
    fopt = fopt_bds;

    grad_hist = [grad_hist, output_bds.grad_hist];
    grad_xhist = [grad_xhist, xopt_bds];
    if iter > dim
        B = [grad_hist(:, end) grad_xhist(:, end) - grad_xhist(:, end-1)];
        MaxFunctionEvaluations_subspace = min(MaxFunctionEvaluations, 100*dim);
        options_subspace = optimset("MaxFunEvals", MaxFunctionEvaluations_subspace, ...
        "maxiter", 10^20, "tolfun", eps, "tolx", eps);
        keyboard
        [xopt_subspace, fopt_subspace, ~, output_subspace, xhist_subspace, fhist_subspace] = fminsearch_with_eval((@(d) eval_fun(fun, xopt + B*d)), zeros(dim, 1), options_subspace);

        nf = nf + output_subspace.funcCount;
        xhist(:, (nf - output_subspace.funcCount + 1):nf) = xopt + B * xhist_subspace;
        fhist((nf - output_subspace.funcCount + 1):nf) = fhist_subspace;
        keyboard
        if fopt_subspace < fopt
            xopt = xopt_subspace;
            fopt = fopt_subspace;
            x0 = xopt;
        end
    end
end





