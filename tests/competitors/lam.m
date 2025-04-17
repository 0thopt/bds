function [xval, fval, exitflag, output] = lam(fun, x0, options)
%LAM (Linesearch Algorithm Model) solves unconstrained optimization problems without using derivatives. 
%

% Set options to an empty structure if it is not provided.
if nargin < 3
    options = struct();
end
% Transpose x0 if it is a row.
x0 = double(x0(:));
% Get the dimension of the problem.
n = length(x0);
num_blocks = n;
options.num_blocks = n;

% Set the default value of debug_flag. If options do not contain debug_flag, then
% debug_flag is set to false.
if isfield(options, "debug_flag")
    debug_flag = options.debug_flag;
else
    debug_flag = false;
end
if debug_flag
    verify_preconditions(fun, x0, options);
end

% If FUN is a string, then convert it to a function handle.
if ischarstr(fun)
    fun = str2func(fun);
end

% We set the initial flag to NaN. This value will be modified by procedures.
% If EXITFLAG is set to NaN on exit, it means that there is a bug.
exitflag = NaN;

% Get the direction set, the number of directions and blocks respectively.
%options.direction = "canonical";
D = get_direction_set(n, options);
% Decide which polling direction belongs to which block.
direction_set_indices = divide_direction_set(n, num_blocks);

% Set indices of blocks as 1:num_blocks.
block_indices = 1:num_blocks;

% Set MAXFUN to the maximum number of function evaluations.
if isfield(options, "MaxFunctionEvaluations")
    MaxFunctionEvaluations = options.MaxFunctionEvaluations;
else
    MaxFunctionEvaluations = get_default_constant("MaxFunctionEvaluations_dim_factor")*n;
end

% Each iteration will at least use one function evaluation. We will perform at most MaxFunctionEvaluations iterations.
% In theory, setting the maximum of function evaluations is not needed. But we do it to avoid infinite 
% cycling if there is a bug.
maxit = MaxFunctionEvaluations;
if isfield(options, "output_alpha_hist")
    output_alpha_hist = options.output_alpha_hist;
else
    output_alpha_hist = false;
end
alpha_hist = NaN(num_blocks, maxit);

if isfield(options, "output_block_hist")
    output_block_hist = options.output_block_hist;
else
    output_block_hist = false;
end
% Initialize the history of blocks visited.
block_hist = NaN(1, MaxFunctionEvaluations);
num_visited_blocks = 0;

% Set the reduction factor. We adopt the reduction factor in the paper Worst case complexity bounds for linesearch-type 
% derivative-free algorithms, 2024.
if isfield(options, "reduction_factor")
    reduction_factor = options.reduction_factor;
else
    reduction_factor = 1e-6;
end

% Set the value of StepTolerance. The algorithm will terminate if the stepsize is less than 
% the StepTolerance.
if isfield(options, "StepTolerance")
    alpha_tol = options.StepTolerance;
else
    alpha_tol = get_default_constant("StepTolerance");
end

% Set the value of expand factor. Since the expand factor in the paper A derivative-free algorithm for bound constrained optimization,
% G. Liuzzi, and S. Lucidi, Computational Optimization and Applications, 2002 is set to 2, we set the default value of expand to 2.
if isfield(options, "expand")
    expand = options.expand;
else
    expand = 2;
end
% % Test the case where expand = 1, which means that the step size is not expanded when linesearch is successful.
% expand = 1;

% Set the value of shrink factor. Since the shrink factor in the paper A derivative-free algorithm for bound constrained optimization,
% G. Liuzzi, and S. Lucidi, Computational Optimization and Applications, 2002 is set to 0.5, we set the default value of shrink to 0.5.
if isfield(options, "shrink")
    shrink = options.shrink;
else
    shrink = 0.5;
end

if isfield(options, 'Algorithm')
    % Set the algorithm type. The default value is 'lam'.
    Algorithm = options.Algorithm;
else
    Algorithm = 'lam1';
end

% Set the boolean value of WITH_CYCLING_MEMORY. 
if isfield(options, "with_cycling_memory")
    with_cycling_memory = options.with_cycling_memory;
else
    with_cycling_memory = get_default_constant("with_cycling_memory");
end

% Set the value of stepsize_factor. We adopt the step selection rule in A. Brilli, M. Kimiaei, G. Liuzzi, and S. Lucidi, Worst case
% complexity bounds for linesearch-type derivative-free algorithms, 2024. (corresponding to the parameter c)
if isfield(options, "stepsize_factor")
    stepsize_factor = options.stepsize_factor;
else
    stepsize_factor = 0;
    % stepsize_factor = 0;
end

% Set the type of linesearch.
if isfield(options, "linesearch_type")
    linesearch_type = options.linesearch_type;
else
    linesearch_type = "standard";
end

% Set the target of the objective function.
if isfield(options, "ftarget")
    ftarget = options.ftarget;
else
    ftarget = get_default_constant("ftarget");
end

% Initialize the step sizes. We adopt the step selection rule in G. Liuzzi, and S. Lucidi, A derivative-free
% algorithm for bound constrained optimization, Computational Optimization and Applications, 2002.
if isfield(options, "alpha_init")
    alpha_all = options.alpha_init*ones(num_blocks, 1);
else
    alpha_all = ones(num_blocks, 1);
end
alpha_hist(:, 1) = alpha_all(:);
success_all = false(num_blocks, 1);
LS_stepsize = ones(num_blocks, 1);

% Initialize the history of function values.
fhist = NaN(1, MaxFunctionEvaluations);

