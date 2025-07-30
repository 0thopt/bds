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
%   batch_selection_probability              Vector of size batch_size, containing the selection probabilities for 
%                                            each batch visited in this iteration.
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

batch_selection_probability = grad_info.batch_selection_probability;
% Compute the number of unique directions sampled in this iteration,
% where each direction is defined by a pair of positive and negative directions.
num_sampled_directions = length(direction_indices_this_iter) / 2;
directional_derivative = nan(num_sampled_directions, 1);
% Get the probability of selecting those directions in this iteration.
direction_selection_probability = zeros(num_sampled_directions, num_sampled_directions);

% Extract the indices of positive directions (odd indices) from each batch.
% Each cell contains the indices of positive directions sampled in the corresponding batch.
positive_direction_indices_per_batch = cellfun(@(x) x(mod(x,2)==1), batch_direction_indices, 'UniformOutput', false);

% Compute the number of positive directions in each batch.
lens = cellfun(@length, positive_direction_indices_per_batch);

% Compute the starting index of each batch's positive directions in the concatenated array.
first_indices = [1, cumsum(lens(1:end-1)) + 1];

% Assign the batch selection probability to the corresponding diagonal block in the direction selection probability matrix.
for i = 1:batch_size
    direction_selection_probability(first_indices(i):first_indices(i) + lens(i) - 1, i) = batch_selection_probability(i);
end

% Get the full direction set.
full_direction_set = grad_info.direction_set;
n = size(full_direction_set, 1);
% Extract the positive direction set from the full direction set.
% The positive direction set is the odd columns of the full direction set.
% This is done to ensure that we only consider the positive directions for gradient estimation.
positive_direction_set = full_direction_set(:, 1:2:2*n-1);

% Identify the indices in direction_indices_this_iter corresponding to positive directions (odd indices).
% Sort these indices according to the values in direction_indices_this_iter, so that the positive directions
% are processed in ascending order of their indices in the full direction set.
% The resulting sorted_positive_directions_visited_indices_in_fhist gives the positions in direction_indices_this_iter
% for the sorted positive directions visited in this iteration.
positive_direction_visited_indices_in_fhist = find(mod(direction_indices_this_iter, 2) == 1);
[~, positive_sort_order] = sort(direction_indices_this_iter(positive_direction_visited_indices_in_fhist));
sorted_positive_directions_visited_indices_in_fhist = positive_direction_visited_indices_in_fhist(positive_sort_order);

% Do the same for negative directions (even indices).
negative_direction_visited_indices_in_fhist = find(mod(direction_indices_this_iter, 2) == 0);
[~, negative_sort_order] = sort(direction_indices_this_iter(negative_direction_visited_indices_in_fhist));
sorted_negative_directions_visited_indices_in_fhist = negative_direction_visited_indices_in_fhist(negative_sort_order);

% Extract the set of sampled directions for this iteration from the full direction set.
% For central difference gradient estimation, use positive_direction_visited_indices
% to index the corresponding directions in the full direction set.
% Find the indices of the positive direction visited in this iteration in the full direction set.
positive_direction_visited_indices = direction_indices_this_iter(mod(direction_indices_this_iter, 2) == 1);
sampled_direction_set = full_direction_set(:, positive_direction_visited_indices);

for i = 1:num_sampled_directions

    % Find the indices of the positive and negative directions in the direction_indices_this_iter.
    positive_index_in_fhist = sorted_positive_directions_visited_indices_in_fhist(i);
    negative_index_in_fhist = sorted_negative_directions_visited_indices_in_fhist(i);

    for j = 1:batch_size
        % Find the batch that contains both the indices of the positive and negative directions in the full
        % direction set.
        if any(batch_direction_indices{j} == direction_indices_this_iter(positive_index_in_fhist)) && any(batch_direction_indices{j} == direction_indices_this_iter(negative_index_in_fhist))
            sample_batch_index = j;
            % Only the first occurrence is needed.
            break;
        end
    end
    
    % Calculate the directional derivative.
    directional_derivative(i) = (fhist_this_iter(positive_index_in_fhist) - fhist_this_iter(negative_index_in_fhist)) / (2 * step_size_each_batch(sample_batch_index));

end

% Why use the backslash operator instead of lsqminnorm? Since positive_direction_set is invertible and
% direction_selection_probability is a diagonal matrix with strictly positive diagonal elements, the matrix
% positive_direction_set * direction_selection_probability * positive_direction_set' is guaranteed to be positive definite.
% In this case, the backslash operator provides a more efficient and numerically stable solution than lsqminnorm.
grad = (positive_direction_set * direction_selection_probability * positive_direction_set') \ (sampled_direction_set * directional_derivative);

end