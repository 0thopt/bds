function direction_selection_probability_matrix = compute_block_selection_probability(block_selection_weight, batch_size, grouped_direction_indices, n)
%COMPUTE_BLOCK_SELECTION_PROBABILITY computes the marginal probability that each block is selected
%when batch_size blocks are sampled without replacement, given the selection weights p (block_selection_weight).
%Returns a diagonal matrix whose diagonal elements are the selection probabilities for each block.
%   block_selection_weight        Weight vector [p1, p2, ..., pn] (positive real numbers),
%                                 where n is the number of blocks.
%   batch_size                    Number of blocks to select, which is a positive integer 
%                                 (1 <= batch_size <= numel(block_selection_weight)).
%   grouped_direction_indices     Cell array of size num_blocks, where each cell contains the indices of the
%                                 directions corresponding to the block.
%   n                             Number of dimensions (optional, if not provided, it will be inferred from the grouped_direction_indices).
% When sampling m blocks without replacement, the marginal probability that block k is selected is:
%   P_k = [p_k * e_{m-1}(p_{-k})] / e_m(p)
% where:
%   p_k             the weight of block k,
%   e_{m-1}(p_{-k}) the (m-1)-th elementary symmetric polynomial of the weights excluding p_k,
%   e_m(p)          the m-th elementary symmetric polynomial of all weights.

% Get the number of blocks.
num_blocks = length(block_selection_weight);

% Initialize the array for elementary symmetric polynomials:
% ep(1) = e_0, ep(2) = e_1, ..., ep(m+1) = e_m, where m = batch_size.
ep = zeros(1, batch_size+1);
% Set the 0-th elementary symmetric polynomial: e_0 = 1.
ep(1) = 1;

% Add weights one by one for all blocks.
for i = 1:num_blocks
    % At each step, determine the highest degree of the elementary symmetric polynomial to update,
    % which is at most batch_size or the current number of blocks considered (i).
    j_max = min(batch_size, i);  % The maximum order that can be computed with the first i blocks

    % Update the elementary symmetric polynomials from high to low order to avoid overwriting values.
    % ep(j+1) stores the value of the j-th order elementary symmetric polynomial of the first i blocks (weights).
    for j = j_max:-1:1
        % Dynamic programming update rule:
        % e_j(p_{1..i}) = e_j(p_{1..i-1}) + p_i * e_{j-1}(p_{1..i-1})
        ep(j+1) = ep(j+1) + block_selection_weight(i) * ep(j);
    end
end

% Initialize probability vector.
block_selection_probability = zeros(size(block_selection_weight));
% Handle the special case when m=1 (no iteration needed)
if batch_size == 1
    % When m=1, e_{m-1}(p_{-k}) = e_0(p_{-k}) = 1.
    % Therefore P_k = p_k / e_1(p) = p_k / sum(p).
    % ep(2) = e_1(p) = sum(p), which is the sum of all weights.
    block_selection_probability = block_selection_weight / ep(2);
end

