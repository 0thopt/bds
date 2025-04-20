function [xopt, fopt, exitflag, output] = LS(fun, xbase, fbase, d, alpha, nf, options)

% Set the value of reduction_factor.
if isscalar(options.reduction_factor)
    options.reduction_factor = options.reduction_factor * ones(1, 3);
end
reduction_factor = options.reduction_factor;

% Set the value of expanding factor.
expand = options.expand;

% Set ftarget of objective function.
ftarget = options.ftarget;

% Explain why NaN is good. It is possible that this function returns
% with exitflag=NaN and this is NOT a bug. This is because other situations
% are corresponding to other normal values. Easy to see whether there is
% some bug related to exitflag.
exitflag = NaN;

% Adjust the maximum number of function evaluations for the inner LS loop.
MaxFunctionEvaluations = options.MaxFunctionEvaluations - nf;
% Reset the function evaluation counter for the inner LS loop.
nf = 0;

xopt = xbase;
fopt = fbase;

% Initialize some parameters before entering the loop.
n = length(xbase);
fhist = NaN(1, MaxFunctionEvaluations);
xhist = NaN(n, MaxFunctionEvaluations);
sufficient_decrease = true;

while sufficient_decrease

    alpha = alpha * expand;
    xnew = xbase + alpha * d;
    fnew = eval_fun(fun, xnew);
    nf = nf + 1;
    fhist(nf) = fnew;
    xhist(:, nf) = xnew;

    % Stop the computations once the target value of the objective function
    % is achieved.
    if fnew <= ftarget
        xopt = xnew;
        fopt = fnew;
        information = "FTARGET_REACHED";
        exitflag = get_exitflag(information);
        break;
    end

    % Update the best point and the best function value.
    if fnew < fbase
        xopt = xnew;
        fopt = fnew;
    end

    % Stop the loop if no more function evaluations can be performed. 
    % Note that this should be checked before evaluating the objective function.
    if nf >= MaxFunctionEvaluations
        exitflag = get_exitflag("MAXFUN_REACHED");
        break;
    end

    sufficient_decrease = fnew + reduction_factor(3) * ((expand-1) * alpha)^2 < fbase;  

    if sufficient_decrease
        fbase = fnew;
        xbase = xnew;
    else
        % If the sufficient decrease condition is not satisfied, then
        % the alpha indicates to the last successful step size.
        alpha = alpha/expand;
    end
end

% Truncate FHIST and XHIST into an nf length vector.
output.fhist = fhist(1:nf);
output.xhist = xhist(:, 1:nf);
output.nf = nf;
output.alpha = alpha;
output.sufficient_decrease = sufficient_decrease;
end




