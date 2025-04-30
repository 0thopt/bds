function [xopt, fopt, exitflag, output] = LS(fun, xbase, fbase, d, alpha, nf, options)

% Set the value of reduction_factor.
reduction_factor = options.reduction_factor;

% Set the value of expanding factor.
expand = options.expand;

% Set ftarget of objective function.
ftarget = options.ftarget;

% Adjust the maximum number of function evaluations for the inner LS loop.
MaxFunctionEvaluations = options.MaxFunctionEvaluations - nf;
% Reset the function evaluation counter for the inner LS loop.
nf = 0;

% If terminate is true and the exitflag is NaN, it means that the algorithm terminates
% not because of the maximum number of function evaluations or the target function value,
% which will be a bug.
exitflag = NaN;

xopt = xbase;
fopt = fbase;

% Initialize some parameters before entering the loop.
n = length(xbase);
fhist = NaN(1, MaxFunctionEvaluations);
xhist = NaN(n, MaxFunctionEvaluations);
sufficient_decrease = true;

while sufficient_decrease

    alpha_tmp = alpha * expand;
    xnew = xbase + alpha_tmp * d;
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

    sufficient_decrease = fnew + reduction_factor * ((expand-1) * alpha_tmp)^2 < fbase;
    % The following code is used to check if ((expand - 1) * alpha)^2 
    % is the same as the distance between the neighbour points.
    % if abs(((expand - 1) * alpha_tmp)^2 - norm(xnew - xbase)^2) > eps
    %     warning('The Algorithm is lht1 and the distance between the neighbour points is not equal to ((expand - 1) * alpha)^2');
    %     keyboard
    % end

    if sufficient_decrease
        fbase = fnew;
        xbase = xnew;
        alpha = alpha_tmp;
    else
        break;
    end
end

% Truncate FHIST and XHIST into an nf length vector.
output.fhist = fhist(1:nf);
output.xhist = xhist(:, 1:nf);
output.nf = nf;
output.alpha = alpha;
end




