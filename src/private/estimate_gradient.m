function grad = estimate_gradient(grad_info)
%ESTIMATE_GRADIENT estimates the gradient using finite difference methods.
%   The gradient is computed only if all batches do not achieve sufficient decrease.
%   grad_info should be a structure with the following fields.
%   complete_direction_set                   Matrix containing all directions (i.e., both positive and negative) 
%                                            used in the optimization.
%   sampled_direction_indices_per_batch      Cell array of size batch_size, where each cell contains the indices of the 
%                                            directions visited in this iteration.
%   function_values_per_batch                Cell array of batch_size, where each cell contains the function values 
%                                            corresponding to the directions visited in this iteration.
%   direction_selection_probability_matrix   Diagonal matrix of size n x n, where the diagonal elements store the 
%                                            selection probability for each positive direction.
%   step_size_per_batch                      Vector of size batch_size, containing the step sizes for each batch visited 
%                                            in this iteration.
%   n                                        The number of dimensions (i.e., the number of positive directions).

% Outputs:
%   - grad: Estimated gradient vector of size n x 1, where n is the number of dimensions.

n = grad_info.n;
sampled_direction_indices_per_batch = grad_info.sampled_direction_indices_per_batch;

% Concatenate all the direction indices visited in this iteration into a single vector
all_sampled_direction_indices = [sampled_direction_indices_per_batch{:}];

% For each dimension i (1 to n), we have a positive direction d_i and a negative direction -d_i
% In our implementation, these are indexed as:
%   - Positive directions d_i: indexed as 2*i-1 (odd numbers)
%   - Negative directions -d_i: indexed as 2*i (even numbers)
% For gradient estimation, we only need one basis direction per dimension.
% We collect the positive direction indices for all dimensions where either the positive or negative direction was sampled.
sampled_dimension_indices = [];
for direction_idx = 1:n
    % For dimension direction_idx, check if either direction (positive or negative) was sampled.
    if any(all_sampled_direction_indices == 2*direction_idx - 1) || any(all_sampled_direction_indices == 2*direction_idx)
        % If either was sampled, we include the positive direction d_i in our basis.
        sampled_dimension_indices = [sampled_dimension_indices, direction_idx];
    end
end

% Sort the indices for consistent ordering.
sorted_sampled_dimension_indices = sort(sampled_dimension_indices);

% Initialize the directional derivative vector for all sampled dimensions.
sampled_directional_derivatives = nan(length(sorted_sampled_dimension_indices), 1);

function_values_per_batch = grad_info.function_values_per_batch;

% Get the step sizes and direction selection probabilities.
step_size_per_batch = grad_info.step_size_per_batch;
direction_selection_probability_matrix = grad_info.direction_selection_probability_matrix;

% Extract the positive direction set.
% This contains only the positive directions {d_1, ..., d_n} that were sampled.
% Note that even if only -d_i was sampled, we still use d_i in our basis.
complete_direction_set = grad_info.complete_direction_set;
sampled_basis_directions = complete_direction_set(:, 2*sorted_sampled_dimension_indices-1);
complete_basis_directions = complete_direction_set(:, 1:2:end);

for j = 1:length(sorted_sampled_dimension_indices)
    sampled_directional_derivatives(j) = estimate_directional_derivative(sorted_sampled_dimension_indices(j), step_size_per_batch, function_values_per_batch, sampled_direction_indices_per_batch);
end

% Why use the backslash operator instead of lsqminnorm? Since complete_basis_directions is invertible and
% direction_selection_probability_matrix is a diagonal matrix with strictly positive diagonal elements, the matrix
% complete_basis_directions * direction_selection_probability_matrix * complete_basis_directions' is guaranteed to be positive definite.
% In this case, the backslash operator provides a more efficient and numerically stable solution than lsqminnorm.
grad = (complete_basis_directions * direction_selection_probability_matrix * complete_basis_directions') \ (sampled_basis_directions * sampled_directional_derivatives);

end

function [directional_derivative] = estimate_directional_derivative(positive_direction_index_visited, step_size_per_batch, function_values_per_batch, sampled_direction_indices_per_batch)
    
    for batch_idx = 1:length(step_size_per_batch)
        % Check if the positive direction is evaluated in this batch
        positive_index = find(sampled_direction_indices_per_batch{batch_idx} == 2*positive_direction_index_visited);

        % Check if the negative direction is evaluated in this batch
        negative_index = find(sampled_direction_indices_per_batch{batch_idx} == 2*positive_direction_index_visited - 1);

        % Three cases for directional derivative estimation:
        % 1. Both positive and negative directions are evaluated (central difference)
        % 2. Only positive direction is evaluated (forward difference)
        % 3. Only negative direction is evaluated (backward difference)
        if ~isempty(positive_index) && ~isempty(negative_index)
            % Central difference formula
            directional_derivative = (function_values_per_batch{batch_idx}(positive_index) - function_values_per_batch{batch_idx}(negative_index)) / (2 * step_size_per_batch(batch_idx));
            return;
        elseif ~isempty(positive_index)
            keyboard
            % Forward difference formula
            directional_derivative = (function_values_per_batch{batch_idx}(positive_index) - function_values_per_batch{batch_idx}(1)) / step_size_per_batch(batch_idx);
            return;
        elseif ~isempty(negative_index)
            keyboard
            % Backward difference formula
            directional_derivative = (function_values_per_batch{batch_idx}(1) - function_values_per_batch{batch_idx}(negative_index)) / step_size_per_batch(batch_idx);
            return;
        end
    end
end