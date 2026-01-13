function [xopt, fopt, exitflag, output] = inner_direct_search(fun, ...
    xbase, fbase, D, direction_indices, alpha, options)
%INNER_DIRECT_SEARCH performs a single iteration of classical direct search 
%   within a given block.
%
%   [xopt, fopt, EXITFLAG, OUTPUT] = INNER_DIRECT_SEARCH(FUN, xbase, fbase, D, ...
%   DIRECTION_INDICES, ALPHA, OPTIONS) returns a structure OUTPUT including
%   fhist, xhist, nf, direction_indices, terminate, and sufficient_decrease, working with the 
%   structure OPTIONS, which includes MaxFunctionEvaluations, ftarget, forcing_function, 
%   reduction_factor, polling_inner, cycling_inner, iprint, FunctionEvaluations_exhausted, and 
%   i_real.
%
%   direction_indices is the indices of directions of the current block in D.
%

MaxFunctionEvaluations = options.MaxFunctionEvaluations;
ftarget = options.ftarget;
forcing_function = options.forcing_function;
reduction_factor = options.reduction_factor;
polling_inner = options.polling_inner;
cycling_strategy = options.cycling_inner;
iprint = options.iprint;
FunctionEvaluations_exhausted = options.FunctionEvaluations_exhausted;
i_real = options.i_real;

% Initialize exitflag to NaN intentionally. This ensures that if the algorithm
% terminates in an unexpected or unhandled way, the NaN value will make it clear
% that no valid exit condition was met. Ideally, the algorithm should exit with
% a proper flag set by get_exitflag.m. If exitflag remains NaN, it indicates a
% potential bug or an unhandled termination case.
exitflag = NaN;

% Initialize some parameters before entering the loop.
n = length(xbase);
num_directions = length(direction_indices);
fhist = NaN(1, num_directions);
xhist = NaN(n, num_directions);
nf = 0; 
fopt = fbase;
xopt = xbase;
% Initialize sufficient_decrease to false in case it is not set within the loop.
% This ensures that if the algorithm terminates early (e.g., by reaching ftarget after the first 
% evaluation), sufficient_decrease remains well-defined and consistent with the algorithm's logic.
sufficient_decrease = false;

for j = 1 : num_directions

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

    % if nf >= MaxFunctionEvaluations
    %     % Set fnew to fbase and sufficient_decrease to false to avoid using an uninitialized
    %     % variable if the termination condition is reached before the first evaluation.
    %     fnew = fbase;
    %     sufficient_decrease = false;
    %     break;
    % end
    
    % Check whether ftarget or MaxFunctionEvaluations is reached immediately after every function 
    % evaluation. If one of them is reached at xnew, no further computation should be entertained 
    % in this inner direct search.
    if fnew <= ftarget || nf >= MaxFunctionEvaluations
        break;
    end

    % Check whether the sufficient decrease condition is achieved.
    sufficient_decrease = (fnew + reduction_factor(3) * forcing_function(alpha)/2 < fbase);

    % In the opportunistic case, if the current iteration achieves sufficient decrease,
    % stop the computations after cycling the indices of the polling directions. The reason  
    % that we cycle indices here is because inner_direct_search is called in a loop 
    % in outer_direct_search. 
    if sufficient_decrease && ~strcmpi(polling_inner, "complete")
        direction_indices = cycling(direction_indices, j, cycling_strategy);
        break;
    end

end


% When the algorithm reaches here, it means that one of the following cases has occurred:
% 1. The algorithm has reached the target function value (ftarget), which is the highest priority.
% 2. The algorithm has exhausted the allocated function evaluations (MaxFunctionEvaluations).
% 3. The algorithm has achieved a sufficient decrease when polling_inner is opportunistic.
%
% Among these, reaching ftarget is the most critical termination condition, so it is checked first.
% If neither of the first two conditions is met, the algorithm continues to evaluate the sufficient
% decrease condition or other criteria.
terminate = (fnew <= ftarget || nf >= MaxFunctionEvaluations);
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
output.sufficient_decrease = sufficient_decrease;
decrease_value = fopt - fbase;
if iprint >= 3
    if sufficient_decrease
        fprintf("Sufficient decrease achieved in the %d-th block.\n", i_real);
    else
        fprintf("Sufficient decrease not achieved in the %d-th block.\n", i_real);
    end
    fprintf("The decrease value of the %d-th block is:%23.16E\n", i_real, decrease_value);
    fprintf("\n");
end
end
