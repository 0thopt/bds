function perf = tuning_score(profile_score, tau_weights)
    % profile_score: a 2x10x2x3 numeric array
    % tau_weights: a 2x10x2x3 numeric array
    % Compute the performance score
    % The performance score is the weighted sum of the profile scores
    % The weights are given by tau_weights

    % Compute the weighted sum of the profile scores
    perf = sum(profile_score(:) .* tau_weights(:));
end