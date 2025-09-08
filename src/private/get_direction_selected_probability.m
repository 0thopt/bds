function direction_selection_probability_matrix = get_direction_selected_probability(n, batch_size, grouped_direction_indices, available_block_indices)
    % Calculate the probability of each direction being selected
    % Returns a diagonal matrix where the i-th diagonal element represents 
    % the probability of selecting the i-th direction
    
    % Initialize a vector to hold probabilities for each direction
    direction_probabilities = zeros(n, 1);
    
    % Calculate how many blocks are available in this iteration.
    num_available_blocks = length(available_block_indices);
    
    % Calculate the probability that those blocks are possibly selected, the probability of
    % other blocks should be zero.
    if num_available_blocks > 0
        % Probability of selecting a particular block in this iteration
        block_selection_probability = batch_size / num_available_blocks;

        % Calculate the probability for each direction based on the number of available blocks
        for i = 1:num_available_blocks
            % Get the indices of the directions in the available_block_indices(i)-th block
            direction_indices = grouped_direction_indices{available_block_indices(i)};
            % Extract the primary (forward) directions (d_i, not -d_i)
            primary_direction_indices = direction_indices(mod(direction_indices, 2) == 1);
            direction_probabilities((primary_direction_indices+1)/2) = block_selection_probability;
        end
    end
    
    % Create diagonal matrix with the probabilities
    direction_selection_probability_matrix = diag(direction_probabilities);
    
end