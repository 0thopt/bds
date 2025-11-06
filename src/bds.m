function [xopt, fopt, exitflag, output] = bds(fun, x0, options)
%BDS solves unconstrained optimization problems without using derivatives by
%blockwise direct search methods.
%
%   BDS supports in MATLAB R2017b or later.
%
%   XOPT = BDS(FUN, X0) returns an approximate minimizer XOPT of the function
%   FUN, starting the calculations at X0. FUN must accept a vector input X and
%   return a scalar.
%
%   XOPT = BDS(FUN, X0, OPTIONS) performs the computations with the options in
%   OPTIONS. OPTIONS should be a structure with the following fields.
%
%   Algorithm                   Algorithm to use. It can be 'cbds' (sorted
%                               blockwise direct search) 'pbds' (randomly
%                               permuted blockwise direct search), 'rbds'
%                               (randomized blockwise direct search), 'ds'
%                               (the classical direct search), 'pads' (parallel
%                               blockwise direct search). If no Algorithm is specified
%                               in the options, the default setting will be equivalent to
%                               using 'cbds' as the input.
%   block_visiting_pattern      block_visiting_pattern to use. It can be 'sorted' (The selected
%                               blocks will be visited in the order of their indices),
%                               'random' (The selected blocks will be visited in a random order),
%                               'parallel' (The selected blocks will be visited in parallel).
%                               Default: 'sorted'.
%   num_blocks                  Number of blocks. A positive integer. The number of blocks
%                               should be less than or equal to the dimension of the problem.
%                               Default: n.
%   MaxFunctionEvaluations      Maximum of function evaluations. A positive integer.
%   direction_set               A matrix whose columns will be used to define
%                               the polling directions. If options does not
%                               contain direction_set, then the polling
%                               directions will be {e_1, -e_1, ..., e_n, -e_n}.
%                               Otherwise, it should be a nonsingular n-by-n matrix.
%                               Then the polling directions will be
%                               {d_1, -d_1, ..., d_n, -d_n}, where d_i is the
%                               i-th column of direction_set. If direction_set
%                               is not singular, then we will revise the
%                               direction_set to make it linear independent.
%                               See get_direction_set.m for details. Default: eye(n).
%   grouped_direction_indices   A cell array of length num_blocks, where each
%                               cell contains a vector of indices corresponding
%                               to the directions assigned to that block. Each index
%                               should be in the range 1 to n, where n is the problem
%                               dimension. The i-th index refers to the i-th direction
%                               in direction_set.
%                               See divide_direction_set.m for details.
%   is_noisy                    A flag deciding whether the problem is noisy or
%                               not. The value of is_noisy will be only used to
%                               determine the values of expand and shrink now.
%                               Default: false.
%   expand                      Expanding factor of step size. A real number
%                               no less than 1. It depends on the dimension of
%                               the problem and whether the problem is noisy or
%                               not and the Algorithm. Default: 2.
%   shrink                      Shrinking factor of step size. A positive number
%                               less than 1. It depends on the dimension of the
%                               problem and whether the problem is noisy or not
%                               and the Algorithm. Default: 0.5.
%                               It should be strictly less than StepTolerance.
%                               A positive number. Default: 1e-3*StepTolerance.
%   forcing_function            The forcing function used for deciding whether
%                               the step achieves a sufficient decrease. forcing_function
%                               should be a function handle.
%                               Default: @(alpha) alpha^2. See also reduction_factor.
%   reduction_factor            Factors multiplied to the forcing function for
%                               deciding whether a step achieves a sufficient decrease.
%                               A 3-dimentional vector such that
%                               reduction_factor(1) <= reduction_factor(2) <= reduction_factor(3),
%                               reduction_factor(1) >= 0, and reduction_factor(2) > 0.
%                               After the "inner direct search" over each block, the base
%                               point is updated to the best trial point in the block if
%                               its reduction is more than reduction_factor(1) * forcing_function;
%                               the step size in this block is shrunk if the reduction is at most
%                               reduction_factor(2) * forcing_function, and it is
%                               expanded if the reduction is at least
%                               reduction_factor(3) * forcing_function.
%                               Default: [0, eps, eps]. See also forcing_function.
%   StepTolerance               Termination threshold for step size. The algorithm terminates
%                               when the step size for each block falls below their corresponding
%                               value. It can be a positive scalar (applied to all blocks) or a
%                               vector with length equal to the number of blocks.
%                               Default: 1e-6.
%   alpha_init                  Initial step size. If alpha_init is a positive
%                               scalar, then the initial step size of each block
%                               is set to alpha_init. If alpha_init is a vector,
%                               then the initial step size of the i-th block is
%                               set to alpha_init(i).
%                               Default: 1.
%   ftarget                     Target of the function value. If the function value
%                               is smaller than or equal to ftarget, then the
%                               algorithm terminates. ftarget should be a real number.
%                               Default: -Inf.
%   polling_inner               Polling strategy in each block. It can be "complete" or
%                               "opportunistic". Default: "opportunistic".
%   cycling_inner               Cycling strategy employed within each block. It
%                               is used only when polling_inner is "opportunistic".
%                               It can be 0, 1, 2, 3, 4. See cycling.m for details.
%                               Default: 3.
%   batch_size                  Suppose that batch_size is k. In each iteration,
%                               k blocks are randomly selected to visit. A positive
%                               integer less than or equal to num_blocks.
%                               Default: num_blocks.
%   seed                        The seed for random number generator. Default: "shuffle".
%   output_xhist                Whether to output the history of points visited.
%                               Default: false.
%   output_alpha_hist           Whether to output the history of step sizes.
%                               Default: false.
%   output_block_hist           Whether to output the history of blocks visited.
%                               Default: false.
%   iprint                      a flag deciding how much information will be printed during
%                               the computation. It can be 0, 1, 2, or 3.
%                               0: there will be no printing;
%                               1: a message will be printed to the screen at the return,
%                               showing the best vector of variables found and its
%                               objective function value;
%                               2: in addition to 1, each function evaluation with its
%                               variables will be printed to the screen. The step size
%                               for each block will also be printed.
%                               3: in addition to 2, prints whether BDS satisfies the sufficient
%                               decrease condition in each block, as well as the corresponding
%                               decrease value for that block.
%                               Default: 0.
%                               This option is cited from
%                               https://github.com/libprima/prima/blob/main/matlab/interfaces/newuoa.m.
%   debug_flag                  A flag deciding whether to check the inputs and outputs
%                               when the algorithm is running.
%                               Default: false.
%   use_function_value_stop     Whether to use the function value to stop the
%                               algorithm. If it is true, then the algorithm will
%                               stop when the function value does not change
%                               significantly over the last func_window_size iterations.
%                               It is an optional termination criterion.
%                               Default: false.
%   func_window_size            The number of iterations to consider when checking
%                               whether the function value has changed significantly.
%                               It should be a positive integer. Default: 10.
%   func_tol_1                  The first tolerance for the function value change.
%                               It should be a positive number. Default: 1e-6.
%   func_tol_2                  The second tolerance for the function value change.
%                               It should be a positive number. Default: 1e-9.
%   use_estimated_gradient_stop Whether to use the estimated gradient to stop
%                               the algorithm. If it is true and the algorithm
%                               is not terminated by other criteria, then the
%                               algorithm will stop when the estimated gradient
%                               is sufficiently small.
%                               It is an optional termination criterion.
%                               Default: false.
%   grad_window_size            The number of iterations to consider when checking
%                               whether the estimated gradient has changed significantly.
%                               It should be a positive integer. Default: 1.
%   grad_tol                    The tolerance for the estimated gradient.
%                               It should be a positive number. Default: 1e-3.
%
%   [XOPT, FOPT] = BDS(...) returns an approximate minimizer XOPT and its function value FOPT.
%
%   [XOPT, FOPT, EXITFLAG] = BDS(...) also returns an EXITFLAG that indicates the exit
%   condition. The possible values of EXITFLAG are 0, 1, 2, and 3.
%
%   0    The StepTolerance of the step size is reached.
%   1    The target of the objective function is reached.
%   2    The maximum number of function evaluations is reached.
%   3    The maximum number of iterations is reached.
%
%   [XOPT, FOPT, EXITFLAG, OUTPUT] = BDS(...) returns a
%   structure OUTPUT with the following fields.
%
%   fhist            History of function values.
%   grad_hist        History of estimated gradients.
%   xhist            History of points visited (if output_xhist is true).
%   alpha_hist       History of step size for every iteration (if output_alpha_hist is true).
%   blocks_hist      History of blocks visited (if output_block_hist is true).
%   funcCount        The number of function evaluations.
%   message          The information of EXITFLAG.
%
%   ***********************************************************************
%   Authors:    Haitian LI (hai-tian.li@connect.polyu.hk)
%               and Zaikun ZHANG (zhangzaikun@mail.sysu.edu.cn)
%               Department of Applied Mathematics,
%               The Hong Kong Polytechnic University
%               School of Mathematics,
%               Sun Yat-sen University
%   ***********************************************************************
%   All rights reserved.
%

