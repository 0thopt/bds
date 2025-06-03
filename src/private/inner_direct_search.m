function [xopt, fopt, exitflag, output] = inner_direct_search(fun, ...
    xbase, fbase, D, direction_indices, alpha, options)
%INNER_DIRECT_SEARCH performs a single iteration of classical direct search 
%   within a given block.
%
%   [xopt, fopt, EXITFLAG, OUTPUT] = INNER_DIRECT_SEARCH(FUN, xbase, fbase, D, ...
%   DIRECTION_INDICES, ALPHA, OPTIONS) returns a structure OUTPUT including
%   funcCount, fhist, xhist, success, terminate, and direction_indices, working with the 
%   structure OPTIONS, which includes reduction_factor, ftarget, polling, 
%   with_cycling_memory, cycling.
%
%   DIRECTION_INDICES is the indices of directions of the current block in D.
%

% Set the value of sufficient decrease factor.
reduction_factor = options.reduction_factor;

% Set target of objective function.
ftarget = options.ftarget;

% Set the value of polling_inner. This is the polling strategy employed within one block.
polling_inner = options.polling_inner;

% Set the value of cycling_inner, which represents the cycling strategy inside each block.
cycling_strategy = options.cycling_inner;

% Set the boolean value of WITH_CYCLING_MEMORY. 
with_cycling_memory = options.with_cycling_memory;

% Set the forcing function, which is a function handle.
forcing_function = options.forcing_function;

% The number of function evaluations allocated to this function.
MaxFunctionEvaluations = options.MaxFunctionEvaluations;

% The number of function evaluations having used in this function.
FunctionEvaluations_exhausted = options.FunctionEvaluations_exhausted;

% Index of the current block being processed.
i_real = options.i_real;

% The value of iprint.
iprint = options.iprint;

% If terminate is true and the exitflag is NaN, it means that the algorithm terminates
% not because of the maximum number of function evaluations or the target function value,
% which will be a bug.
exitflag = NaN;

% Initialize some parameters before entering the loop.
n = length(xbase);
num_directions = length(direction_indices);
fhist = NaN(1, num_directions);
xhist = NaN(n, num_directions);
nf = 0; 
fopt = fbase;
xopt = xbase;

for j = 1 : num_directions

    if nf >= MaxFunctionEvaluations
        % Set fnew to fbase and sufficient_decrease to false to avoid using an uninitialized
        % variable if the termination condition is reached before the first evaluation.
        fnew = fbase;
        sufficient_decrease = false;
        break;
    end
    
    % Evaluate the objective function for the current polling direction.
    xnew = xbase+alpha*D(:, j);
    % fnew_real is the real function value at xnew, which is the value returned by fun 
    % (not fnew).
    [fnew, fnew_real] = eval_fun(fun, xnew);
    nf = nf+1;
    % When we record the function value, we use the real function value.
    % Here, we should use fnew_real instead of fnew.
    fhist(nf) = fnew_real;
    xhist(:, nf) = xnew;
    if iprint >= 2
        fprintf("The %d-th block is currently being visited.\n", i_real);
        fprintf("The corresponding step size is:\n");
        fprintf("%23.16E ", alpha);
        fprintf("\n");
        fprintf("Function number %d    F = %23.16E\n", FunctionEvaluations_exhausted + nf, fnew_real);
        fprintf("The corresponding X is:\n");
        print_aligned_vector(xnew);
        fprintf("\n");
    end
    
    % Update the best point and the best function value.
    if fnew < fopt
        xopt = xnew;
        fopt = fnew;
    end
    
    % Check whether the sufficient decrease condition is achieved.
    sufficient_decrease = (fnew + reduction_factor(3) * forcing_function(alpha)/2 < fbase);

    % In the opportunistic case, if the current iteration achieves sufficient decrease,
    % stop the computations after cycling the indices of the polling directions. The reason  
    % that we cycle indices here is because inner_direct_search is called in a loop 
    % in outer_direct_search. 
    if sufficient_decrease && ~strcmpi(polling_inner, "complete")
        direction_indices = cycling(direction_indices, j, cycling_strategy, with_cycling_memory);
        break;
    end

    if nf >= MaxFunctionEvaluations || fnew <= ftarget
        break;
    end

end

% When the algorithm reaches here, it means that there are three cases.
% 1. The algorithm uses out of the allocated function evaluations.
% 2. The algorithm reaches the target function value.
% 3. The algorithm achieves a sufficient decrease when polling_inner is opportunistic.
% We need to check whether the algorithm terminates by the first two cases.
terminate = (nf >= MaxFunctionEvaluations || fnew <= ftarget);
if fnew <= ftarget
    exitflag = get_exitflag( "FTARGET_REACHED");
elseif nf >= MaxFunctionEvaluations
    exitflag = get_exitflag("MAXFUN_REACHED");
end

% Truncate FHIST and XHIST into a vector of length nf.
output.fhist = fhist(1:nf);
output.xhist = xhist(:, 1:nf);
output.nf = nf;
output.direction_indices = direction_indices;
output.terminate = terminate;
decrease_value = fopt - fbase;
if iprint == 3
    if sufficient_decrease
        fprintf("Sufficient decrease achieved in the %d-th block.\n", i_real);
    else
        fprintf("Sufficient decrease not achieved in the %d-th block.\n", i_real);
    end
    fprintf("The decrease value of the %d-th block is:%23.16E\n", i_real, decrease_value);
    fprintf("\n");
end
end