% Initialize the history of points visited.
if isfield(options, "output_xhist")
    output_xhist = options.output_xhist;
else
    output_xhist = false;
end
xhist = NaN(n, MaxFunctionEvaluations); 

xval = x0; 
[fval, fval_real] = eval_fun(fun, xval);
% Set the number of function evaluations.
nf = 1; 
fhist(nf) = fval_real;
xhist(:, nf) = xval;

% Check whether FTARGET is reached by FVAL. If it is true, then terminate.
if fval <= ftarget
    information = "FTARGET_REACHED";
    exitflag = get_exitflag(information);
    
    % FTARGET has been reached at the very first function evaluation. 
    % In this case, no further computation should be entertained, and hence, 
    % no iteration should be run.
    maxit = 0;
end

% Start the actual computations.
for iter = 1:maxit

    alpha_max = max(alpha_all);

    for i = 1:length(block_indices)

        i_real = block_indices(i);
        
        alpha_bar = max(alpha_all(i_real), stepsize_factor*alpha_max);

        % Get indices of directions in the i-th block.
        direction_indices = direction_set_indices{i_real}; 
        
        suboptions.MaxFunctionEvaluations = MaxFunctionEvaluations - nf;
        suboptions.reduction_factor = reduction_factor;
        suboptions.with_cycling_memory = with_cycling_memory;
        suboptions.expand = expand;
        suboptions.ftarget = ftarget;
        suboptions.linesearch_type = linesearch_type;
        suboptions.iter = iter;
        suboptions.i_real = i_real;

        % if iter == 2 && i_real == 2
        %     keyboard
        % end
        
        [xval, fval, sub_exitflag, suboutput] = linesearch(fun, xval,...
            fval, D(:, direction_indices), direction_indices,...
            alpha_bar, suboptions);
        
        % if iter == 2 && i_real == 2
        %     keyboard
        % end

        success_all(i_real) = suboutput.success;
        LS_stepsize(i_real) = suboutput.stepsize;
        
        % Store the history of the evaluations by inner_direct_search, 
        % and accumulate the number of function evaluations.
        fhist((nf+1):(nf+suboutput.nf)) = suboutput.fhist;
        xhist(:, (nf+1):(nf+suboutput.nf)) = suboutput.xhist;
        nf = nf+suboutput.nf;

        % Record the index of the block visited.
        num_visited_blocks = num_visited_blocks + 1;
        block_hist(num_visited_blocks) = i_real;
 
        % If suboutput.terminate is true, then inner_direct_search returns 
        % boolean value of terminate because either the maximum number of function
        % evaluations or the target of the objective function value is reached. 
        % In both cases, the exitflag is set by inner_direct_search.
        terminate = suboutput.terminate;
        if terminate
            exitflag = sub_exitflag;
            break;
        end
        
        % Retrieve the order of the polling directions and check whether a
        % sufficient decrease has been achieved in inner_direct_search.
        direction_set_indices{i_real} = suboutput.direction_indices;

        if strcmpi(Algorithm, 'lam1')
            if success_all(i_real)
                % If the linesearch is successful, then we will use the step size
                % returned by linesearch.
                alpha_all(i_real) = LS_stepsize(i_real);
            else
                % if alpha_bar ~= alpha_all(i_real) || alpha_bar ~= LS_stepsize(i_real)
                %     keyboard
                % end
                % If the linesearch is not successful, then we shrink the step size.
                alpha_all(i_real) = shrink * alpha_bar;
            end
        end
        % if iter == 1 && i_real == 2
        %     keyboard
        % end
        % Terminate the computations if the largest step size is below StepTolerance.
        if max(alpha_all) < alpha_tol
            terminate = true;
            exitflag = get_exitflag("SMALL_ALPHA");
            break;
        end
        
    end

    % if iter == 10
    %     keyboard
    % end

    % Check whether one of SMALL_ALPHA, MAXFUN_REACHED, and FTARGET_REACHED is reached.
    if terminate
        break;
    end


    % case 'lam1'
    %     alpha_all = success_all .* LS_stepsize + shrink * (~success_all) .* alpha_all;
    if strcmpi(Algorithm, 'lam')
        alpha_all = (any(success_all) * LS_stepsize) + (~any(success_all) * shrink .* alpha_all);
    end

    % Why iter+1? Because we record the step size for the next iteration.
    alpha_hist(:, iter+1) = alpha_all;

    % Terminate the computations if the largest component of step size is below a
    % given StepTolerance.
    if max(alpha_all) < alpha_tol
        exitflag = get_exitflag("SMALL_ALPHA");
        break;
    end
    
    % Check whether MAXIT is reached.
    if iter == maxit
        exitflag = get_exitflag("MAXIT_REACHED");
    end
    
end

% Truncate HISTORY into an nf length vector.
output.funcCount = nf;
output.fhist = fhist(1:nf);
if output_xhist
    output.xhist = xhist(:, 1:nf);
end
if output_alpha_hist
    output.alpha_hist = alpha_hist(:, 1:iter);
end
if output_block_hist
    output.blocks_hist = block_hist(1:num_visited_blocks);
end

switch exitflag
    case {get_exitflag("SMALL_ALPHA")}
        output.message = "The StepTolerance of the step size is reached.";
    case {get_exitflag("MAXFUN_REACHED")}
        output.message = "The maximum number of function evaluations is reached.";
    case {get_exitflag("FTARGET_REACHED")}
        output.message = "The target of the objective function is reached.";
    case {get_exitflag("MAXIT_REACHED")}
        output.message = "The maximum number of iterations is reached.";
    otherwise
        output.message = "Unknown exitflag";
end
