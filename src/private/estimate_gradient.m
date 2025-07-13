function [gradient, is_gradient_returned, ...
          directional_derivative_history, ...
          is_directional_derivative_sampled_history, ...
          last_sampled_iteration_per_direction] = ...
    estimate_gradient(grad_info, ...
                      directional_derivative_history, ...
                      is_directional_derivative_sampled_history, ...
                      last_sampled_iteration_per_direction)
% estimate_gradient estimates the gradient using finite difference methods.
% The gradient is computed under the following cases:
% 1. If the number of blocks equals the batch size, the gradient is computed only if all directions have been sampled.
%    - For "central_difference_mode", the gradient is returned only if no block has achieved sufficient decrease.
%    - For "mixed_difference_mode", the gradient is always returned as long as all directions are sampled.
% 2. If the number of blocks does not equal the batch size, the gradient is computed whenever each direction has 
% at least one sampled directional derivative.
% Inputs:
%   grad_info: A structure containing the following fields:
%       - n: Number of variables.
%       - num_blocks: Number of blocks.
%       - iter: Current iteration number.
%       - sufficient_decrease_each_block: Boolean array indicating if sufficient decrease was achieved in each block.
%       - direction_set: Matrix containing only the positive directions (i.e., the odd columns of the full direction set in bds.m).
%                        This matrix is of size n x n, where each column corresponds to a basis direction d_i (i=1,...,n).
%                        Note: direction_set here has already been extracted as the odd columns (1:2:2*n-1) outside this function.
%       - fhist_each_block: Cell array of length num_blocks, where each cell contains an array of function values (fhist) for
%                           the corresponding block.
%       - fbase_each_block: Base function values for each block, recorded at the start of each block.
%       - step_size_each_block: Step size used for each block, recorded before updating step sizes.
%       - direction_set_indices_current_iteration: Cell array containing indices of sampled directions for the current iteration.
%       - finite_difference_mode: Mode of finite difference estimation ("central_difference_mode" or "mixed_difference_mode").
%   directional_derivative_history: An n-by-history_length matrix, where each row corresponds to a direction and each column to 
%       an iteration. Each entry stores the directional derivative for a given direction at a specific iteration.
%       The number of columns (history_length) is preset to the maximum number of iterations, since MATLAB matrices require 
%       fixed size at initialization. If not provided, elements are initialized to NaN.
%   is_directional_derivative_sampled_history: An n-by-history_length logical matrix, where each row corresponds to a direction and each 
%       column to an iteration. Each entry indicates whether the directional derivative for a given direction was sampled at a 
%       specific iteration. The number of columns is also preset to the maximum number of iterations.
%   last_sampled_iteration_per_direction: A vector of length n, where each entry corresponds to a direction and stores the last
%       iteration when the directional derivative for that direction was sampled. This is used to track the last sampled iteration 
%       for each direction, which can be used to estimate the gradient when batch size is less than the number of blocks.
% Outputs:
%   - gradient: Estimated gradient vector. If the gradient cannot be estimated, it will be NaN.
%   - is_gradient_returned: Boolean indicating if the gradient was successfully estimated. If the gradient is estimated, 
%                           it will be true; otherwise, it will be false.
%   - directional_derivative_history: See the detailed explanation above.
%   - is_directional_derivative_sampled_history: See the detailed explanation above.
%   - last_sampled_iteration_per_direction: See the detailed explanation above.
 
% is_sampled_direction is a logical array indicating whether each direction has been sampled. If a direction has been sampled,
% it will be true; otherwise, it will be false.
is_sampled_direction = false(grad_info.n, 1);
% directional_derivative is a vector to store the computed directional derivatives of each direction.
% It will be used to compute the gradient if necessary.
directional_derivative = zeros(grad_info.n, 1);
% is_gradient_returned is a boolean flag indicating whether the gradient has been successfully estimated.
% If the condition for estimating the gradient is met, it will be set to true; otherwise, it will remain false.
is_gradient_returned = false;
% Initialize the gradient to NaN. If the gradient is not estimated, it will remain NaN.
gradient = NaN;
% Initialize the updated vector for the last sampled iteration of each direction.
last_sampled_iteration_per_direction_update = zeros(grad_info.n, 1);

