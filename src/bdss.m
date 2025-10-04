function [xopt, fopt, exitflag, output] = bdss(fun, x0, options)

% Set options to an empty structure if it is not provided.
if nargin < 3
    options = struct();
end

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

exitflag = 0;
output = struct();

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

    if MaxFunctionEvaluations <= 0
        break;
    end

    grad_hist = [grad_hist, output_bds.grad_hist];
    grad_xhist = [grad_xhist, xopt_bds];
    if iter > dim
        B = [grad_hist(:, end) grad_xhist(:, end) - grad_xhist(:, end-1)];
        MaxFunctionEvaluations_newuoa = min(MaxFunctionEvaluations, 500*dim);
        options_newuoa.maxfun = MaxFunctionEvaluations_newuoa;
        options_newuoa.output_xhist = true;

        [xopt_newuoa, fopt_newuoa, ~, output_newuoa] = newuoa(@(d) eval_fun(fun, xopt + B*d), zeros(dim, 1), options_newuoa);

        nf = nf + output_newuoa.funcCount;
        fhist((nf - output_newuoa.funcCount + 1):nf) = output_newuoa.fhist;
        xhist(:, (nf - output_newuoa.funcCount + 1):nf) = xopt + B * output_newuoa.xhist;
        MaxFunctionEvaluations = MaxFunctionEvaluations - nf;
        
        if fopt_newuoa < fopt
            xopt = xopt + B * xopt_newuoa; 
            fopt = fopt_newuoa;
            x0 = xopt;
        end
        if MaxFunctionEvaluations <= 0
           break;
        end
    end
end