% Set options to an empty structure if it is not provided.
if nargin < 3
    options = struct();
end

% Transpose x0 if it is a row.
x0_is_row = isrow(x0);
x0 = double(x0(:));

% Set the default value of options.
options = set_options(options, x0);

% Get the dimension of the problem.
n = length(x0);

% Check the inputs of the user when debug_flag is true.
if options.debug_flag
    verify_preconditions(fun, x0, options);
end

% If FUN is a string, then convert it to a function handle.
if ischarstr(fun)
    fun = str2func(fun);
end
% Redefine fun to accept columns if x0 is a row, as we use columns internally.
fun_orig = fun;
if x0_is_row
    fun = @(x)fun(x');
end

% Get the direction set.
D = get_direction_set(n, options);
positive_direction_set = D(:, 1:2:end);

block_visiting_pattern = options.block_visiting_pattern;
num_blocks = options.num_blocks;
batch_size = options.batch_size;
% Determine the indices of directions in each block.
grouped_direction_indices = divide_direction_set(n, num_blocks, options);
expand = options.expand;
shrink = options.shrink;

seed = options.seed;
random_stream = RandStream("mt19937ar", "Seed", seed);

reduction_factor = options.reduction_factor;
forcing_function = options.forcing_function;
polling_inner = options.polling_inner;
cycling_inner = options.cycling_inner;
replacement_delay = options.replacement_delay;

MaxFunctionEvaluations = options.MaxFunctionEvaluations;
% Set the maximum number of iterations.
% Each iteration will use at least one function evaluation. Setting maxit to MaxFunctionEvaluations will
% ensure that MaxFunctionEvaluations is exhausted before maxit is reached.
maxit = MaxFunctionEvaluations;

% Set the value of StepTolerance. The algorithm will terminate if the stepsize is less than
% the StepTolerance.
alpha_tol = options.StepTolerance;

ftarget = options.ftarget;

output_alpha_hist = options.output_alpha_hist;
alpha_all = options.alpha_init;
% Record the initial step size into the alpha_hist.
if  output_alpha_hist
    alpha_hist(:, 1) = alpha_all(:);
end

output_xhist = options.output_xhist;
if output_xhist
    xhist = NaN(n, MaxFunctionEvaluations);
end

% Initialize the history of function values.
fhist = NaN(1, MaxFunctionEvaluations);
% Establish the history of best function values for each iteration.
fopt_hist = [];

output_block_hist = options.output_block_hist;
% Initialize the history of blocks visited.
block_hist = NaN(1, MaxFunctionEvaluations);

use_function_value_stop = options.use_function_value_stop;
func_window_size = options.func_window_size;
func_tol_1 = options.func_tol_1;
func_tol_2 = options.func_tol_2;

use_estimated_gradient_stop = options.use_estimated_gradient_stop;
grad_window_size = options.grad_window_size;
grad_tol_1 = options.grad_tol_1;
grad_tol_2 = options.grad_tol_2;
norm_grad_hist = [];

gradient_estimation_complete = options.gradient_estimation_complete;

grad_hist = [];
grad_xhist = [];
grad_error_hist = [];


grad_info = struct();
grad_info.n = n;
grad_info.step_size_per_batch = NaN(batch_size, 1);
grad_info.fbase_per_batch = NaN(batch_size, 1);
grad_info.complete_direction_set = D;

% Initialize exitflag. If exitflag is not set elsewhere, then the maximum number of iterations
% is reached, and hence we initialize exitflag to the corresponding value.
exitflag = get_exitflag("MAXIT_REACHED");

% Initialize xbase and fbase. xbase serves as the "base point" for the computation in the next
% block, meaning that reduction will be calculated with respect to xbase. fbase is the function
% value at xbase.
xbase = x0;
% fbase_real is the real function value at xbase, which is the value returned by fun
% (not eval_fun).
[fbase, fbase_real] = eval_fun(fun, xbase);
% Initialize nf (the number of function evaluations), xhist (history of points visited), and
% fhist (history of function values).
nf = 1;
if output_xhist
    xhist(:, nf) = xbase;
end
% When we record fhist, we should use the real function value at xbase, which is fbase_real.
fhist(nf) = fbase_real;
iprint = options.iprint;
if iprint >= 2
    fprintf("The initial step size is:\n");
    print_aligned_vector(alpha_all);
    fprintf("Function number %d    F = %23.16E\n", nf, fbase_real);
    fprintf("The corresponding X is:\n");
    print_aligned_vector(xbase);
    fprintf("\n");
end
% Initialize xopt and fopt. xopt is the best point encountered so far, and fopt is the
% corresponding function value.
xopt = xbase;
fopt = fbase;
% Initialize
fopt_hist(1) = fopt;

terminate = false;
% If MaxFunctionEvaluations is reached at the very first function evaluation
% or FTARGET is reached at the very first function evaluation, no further computation
% should be entertained, and hence, no iteration should be run.
if fbase_real <= ftarget
    maxit = 0;
    exitflag = get_exitflag("FTARGET_REACHED");
elseif nf >= MaxFunctionEvaluations
    maxit = 0;
    exitflag = get_exitflag("MAXFUN_REACHED");
end

%Initialize the number of blocks visited.
num_visited_blocks = 0;

% fopt_all(i) stores the best function value found in the i-th block after one iteration,
% while xopt_all(:, i) holds the corresponding x. If a block is not visited during the iteration,
% fopt_all(i) is set to NaN. Both fopt_all and xopt_all have a length of num_blocks, not batch_size,
% as not all blocks might not be visited in each iteration, but the best function value across all
% blocks must still be recorded.
fopt_all = NaN(1, num_blocks);
xopt_all = NaN(n, num_blocks);

for iter = 1:maxit

    % Define block_indices, a vector that specifies both the indices of the blocks
    % and the order in which they will be visited during the current iteration.
    % The length of block_indices is equal to batch_size.
    % These blocks should not have been visited in the previous replacement_delay
    % iterations when the replacement_delay is nonnegative.
    unavailable_block_indices = unique(block_hist(max(1, (iter-replacement_delay) * batch_size) : (iter-1) * batch_size), 'stable');
    available_block_indices = setdiff(1:num_blocks, unavailable_block_indices);

    % Select batch_size blocks randomly from the available blocks. The selected blocks
    % will be visited in this iteration.
    block_indices = available_block_indices(random_stream.randperm(length(available_block_indices), batch_size));

    % Compute the direction selection probability matrix.
    direction_selection_probability_matrix = get_direction_selected_probability(n, batch_size, grouped_direction_indices, available_block_indices);
    grad_info.direction_selection_probability_matrix = direction_selection_probability_matrix;

    % Choose the block indices based on options.block_visiting_pattern.
    if strcmpi(block_visiting_pattern, "sorted")
        block_indices = sort(block_indices);
    end

    % Initialize sampled_direction_indices_per_batch as a cell array of length batch_size to store the indices
    % of directions evaluated in each batch during the current iteration.
    % Initialize function_values_per_batch as a cell array of length batch_size to store the function values
    % computed in each batch during the current iteration.
    % Initialize batch_gradient_eligible as a logical array of length batch_size, indicating whether
    % each block qualifies for gradient estimation based on specific criteria.
    sampled_direction_indices_per_batch = cell(1, batch_size);
    function_values_per_batch = cell(1, batch_size);
    % Determines eligibility for gradient estimation: a block qualifies when the following two conditions are met:
    % (1) sufficient decrease criterion is not met
    % (2) all directions in the block have been evaluated.
    % The second condition is essential because gradient estimation requires complete
    % directional information. Without it, we might incorrectly attempt gradient estimation
    % when function evaluation budget is 1 and this only function evaluation does not achieve
    % sufficient decrease. This situation is particularly critical when num_blocks = 1.
    batch_gradient_eligible = false(1, batch_size);

    for i = 1:length(block_indices)

        % i_real = block_indices(i) is the real index of the block to be visited. For example,
        % if block_indices is [1 3 2] and i = 2, then we are going to visit the 3rd block.
        i_real = block_indices(i);

        % Get indices of directions in the i_real-th block.
        direction_indices = grouped_direction_indices{i_real};

        % Store the step size for the i_real-th block in grad_info. We use i (the batch index)
        % instead of i_real (the absolute block index) because we are only concerned with the batch_size
        % blocks visited in the current iteration. Therefore, step_size_per_batch is initialized with
        % batch_size elements.
        grad_info.step_size_per_batch(i) = alpha_all(i_real);
        grad_info.fbase_per_batch(i) = fbase;

        % Set the options for the direct search within the i_real-th block.
        suboptions.FunctionEvaluations_exhausted = nf;
        suboptions.MaxFunctionEvaluations = MaxFunctionEvaluations - nf;
        suboptions.cycling_inner = cycling_inner;
        suboptions.reduction_factor = reduction_factor;
        suboptions.forcing_function = forcing_function;
        suboptions.ftarget = ftarget;
        suboptions.polling_inner = polling_inner;
        suboptions.i_real = i_real;
        suboptions.iprint = iprint;

        % Perform the direct search within the i_real-th block.
        [sub_xopt, sub_fopt, sub_exitflag, sub_output] = inner_direct_search(fun, xbase,...
            fbase, D(:, direction_indices), direction_indices,...
            alpha_all(i_real), suboptions);

        % Record the index of the block visited.
        num_visited_blocks = num_visited_blocks + 1;
        block_hist(num_visited_blocks) = i_real;

        % Record the points visited by inner_direct_search if output_xhist is true.
        if output_xhist
            xhist(:, (nf+1):(nf+sub_output.nf)) = sub_output.xhist;
        end

        % Record the function values calculated by inner_direct_search,
        fhist((nf+1):(nf+sub_output.nf)) = sub_output.fhist;

        % Update the number of function evaluations.
        nf = nf+sub_output.nf;

        % Store the indices of directions (with respect to the full direction set) that were evaluated
        % in the current batch during this iteration.
        % Note: We use sampled_direction_indices_per_batch{i} rather than sampled_direction_indices_per_batch{i_real} because:
        % 1. sampled_direction_indices_per_batch has length batch_size, tracking only directions visited in the current iteration.
        % 2. We're recording information by batch position (i) rather than absolute block index (i_real).
        % 3. This organization simplifies gradient estimation which only needs info about directions sampled in this iteration.
        sampled_direction_indices_per_batch{i} = direction_indices(1:sub_output.nf);

        % Store function values for the current batch.
        function_values_per_batch{i} = sub_output.fhist;

        % Record whether sufficient decrease was achieved in this batch.
        batch_gradient_eligible(i) = (sub_output.nf == length(direction_indices)) && ~sub_output.sufficient_decrease;

        % Record the best function value and point encountered in the i_real-th block.
        fopt_all(i_real) = sub_fopt;
        xopt_all(:, i_real) = sub_xopt;

        % Retrieve the direction indices of the i_real-th block, which represent the order of the
        % directions in the i_real-th block when we perform the direct search in this block next time.
        grouped_direction_indices{i_real} = sub_output.direction_indices;

        % Whether to update xbase and fbase. xbase serves as the "base point" for the computation in the next block,
        % meaning that reduction will be calculated with respect to xbase, as shown above.
        % Note that their update requires a sufficient decrease if reduction_factor(1) > 0.
        update_base = (reduction_factor(1) <= 0 && sub_fopt < fbase) ...
            || (sub_fopt + reduction_factor(1) * forcing_function(alpha_all(i_real)) < fbase);

        % Update the step size alpha_all according to the reduction achieved.
        if sub_fopt + reduction_factor(3) * forcing_function(alpha_all(i_real)) < fbase
            alpha_all(i_real) = expand * alpha_all(i_real);
        elseif sub_fopt + reduction_factor(2) * forcing_function(alpha_all(i_real)) >= fbase
            alpha_all(i_real) = shrink * alpha_all(i_real);
        end

        % If the block_visiting_pattern is not "parallel", then we will update xbase and fbase after finishing the
        % direct search in the i_real-th block. For "parallel", we will update xbase and fbase after
        % one iteration of the outer loop.
        if ~strcmpi(block_visiting_pattern, "parallel")
            if update_base
                xbase = sub_xopt;
                fbase = sub_fopt;
            end
        end

        % Terminate the computations if sub_output.terminate is true, which means that inner_direct_search
        % decides that the algorithm should be terminated for some reason indicated by sub_exitflag.
        if sub_output.terminate
            terminate = true;
            exitflag = sub_exitflag;
            break;
        end

        % Terminate the computations if the step size for each block falls below their corresponding thresholds.
        if all(alpha_all < alpha_tol)
            terminate = true;
            exitflag = get_exitflag("SMALL_ALPHA");
            break;
        end
    end

    % Record the step size for every iteration if output_alpha_hist is true.
    % Why iter+1? Because we record the step size for the next iteration.
    if output_alpha_hist
        alpha_hist = [alpha_hist, alpha_all(:)];
    end

    % Update xopt and fopt. Note that we do this only if the iteration encounters a strictly better point.
    % Make sure that fopt is always the minimum of fhist after the moment we update fopt.
    % The determination between fopt_all and fopt is to avoid the case that fopt_all is
    % bigger than fopt due to the update of xbase and fbase.
    % NOTE: If the function values are complex, the min function will return the value with the smallest
    % norm (magnitude).
    [~, index] = min(fopt_all, [], "omitnan");
    if fopt_all(index) < fopt
        fopt = fopt_all(index);
        xopt = xopt_all(:, index);
    end

    % Actually, fopt is not always the minimum of fhist after the moment we update fopt
    % since the value we used to iterate is not always equal to the value returned by the function.
    % See eval_fun.m for details.
    % assert(fopt == min(fhist));

    % For "parallel", we will update xbase and fbase only after one iteration of the outer loop.
    % During the inner loop, every block will share the same xbase and fbase.
    if strcmpi(block_visiting_pattern, "parallel")
        % Update xbase and fbase. xbase serves as the "base point" for the computation in the
        % next block, meaning that reduction will be calculated with respect to xbase, as shown above.
        % Note that their update requires a sufficient decrease if reduction_factor(1) > 0.
        if (reduction_factor(1) <= 0 && fopt < fbase) || fopt + reduction_factor(1) * forcing_function(min(alpha_all)) < fbase
            xbase = xopt;
            fbase = fopt;
        end
    end

    % Track the best function value observed among the latest func_window_size iterations.
    fopt_hist = [fopt_hist, fopt];
    % Why func_window_size + 1? Because the function value of the initial point has already been recorded
    % before the iterations start. fopt_hist should always contain the latest func_window_size function values
    % and the initial function value, which makes its length func_window_size + 1.
    if length(fopt_hist) > func_window_size + 1
        fopt_hist = fopt_hist(end - func_window_size : end);
    end

    % If the change is below a specified threshold, terminate the optimization. 
    % This check is performed after the current iteration is complete, ensuring fopt_hist includes the latest 
    % function value.
    if use_function_value_stop
        func_change = max(fopt_hist) - min(fopt_hist);
        if func_change < func_tol_1 * min(1, abs(fopt_hist(end))) || ...
                func_change < func_tol_2 * max(1, abs(fopt_hist(end)))
            terminate = true;
            exitflag = get_exitflag("SMALL_OBJECTIVE_CHANGE");
        end
    end

    % When sufficient decrease is not achieved in any batch, we estimate the gradient.
    if all(batch_gradient_eligible)
        grad_info.sampled_direction_indices_per_batch = sampled_direction_indices_per_batch;
        grad_info.function_values_per_batch = function_values_per_batch;
        grad = estimate_gradient(grad_info);
        % If the norm of the estimated gradient exceeds the threshold (1e30), it is discarded.
        % This threshold is chosen to maintain consistency with the standard used in eval_fun.m.
        % Additionally, we check for NaN values to ensure the gradient is valid. The first verification
        % can cover both cases. The second verification is to avoid the length of grad is too short.
        if (norm(grad) <= 1e30) && (norm(grad) > 10*sqrt(n)*eps)
            % Record the estimated gradient in grad_hist.
            grad_hist = [grad_hist, grad];
            % Record the corresponding xbase in grad_xhist. As long as all batches do not achieve
            % sufficient decrease, we record the estimated gradient. Thus, xbase should be recorded
            % not xopt even if xopt is better than xbase.
            grad_xhist = [grad_xhist, xbase];

            % When gradient_estimation_complete is true, we check whether the estimated gradient is
            % from the first iteration. If it is not, the solver will terminate. For now, we only
            % focus on the case where the setting is default, i.e., num_blocks = n and each
            % block contains only one subspace, which means that to get the estimated gradient in
            % the first iteration, we need exactly 2*n function evaluations in the first iteration
            % and one function evaluation for x0. That is why we check whether nf > 2*n + 1.
            if gradient_estimation_complete && (nf > (2 * n + 1))
                terminate = true;
                exitflag = get_exitflag("gradient_estimation_complete");
            end

            if use_estimated_gradient_stop
                % Note that we use grad_info.step_size_per_batch instead of alpha_all because the 
                % step size has already been updated in the current iteration. The error between 
                % the estimated gradient and the true gradient should be based on the step size used
                % in the finite difference calculation, which corresponds to the step size from the
                % previous iteration. This is why we rely on grad_info.step_size_per_batch.
                grad_error = get_gradient_error_bound(grad_info.step_size_per_batch, ...
                                                    batch_size, grouped_direction_indices, n, ...
                                                    positive_direction_set, direction_selection_probability_matrix);
                
                % Discard very large gradient errors to avoid unreliable stopping criteria.
                if grad_error < max(1e-3, 1e-1 * norm(grad))
                    norm_grad_hist = [norm_grad_hist, (norm(grad) + grad_error)];
                end

                if length(norm_grad_hist) > grad_window_size
                    reference_grad_norm = median(norm_grad_hist(1:grad_window_size));
                    if all(norm_grad_hist(end-grad_window_size+1:end) < grad_tol_1 * min(1, reference_grad_norm) ...
                        | norm_grad_hist(end-grad_window_size+1:end) < grad_tol_2 * max(1, reference_grad_norm))
                        terminate = true;
                        exitflag = get_exitflag("SMALL_ESTIMATE_GRADIENT");
                    end
                end

            end
        end
    end

    % Terminate the computations if terminate is true.
    if terminate
        break;
    end

end

% Record the number of function evaluations in output.
output.funcCount = nf;

% Truncate the histories of the blocks visited, the step sizes, the points visited,
% and the function values.
if output_block_hist
    output.blocks_hist = block_hist(1:num_visited_blocks);
end
if output_alpha_hist
    output.alpha_hist = alpha_hist(:, 1:min(iter, maxit));
end

if output_xhist
    output.xhist = xhist(:, 1:nf);
end
output.fhist = fhist(1:nf);
output.grad_hist = grad_hist;
output.grad_xhist = grad_xhist;
output.alpha_final = alpha_all;

% Set the message according to exitflag.
switch exitflag
    case get_exitflag("SMALL_ALPHA")
        output.message = "The StepTolerance of the step size is reached.";
    case get_exitflag("MAXFUN_REACHED")
        output.message = "The maximum number of function evaluations is reached.";
    case get_exitflag("FTARGET_REACHED")
        output.message = "The target of the objective function is reached.";
    case get_exitflag("MAXIT_REACHED")
        output.message = "The maximum number of iterations is reached.";
    case get_exitflag("SMALL_OBJECTIVE_CHANGE")
        output.message = "The change of the function value is small.";
    case get_exitflag("SMALL_ESTIMATE_GRADIENT")
        output.message = "The estimated gradient is small.";
    case get_exitflag("gradient_estimation_complete")
        output.message = "The algorithm is terminated by gradient estimation completion.";
    otherwise
        output.message = "Unknown exitflag";
end

% Transpose xopt if x0 is a row.
if x0_is_row
    xopt = xopt';
end

% verify_postconditions is to detect whether the output is valid when debug_flag is true.
if options.debug_flag
    verify_postconditions(fun_orig, xopt, fopt, exitflag, output);
end

if iprint > 0
    fprintf("\n");
    fprintf('%s\n', output.message);
    fprintf("Number of function values = %d    Least value of F is %23.16E\n", nf, fopt);
    fprintf("The corresponding X is:\n");
    print_aligned_vector(xopt);
end

end