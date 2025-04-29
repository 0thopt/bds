function [xval, fval, exitflag, output] = linesearch(fun, ...
    xval, fval, D, direction_indices, alpha, options)

% Set the value of reduction_factor.
if isscalar(options.reduction_factor)
    reduction_factor = options.reduction_factor;
elseif length(options.reduction_factor) == 3
    reduction_factor = options.reduction_factor(3);
else
    error("The length of reduction_factor should be 1 or 3.");
end

ls_list = ['fm', 'lht', 'lht1'];
lam_list = ['lam', 'lam1'];

% Set the value of cycling_strategy, which represents the cycling strategy inside each block.
cycling_strategy = get_default_constant('cycling_inner');

% Set the boolean value of WITH_CYCLING_MEMORY. 
with_cycling_memory = options.with_cycling_memory;

% Set ftarget of objective function.
ftarget = options.ftarget;

% Set the value of Algorithm.
Algorithm = options.Algorithm;

% Set the number of function evaluations allocated to this function.
MaxFunctionEvaluations = options.MaxFunctionEvaluations;

% Explain why NaN is good. It is possible that this function returns
% with exitflag=NaN and this is NOT a bug. This is because other situations
% are corresponding to other normal values. Easy to see whether there is
% some bug related to exitflag.
exitflag = NaN;

% Initialize some parameters before entering the loop.
n = length(xval);
num_directions = length(direction_indices);
fhist = NaN(1, MaxFunctionEvaluations);
xhist = NaN(n, MaxFunctionEvaluations);
success = false;
nf = 0; 
fbase = fval;
xbase = xval;

for j = 1 : num_directions

    % % Stop the loop if no more function evaluations can be performed. 
    % % Note that this should be checked before evaluating the objective function.
    % if nf >= MaxFunctionEvaluations
    %     exitflag = get_exitflag("MAXFUN_REACHED");
    %     break;
    % end

    % Evaluate the objective function for the current polling direction.
    xnew = xbase+alpha*D(:, j);
    [fnew, fnew_real] = eval_fun(fun, xnew);
    nf = nf+1;
    % When we record the function value, we use the real function value.
    % Here, we should use fnew_real instead of fnew.
    fhist(nf) = fnew_real;
    xhist(:, nf) = xnew;
    
    % Update the best point and the best function value.
    if fnew < fval
        xval = xnew;
        fval = fnew;
    end

    % Stop the computations once the target value of the objective function
    % is achieved.
    if fnew_real <= ftarget
        information = "FTARGET_REACHED";
        exitflag = get_exitflag(information);
        break;
    end

    % Stop the loop if no more function evaluations can be performed. 
    % Note that this should be checked before evaluating the objective function.
    if nf >= MaxFunctionEvaluations
        exitflag = get_exitflag("MAXFUN_REACHED");
        break;
    end

    % Check whether the sufficient decrease condition is achieved.
    sufficient_decrease = (fnew + reduction_factor * alpha^2 < fbase);
    success = sufficient_decrease;

    if sufficient_decrease    
        switch any(ismember(lower(Algorithm), ls_list))
            case true
                [xnew, fnew, exitflag, ls_output] = LS(fun, xnew, fnew, D(:, j), alpha, nf, options);
                % Record the points visited by LS.
                xhist(:, (nf+1):(nf+ls_output.nf)) = ls_output.xhist;
                % Record the function values calculated by inner_direct_search,
                fhist((nf+1):(nf+ls_output.nf)) = ls_output.fhist;
                % Update the number of function evaluations.
                nf = nf + ls_output.nf;
                alpha = ls_output.alpha;
                % Update the best point and the best function value.
                if fnew < fval
                    xval = xnew;
                    fval = fnew;
                end
                if nf >= MaxFunctionEvaluations || fval <= ftarget
                    break;
                end
            case false
                % If the algorithm is LAM or LAM1, we need to use another way to do linesearch.
                if strcmpi(Algorithm, "lht") || strcmpi(Algorithm, "lht1")
                    success = sufficient_decrease;
                end
        end
    end
     
    if success
        direction_indices = cycling(direction_indices, j, cycling_strategy, with_cycling_memory);
        break;
    end
end


% When the algorithm reaches here, it means that there are three cases.
% 1. The algorithm uses out of the allocated function evaluations.
% 2. The algorithm reaches the target function value.
% 3. The algorithm achieves a sufficient decrease when polling_inner is opportunistic.
% We need to check whether the algorithm terminates by the first two cases.
terminate = (nf >= MaxFunctionEvaluations || fval <= ftarget);
if fval <= ftarget
    exitflag = get_exitflag( "FTARGET_REACHED");
elseif nf >= MaxFunctionEvaluations
    exitflag = get_exitflag("MAXFUN_REACHED");
end
% Truncate FHIST and XHIST into an nf length vector.
output.fhist = fhist(1:nf);
output.xhist = xhist(:, 1:nf);
output.nf = nf;
% if options.iter == 9 && options.i_real == 3
%     keyboard
% end
output.success = success;
if ~success && (strcmpi(Algorithm, "lht") || strcmpi(Algorithm, "lht1"))
    output.direction_indices = direction_indices([2, 1]);
else
    output.direction_indices = direction_indices;
end
output.terminate = terminate;
output.stepsize = alpha;

end

