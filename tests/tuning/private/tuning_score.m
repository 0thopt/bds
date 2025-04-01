function perf = tuning_score(profile_score, tau_weights)
    % profile_score: a 2x10x2x3 numeric array
    % tau_weights: a 2x10x2x3 numeric array
    % Compute the performance score
    % The performance score is the weighted sum of the profile scores
    % The weights are given by tau_weights

    % For temporary testing purposes, we will use the following code
    % to compute the performance score, which means that we will maximize
    % the difference, not only the score of the tuning solver.
    perf = sum((profile_score(1, :, 2, 1) - profile_score(2, :, 2, 1)) .* tau_weights(1, :, 2, 1));
    % Compute the weighted sum of the profile scores.
    % perf = sum(profile_score(:) .* tau_weights(:));
    
end