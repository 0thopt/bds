function [xval, fval, exitflag, output] = lam(fun, x0, options)
%LAM Line-search derivative-free method used as the monotone baseline.

if nargin < 3
    options = struct();
end

x0 = double(x0(:));
n = length(x0);
num_blocks = n;

if ischarstr(fun)
    fun = str2func(fun);
end

D = get_direction_set(n, struct());
direction_set_indices = divide_direction_set(n, num_blocks, struct());
block_indices = 1:num_blocks;

if isfield(options, "MaxFunctionEvaluations")
    MaxFunctionEvaluations = options.MaxFunctionEvaluations;
else
    MaxFunctionEvaluations = 500*n;
end

if isfield(options, "reduction_factor")
    reduction_factor = options.reduction_factor;
else
    reduction_factor = 1e-6;
end

if isfield(options, "StepTolerance")
    alpha_tol = options.StepTolerance;
else
    alpha_tol = 1e-6;
end

if isfield(options, "expand")
    expand = options.expand;
else
    expand = 2;
end

if isfield(options, "shrink")
    shrink = options.shrink;
else
    shrink = 0.5;
end

if isfield(options, "stepsize_factor")
    stepsize_factor = options.stepsize_factor;
else
    stepsize_factor = 1e-8;
end

if isfield(options, "ftarget")
    ftarget = options.ftarget;
else
    ftarget = -inf;
end

if isfield(options, "alpha_init")
    alpha_all = options.alpha_init*ones(num_blocks, 1);
else
    alpha_all = 0.5*ones(num_blocks, 1);
end

fhist = NaN(1, MaxFunctionEvaluations);
xhist = NaN(n, MaxFunctionEvaluations);

xval = x0;
fval = eval_fun(fun, xval);
nf = 1;
fhist(nf) = fval;
xhist(:, nf) = xval;

terminate = false;
exitflag = NaN;
maxit = MaxFunctionEvaluations;
if fval <= ftarget
    terminate = true;
    exitflag = get_exitflag("FTARGET_REACHED");
    maxit = 0;
end

for iter = 1:maxit
    alpha_max = max(alpha_all);

    for i = 1:length(block_indices)
        i_real = block_indices(i);
        alpha_bar = max(alpha_all(i_real), stepsize_factor*alpha_max);
        direction_indices = direction_set_indices{i_real};

        suboptions.MaxFunctionEvaluations = MaxFunctionEvaluations - nf;
        suboptions.reduction_factor = reduction_factor;
        suboptions.expand = expand;
        suboptions.ftarget = ftarget;

        [xval, fval, sub_exitflag, suboutput] = lam_linesearch(fun, xval, ...
            fval, D(:, direction_indices), direction_indices, alpha_bar, suboptions);

        if suboutput.nf > 0
            fhist((nf+1):(nf+suboutput.nf)) = suboutput.fhist;
            xhist(:, (nf+1):(nf+suboutput.nf)) = suboutput.xhist;
        end
        nf = nf + suboutput.nf;

        if suboutput.terminate
            terminate = true;
            exitflag = sub_exitflag;
            break;
        end

        direction_set_indices{i_real} = suboutput.direction_indices;
        if suboutput.success
            alpha_all(i_real) = suboutput.stepsize;
        else
            alpha_all(i_real) = shrink*alpha_bar;
        end

        if max(alpha_all) < alpha_tol
            terminate = true;
            exitflag = get_exitflag("SMALL_ALPHA");
            break;
        end
    end

    if terminate
        break;
    end

    if iter == maxit
        exitflag = get_exitflag("MAXIT_REACHED");
    end
end

output.funcCount = nf;
output.fhist = fhist(1:nf);
output.xhist = xhist(:, 1:nf);
output.message = lam_exit_message(exitflag);

end

function message = lam_exit_message(exitflag)

if exitflag == get_exitflag("SMALL_ALPHA")
    message = "The StepTolerance of the step size is reached.";
elseif exitflag == get_exitflag("MAXFUN_REACHED")
    message = "The maximum number of function evaluations is reached.";
elseif exitflag == get_exitflag("FTARGET_REACHED")
    message = "The target of the objective function is reached.";
elseif exitflag == get_exitflag("MAXIT_REACHED")
    message = "The maximum number of iterations is reached.";
else
    message = "Unknown exitflag";
end

end
