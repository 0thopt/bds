function [xval, fval, exitflag, output] = lam_linesearch(fun, ...
    xval, fval, D, direction_indices, alpha, options)

reduction_factor = options.reduction_factor;
expand = options.expand;
cycling_strategy = 1;
ftarget = options.ftarget;

exitflag = NaN;
n = length(xval);
num_directions = length(direction_indices);
fhist = NaN(1, options.MaxFunctionEvaluations);
xhist = NaN(n, options.MaxFunctionEvaluations);
success = false;
nf = 0;
fbase = fval;
xbase = xval;
terminate = false;

for j = 1:num_directions
    if nf >= options.MaxFunctionEvaluations
        terminate = true;
        exitflag = get_exitflag("MAXFUN_REACHED");
        break;
    end

    xnew = xbase + alpha*D(:, j);
    fnew = eval_fun(fun, xnew);
    nf = nf + 1;
    fhist(nf) = fnew;
    xhist(:, nf) = xnew;

    if fnew <= ftarget
        xval = xnew;
        fval = fnew;
        terminate = true;
        exitflag = get_exitflag("FTARGET_REACHED");
        break;
    end

    sufficient_decrease = (fnew + reduction_factor*alpha^2 < fbase);
    if sufficient_decrease
        fval = fnew;
        xval = xnew;
    end

    success = sufficient_decrease;

    while sufficient_decrease
        if nf >= options.MaxFunctionEvaluations
            terminate = true;
            exitflag = get_exitflag("MAXFUN_REACHED");
            break;
        end

        alpha = alpha*expand;
        xbase = xnew;
        fbase = fnew;
        xnew = xbase + alpha*D(:, j);
        fnew = eval_fun(fun, xnew);
        nf = nf + 1;
        fhist(nf) = fnew;
        xhist(:, nf) = xnew;

        if fnew <= ftarget
            xval = xnew;
            fval = fnew;
            terminate = true;
            exitflag = get_exitflag("FTARGET_REACHED");
            break;
        end

        sufficient_decrease = fnew + reduction_factor*((expand - 1)*alpha)^2 < fbase;

        if sufficient_decrease
            fval = fnew;
            xval = xnew;
        else
            alpha = alpha/expand;
        end
    end

    if terminate
        break;
    end

    if success
        direction_indices = cycling(direction_indices, j, cycling_strategy);
        break;
    end
end

output.fhist = fhist(1:nf);
output.xhist = xhist(:, 1:nf);
output.nf = nf;
output.success = success;
output.direction_indices = direction_indices;
output.terminate = terminate;
output.stepsize = alpha;

end
