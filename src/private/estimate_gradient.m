function grad = estimate_gradient(grad_info)
%ESTIMATE_GRADIENT estimates the gradient using finite difference methods.
%   The gradient is computed only if all directions in the batch visited in the current iteration have been sampled.
%   grad_info should be a structure with the following fields.
%   direction_set                            Matrix containing only the positive directions (i.e., the odd columns of 
%                                            the full direction set in bds.m). This matrix is of size n x n, where each 
%                                            column corresponds to a basis direction d_i (i=1,...,n).
%                                            Note: direction_set here has already been extracted as the odd 
%                                            columns (1:2:2*n-1) outside this function.
%   batch_direction_indices                  Cell array of size batch_size, where each cell contains the indices of the 
%                                            directions visited in this iteration.
%   batch_fhist                              Cell array of batch_size, where each cell contains the function values 
%                                            corresponding to the directions visited in this iteration.
%   step_size_each_batch                     Vector of size batch_size, containing the step sizes for each batch visited 
%                                            in this iteration.
%   direction_set_indices_current_iteration  Cell array containing indices of sampled directions for the current iteration.

% Outputs:
%   - grad: Estimated gradient vector of size n x 1, where n is the number of dimensions.


batch_direction_indices = grad_info.batch_direction_indices;
% Concatenate all the indices of the directions visited in this iteration into a single vector.
direction_indices_this_iter = [batch_direction_indices{:}];
batch_fhist = grad_info.batch_fhist;
% Concatenate all the function values corresponding to the directions visited in this iteration 
% into a single vector.
fhist_this_iter = [batch_fhist{:}];
% Get the step sizes for the batch visited in this iteration.
step_size_each_batch = grad_info.step_size_each_batch;
batch_size = length(step_size_each_batch);
% Compute the number of unique directions sampled in this iteration,
% where each direction is defined by a pair of positive and negative directions.
num_sampled_directions = length(direction_indices_this_iter) / 2;
num_directional_derivatives = ceil(num_sampled_directions / 2);
directional_derivative = nan(num_directional_derivatives, 1);
% Get the full direction set.
full_direction_set = grad_info.direction_set;
n = size(full_direction_set, 1);

% Find the indices of the positive direction visited in this iteration in direction_indices_this_iter.
% These indices correspond to the positive directions in the full direction set.
% The positive directions are those with odd indices in the full direction set.
positive_direction_visited_indices = find(mod(direction_indices_this_iter, 2) == 1);
% Sort the positive directions visited in this iteration and get their indices in the direction_indices_this_iter.
[~, positive_direction_visited_indices_sorted] = sort(direction_indices_this_iter(positive_direction_visited_indices));
positive_direction_visited_indices_sorted = positive_direction_visited_indices(positive_direction_visited_indices_sorted);

% Find the indices of the negative direction visited in this iteration in direction_indices_this_iter.
% These indices correspond to the negative directions in the full direction set.
% The negative directions are those with even indices in the full direction set.
negative_direction_visited_indices = find(mod(direction_indices_this_iter, 2) == 0);
% Sort the negative directions visited in this iteration and get their indices in the direction_indices_this_iter.
[~, negative_direction_visited_indices_sorted] = sort(direction_indices_this_iter(negative_direction_visited_indices));
negative_direction_visited_indices_sorted = negative_direction_visited_indices(negative_direction_visited_indices_sorted);

% Extract the set of sampled directions for this iteration from the full direction set.
% For central difference gradient estimation, use positive_direction_visited_indices_sorted
% to index the corresponding directions in the full direction set.
sampled_direction_set = full_direction_set(:, positive_direction_visited_indices_sorted);

for i = 1:length(positive_direction_visited_indices_sorted)
    % Get the index of the positive direction.
    pos_index = positive_direction_visited_indices_sorted(i);
    % Get the index of the negative direction.
    neg_index = negative_direction_visited_indices_sorted(i);

    for j = 1:length(batch_size)
        % Identify the batch that contains both the positive and negative direction indices.
        % This is done by checking if both pos_index and neg_index are present in the current batch_direction_indices cell.
        for k = 1:length(batch_direction_indices)
            if any(batch_direction_indices{k} == pos_index) && any(batch_direction_indices{k} == neg_index)
                batch_with_directions_index = k;
                % Only the first occurrence is needed.
                break;
            end
        end
    end
    
    % Calculate the directional derivative.
    directional_derivative(i) = (fhist_this_iter(pos_index) - fhist_this_iter(neg_index)) / 2 * step_size_each_batch(batch_with_directions_index);

end

% grad = lsqminnorm(full_direction_set*full_direction_set', (n / num_sampled_directions) * sampled_direction_set * directional_derivative);
% Why use the backslash operator instead of lsqminnorm? Since full_direction_set is invertible,
% full_direction_set*full_direction_set' is positive definite. The backslash operator provides a more efficient solution in this case.
grad = (full_direction_set*full_direction_set') \ ((n / num_sampled_directions) * sampled_direction_set * directional_derivative);

end