for i = 1:grad_info.n

    % Check if the i-th direction has been sampled in any block. To be specific, we will check if the 2*i-1-th and 2*i-th
    % directions have been sampled in any block. The 2*i-1-th direction corresponds to the positive direction, and the 2*i-th 
    % direction corresponds to the negative direction.
    [is_sampled_direction(i), block_index, direction_position, is_sampled_positive_negative_direction] = is_direction_sampled(i, grad_info.num_blocks, grad_info.fhist_each_block, grad_info.direction_set_indices_current_iteration);

    % Record whether the i-th direction has been sampled at the current iteration.
    is_directional_derivative_sampled_history(i, grad_info.iter) = is_sampled_direction(i);

    % Find the last true index in the logical vector.
    last_sampled_iteration_per_direction_update(i) = max([0 find(is_directional_derivative_sampled_history(i, 1:grad_info.iter))]);

    % If the direction is sampled, compute the directional derivative.
    if is_sampled_direction(i)
        % is_sampled_positive_negative_direction is a boolean array of size 2 indicating whether the positive and negative 
        % directions have been sampled. If both are sampled, we will use the central difference to compute the directional derivative.
        % If only one direction is sampled, we will use the forward or backward difference accordingly.
        if any(is_sampled_positive_negative_direction)
            if all(is_sampled_positive_negative_direction)
                % Both positive and negative directions are sampled. Use central difference to compute the directional derivative.
                directional_derivative(i) = (grad_info.fhist_each_block{block_index}(direction_position(1)) - grad_info.fhist_each_block{block_index}(direction_position(2))) / (2 * grad_info.step_size_each_block(block_index));
            else
                % Only one of the positive or negative directions is sampled. If the positive direction is sampled, we use forward 
                % difference. If the negative direction is sampled, we use backward difference.
                if is_sampled_positive_negative_direction(1)
                    directional_derivative(i) = (grad_info.fhist_each_block{block_index}(direction_position(1)) - grad_info.fbase_each_block(block_index)) / grad_info.step_size_each_block(block_index);
                else
                    directional_derivative(i) = (grad_info.fbase_each_block(block_index) - grad_info.fhist_each_block{block_index}(direction_position(2))) / grad_info.step_size_each_block(block_index);
                end
            end
        end
        % Record the computed directional derivative of the i-th direction at the current iteration.
        directional_derivative_history(i, grad_info.iter) = directional_derivative(i);
    end
end

