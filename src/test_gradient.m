function test_gradient(n, seed)

    % Add an optional seed parameter for reproducibility
    % Default seed if not provided
    if nargin < 2
        time_zone = "Asia/Shanghai";

        dt = datetime("now", "TimeZone", time_zone);
        yw = 100*mod(year(dt), 100) + week(dt);
        seed = yw;
    end

    if nargin < 1
        n = randi(1000); % Randomly choose a dimension between 1 and 1000
    end

    % Save current random number generator state
    oldState = rng();
    
    % Set the random seed for reproducibility
    rng(seed);

    % Randomly generate a point in n-dimensional space.
    x = randn(n, 1);
    options.direction_set = randn(n, n);
    
    % Let each batch has their own step size. We only test the case where batch_size is equal to n since it
    % is deterministic.
    grad_info.step_size_per_batch = 0.01 + 0.09 * rand(n, 1);
    % Give estimate_gradient.m enough information.
    grad_info.complete_direction_set = get_direction_set(n, options);
    positive_direction_set = grad_info.complete_direction_set(:, 1:2:end);
    grad_info.sampled_direction_indices_per_batch = divide_direction_set(n, n);
    % Since the batch_size is equal to n, every direction should be visited when all directions fail to get
    % sufficient decrease.
    grad_info.direction_selection_probability_matrix = eye(n);

    % Use different way from bds.m to compute function values and divide those function values into corresponding batches.
    grad_info.function_values_per_batch = cellfun(@(batch_idx, b) arrayfun(@(d) ...
        cubic_function_with_gradient(x + grad_info.step_size_per_batch(b) * grad_info.complete_direction_set(:, batch_idx(d))), ...
        1:length(batch_idx)), ...
        grad_info.sampled_direction_indices_per_batch, num2cell(1:length(grad_info.sampled_direction_indices_per_batch)), ...
        'UniformOutput', false);

    grad_info.n = n;
    estimate_grad = estimate_gradient(grad_info);
    [~, true_grad] = cubic_function_with_gradient(x);

    alpha_powers = grad_info.step_size_per_batch.^4;
    direction_norms = vecnorm(positive_direction_set).^6;

    grad_diff = norm(estimate_grad - true_grad);
    theoretical_bound = (1 / (6 * min(svd(positive_direction_set)))) * sqrt(sum(direction_norms .* alpha_powers'));
    assert(grad_diff <= theoretical_bound - 1e-10, ...
        'Gradient estimation error does not match theoretical bound with tolerance 1e-10');

    fprintf('Test passed! Actual gradient difference: %e, Theoretical bound: %e\n', grad_diff, theoretical_bound);
    
    % Restore the original random number generator state
    rng(oldState);
    
end

function [f, grad] = cubic_function_with_gradient(x)
    % A simple cubic function whose lipschitz constant of the hessian is 1.
    f = sum(x.^3) / 6;
    grad = 0.5 * x.^2;
end