function block_selection_probability = compute_block_selection_probability(block_selection_weight, batch_size)
%Compute_BLOCK_SELECTION_PROBABILITY Compute the probability that each block is selected 
%when batch_size blocks are drawn without replacement,
%   given the selection weights p (corresponding to block_selection_weight).
%   block_selection_weight        Weight vector [p1, p2, ..., pn] (positive real numbers),
%                                 where n is the number of blocks.
%   batch_size                    Number of blocks to select, which is a positive integer 
%                                 (1 <= batch_size <= numel(block_selection_weight)).
%   block_selection_probability   Probability vector, where the k-th element is the probability that
%                                 the k-th block is selected. For convenience, use P to denote this vector.
%   The core mathematical formula used is:
%   P_k = [p_k * e_{m-1}(p_{-k})] / e_m(p), where
%   e_m(p)                        the m-th elementary symmetric polynomial of the weights (i.e., the sum 
%                                 over all products of m distinct elements of block_selection_weight).
%   e_{m-1}(p_{-k})               the (m-1)-th elementary symmetric polynomial of the weights with p_k 
%                                 excluded (i.e., the sum over all products of m-1 distinct elements of 
%                                 block_selection_weight, excluding p_k).

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
    return;
end

% For num_blocks > 1, compute the selection probability for each element k.
for k = 1:num_blocks
    
    % Initialize q_0 = e_0(p_{-k}) = 1 since the 0-th order elementary 
    % symmetric polynomial is always 1.
    q_prev = 1;
    for j = 1:(batch_size-1)
        % Recurrence: q_j = e_j(p) - p_k * q_{j-1}, where q_j = e_j(p_{-k}).
        % To get e_{m-1}(p_{-k}), we need to compute it iteratively.
        q_prev = ep(j+1) - block_selection_weight(k) * q_prev;
    end

    % Compute e_{m-1}(p_{-k}), the (m-1)-th elementary symmetric polynomial with p_k excluded,
    % using the recurrence relation (polynomial division).
    % Apply the selection probability formula:
    %   P_k = [p_k * e_{m-1}(p_{-k})] / e_m(p)
    % where:
    %   p_k      = the k-th selection weight
    %   q_prev   = e_{m-1}(p_{-k}), computed iteratively above
    %   ep(m+1)  = e_m(p), the m-th elementary symmetric polynomial of all weights
    block_selection_probability(k) = block_selection_weight(k) * q_prev / ep(batch_size+1);
end

% Special case: if batch_size equals num_blocks,
% then all blocks are selected, and the selection probability for each block is 1.
if batch_size == num_blocks

    block_selection_probability(:) = 1;
end