% Iterate over each block to compute its selection probability.
for k = 1:num_blocks

    % Create an array q to store the values of the elementary symmetric polynomials of all orders
    % with the k-th block removed. The size of q is [1, batch_size].
    % Index mapping: q(j) corresponds to the (j-1)-th order elementary symmetric polynomial.
    % Initialize all-zero array.
    q = zeros(1, batch_size);

    % Set the 0-th elementary symmetric polynomial value, which is always 1.
    % q(1) = e_0(p_{-k}) = 1, where the product over the empty set is defined to be 1.
    q(1) = 1;  % Mathematically: e_0(p_{-k}) = 1.

    % Compute the elementary symmetric polynomials with the k-th block removed.
    % Use the recurrence relation to compute the elementary symmetric polynomials from order 1 to (batch_size-1).
    for j = 1:(batch_size-1)
        % Mathematical explanation:
        %   The j-th order elementary symmetric polynomial of all blocks e_j(p) can be decomposed as:
        %      e_j(p) = e_j(p_{-k}) + p_k × e_{j-1}(p_{-k})
        %   where:
        %     - e_j(p_{-k}) is the j-th order polynomial excluding the k-th block
        %     - p_k × e_{j-1}(p_{-k}) is the j-th order polynomial including the k-th block
        %   Rearranging gives: e_j(p_{-k}) = e_j(p) - p_k × e_{j-1}(p_{-k})
        % Recurrence relation:
        %   e_j(p_{-k}) = e_j(p) - p_k × e_{j-1}(p_{-k})
        % Where:
        %   ep(j+1) = e_j(p)             (the j-th elementary symmetric polynomial of all blocks)
        %   q(j) = e_{j-1}(p_{-k})       (the (j-1)-th elementary symmetric polynomial with the k-th block removed)
        %   block_selection_weight(k) = p_k (the weight of the k-th block)
        %
        % Update q(j+1) = e_j(p_{-k})


        % Mathematical explanation:
        %   The j-th order elementary symmetric polynomial e_j(p) can be written as:
        %      e_j(p) = e_j(p_{-k}) + p_k * e_{j-1}(p_{-k}),
        %   where:
        %     - e_j(p_{-k}) is the j-th order polynomial excluding the k-th block
        %     - p_k × e_{j-1}(p_{-k}) is the j-th order polynomial including the k-th block
        %   Rearranged, the recurrence is:
        %      e_j(p_{-k}) = e_j(p) - p_k * e_{j-1}(p_{-k})
        %   with:
        %     ep(j+1) = e_j(p) (the j-th elementary symmetric polynomial of all blocks)
        %     q(j)    = e_{j-1}(p_{-k}) (the (j-1)-th elementary symmetric polynomial with the k-th block removed)
        %     p_k     = block_selection_weight(k).
        %   Update q(j+1) = e_j(p_{-k})
        q(j+1) = ep(j+1) - block_selection_weight(k) * q(j);
    end

    % We need the (batch_size-1) order elementary symmetric polynomial with the k-th block removed
    % In the q array, where q(batch_size) corresponds to e_{batch_size-1}(p_{-k}).
    e_m1_minus_k = q(batch_size);
    
    % Index explanation:
    %   The q array is 1-based:
    %     q(1) -> 0th order (e_0)
    %     q(2) -> 1st order (e_1)
    %     ...
    %     q(batch_size) -> (batch_size-1)th order (e_{m-1})

    % Probability formula:
    %   P_k = [p_k × e_{m-1}(p_{-k})] / e_m(p)
    % where:
    %   block_selection_weight(k) = p_k
    %   e_m1_minus_k = e_{m-1}(p_{-k})
    %   ep(batch_size+1) = e_m(p), the m-th order elementary symmetric polynomial of all blocks
    block_selection_probability(k) = block_selection_weight(k) * e_m1_minus_k / ep(batch_size+1);

end

% Special case: if batch_size equals num_blocks,
% then all blocks are selected, and the selection probability for each block is 1.
if batch_size == num_blocks
    block_selection_probability(:) = 1;
end

% Initialize the direction selection probability matrix.
% The diagonal elements will store the selection probability for each positive direction.
direction_selection_probability_matrix = zeros(n, n);

% Extract the indices of positive directions (odd indices) from each block.
% Each cell contains the indices of positive directions sampled in the corresponding block.
positive_direction_indices_per_block = cellfun(@(x) x(mod(x,2)==1), grouped_direction_indices, 'UniformOutput', false);

% Compute the number of positive directions in each block.
num_positive_directions_per_block = cellfun(@length, positive_direction_indices_per_block);

% Compute the starting index of each block's positive directions in the concatenated array.
start_indices_positive_directions = [1, cumsum(num_positive_directions_per_block(1:end-1)) + 1];

% Assign the block selection probability to the corresponding diagonal block in the direction selection probability matrix.
for i = 1:n
    direction_selection_probability_matrix(start_indices_positive_directions(i):start_indices_positive_directions(i) + num_positive_directions_per_block(i) - 1, i) = block_selection_probability(i);
end
keyboard
end