if grad_info.num_blocks == grad_info.batch_size
    % When the number of blocks is equal to the batch size, we will only compute the gradient if all directions have been sampled.
    % Check if all directions have been sampled. If there are some directions that have not been sampled, 
    % we will not compute the gradient.
    if all(is_sampled_direction)
        % If the finite difference mode is "central_difference_mode", we will only return the gradient if there 
        % are no blocks reaching sufficient decrease.
        if strcmpi(grad_info.finite_difference_mode, "central_difference_mode")
            if ~any(grad_info.sufficient_decrease_each_block)
                is_gradient_returned = true;
            end
        % If the finite difference mode is "mixed_difference_mode", we will return the gradient as long as all directions have been sampled.
        % In this case, we do not check for sufficient decrease.
        elseif strcmpi(grad_info.finite_difference_mode, "mixed_difference_mode")
            is_gradient_returned = true;
        end
    end
    if is_gradient_returned
        % Find the indices of the sampled directions.
        sampled_direction_indices = find(is_sampled_direction);
        % Extract the sampled directions from the direction set.
        sampled_direction_set = grad_info.direction_set(:, sampled_direction_indices);
        % Compute the gradient using the least-squares minimum norm solution.
        gradient = lsqminnorm(sampled_direction_set', directional_derivative(sampled_direction_indices));
    end
else
    % When num_blocks is not equal to batch_size, the gradient is estimated whenever each direction has at least one sampled 
    % directional derivative. This is detected by checking that last_sampled_iteration_per_direction and 
    % last_sampled_iteration_per_direction_update are different, and that all directions have at least one sampled 
    % value (i.e., all(last_sampled_iteration_per_direction_update > 0)). For each direction, the most recently sampled directional 
    % derivative is extracted from the history, and the gradient is computed using the least-squares minimum norm solution.
    if all(last_sampled_iteration_per_direction ~= last_sampled_iteration_per_direction_update) && all(last_sampled_iteration_per_direction_update > 0)
        is_gradient_returned = true;
        directional_derivative =  directional_derivative_history(sub2ind(size(directional_derivative_history), (1:size(directional_derivative_history,1))', last_sampled_iteration_per_direction_update));
        gradient = lsqminnorm(grad_info.direction_set', directional_derivative);
    end
end

% Update the last sampled iteration for each direction.
last_sampled_iteration_per_direction = last_sampled_iteration_per_direction_update;

function [is_sampled_each_direction, block_index_each_direction, direction_position_in_block, is_sampled_positive_negative_direction] = is_direction_sampled(direction_index, num_blocks, fhist_each_block, direction_set_indices_current_iteration)
% is_direction_sampled checks if a specific direction has been sampled in any block.
% Inputs:
%   - direction_index: Index of the direction to check. This should be a positive integer from 1 to n, where n is the number of variables.
%   - num_blocks: Total number of blocks.
%   - fhist_each_block: Cell array of length num_blocks, where each cell contains an array of function values (fhist) for 
%                       the corresponding block.
%   - direction_set_indices_current_iteration: Cell array containing indices of sampled directions for the current iteration.
% Outputs:
%   - is_sampled_each_direction: Boolean indicating if the direction_index-th direction has been sampled in any block.
%   - block_index_each_direction: Index of the block where the direction_index-th direction was sampled. 
%                                 If the direction is not sampled, it will be 0.
%   - direction_position_in_block: Position of the positive and negative direction along the direction_index-th direction 
%                                  in the block where it was sampled.
%   - is_sampled_positive_negative_direction: Boolean array indicating if the positive and negative directions have been sampled.

% Initialize variables to store the results.
is_sampled_each_direction = false;
block_index_each_direction = 0;
% Initialize to NaN for the positive and negative directions.
direction_position_in_block = NaN(2, 1);
% Initialize the boolean array to indicate if the positive and negative directions have been sampled.
is_sampled_positive_negative_direction = false(2, 1);

for block_id = 1:num_blocks
    % Get the number of sampled points in the block_id-th block.
    num_sampled_directions_in_block = length(fhist_each_block{block_id});
    % Get the indices of the sampled directions in the block_id-th block, which are stored in the direction_set_indices_current_iteration.
    sampled_direction_indices_in_block = direction_set_indices_current_iteration{block_id}(1:num_sampled_directions_in_block);

    % Due to our division way,the positive direction and negative direction must be in the same block. The index 
    % of the positive direction in the direction_set is 2*direction_index-1, and the index of the negative direction 
    % is 2*direction_index. Check if the positive and negative directions have been sampled in the block_id-th block.
    % If the direction is not sampled, the positive_direction_position_in_block and negative_direction_position_in_block 
    % will be empty. If the direction is sampled, the positive_direction_position_in_block and negative_direction_position_in_block 
    % will represent the position of the positive and negative directions in the block_id-th block, respectively.
    positive_direction_position_in_block = find(sampled_direction_indices_in_block == 2*direction_index-1, 1);
    negative_direction_position_in_block = find(sampled_direction_indices_in_block == 2*direction_index, 1);

    if ~isempty(positive_direction_position_in_block) || ~isempty(negative_direction_position_in_block)
        % If either the positive or negative direction is sampled, we set the is_sampled_each_direction to true,
        % and we also store the block index in the block_id-th block.
        is_sampled_each_direction = true;
        block_index_each_direction = block_id;
        % If the positive direction is sampled, we store its position in direction_position_in_block first.
        % We also set the is_sampled_positive_negative_direction array accordingly.
        if ~isempty(positive_direction_position_in_block)
            direction_position_in_block(1) = positive_direction_position_in_block;
            is_sampled_positive_negative_direction(1) = true;
        end
        % If the negative direction is sampled, we append its position to direction_position_in_block.
        % We also set the is_sampled_positive_negative_direction array accordingly.
        if ~isempty(negative_direction_position_in_block)
            direction_position_in_block(2) = negative_direction_position_in_block;
            is_sampled_positive_negative_direction(2) = true;
        end
        % If we have found the direction in the current block, we can terminate the function immediately.
        break;
    end
end
end
end