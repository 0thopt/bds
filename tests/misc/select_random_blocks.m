function block_indices = select_random_blocks(num_blocks, batch_size, random_stream, block_selecting_probability)
%SELECT_RANDOM_BLOCKS Select batch_size blocks randomly from 1:num_blocks according to the specified probabilities.
%   num_blocks: Total number of blocks.
%   batch_size: Number of blocks to select.
%   random_stream: Random stream for reproducibility.
%   block_selecting_probability: A vector of probabilities for selecting each block.
%

% Initialize the selected block indices.
block_indices = zeros(1, batch_size);
% Indices of remaining blocks.
remaining_indices = 1:num_blocks;

% Initialize the probability distribution for block selection.
% Once a block is selected, it is removed from the candidate set and will not be selected again in subsequent 
% selections. The probabilities will be renormalized at each selection step to ensure they sum to 1.
current_block_selecting_probability = block_selecting_probability;

for i = 1:batch_size
    
    % Normalize the current weights to probabilities before selection.
    totalWeight = sum(current_block_selecting_probability);
    probabilities = current_block_selecting_probability / totalWeight;

    % Calculate cumulative probabilities.
    cumProb = cumsum(probabilities);

    % Generate a random number and select the index.
    r = random_stream.rand();
    idx = find(r <= cumProb, 1, 'first');

    % Record the selected block index.
    block_indices(i) = remaining_indices(idx);

    % Update the remaining indices and probabilities.
    remaining_indices(idx) = [];
    current_block_selecting_probability(idx) = [];
    
end

end