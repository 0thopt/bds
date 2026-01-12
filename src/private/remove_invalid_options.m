function options = remove_invalid_options(options, n)
% REMOVE_INVALID_OPTIONS Validate and clean the options structure.
%
% This function ensures that all fields in the `options` structure have valid
% values. If a field contains an invalid value, a warning is issued, and the
% field is removed.
%
% Inputs:
%   - options: A structure containing the options to be validated.
%   - n: The dimension of the optimization problem.
%
% Outputs:
%   - options: The validated and updated options structure, with invalid fields
%              removed.
%
% Notes:
%   - This function assumes that `options` only contains valid field names.
%     Any unknown fields should be removed prior to calling this function.
%

% MaxFunctionEvaluations
if isfield(options, 'MaxFunctionEvaluations')
    if ~(isintegerscalar(options.MaxFunctionEvaluations) && options.MaxFunctionEvaluations > 0)
        warning('BDS:set_options:InvalidMaxFunctionEvaluations', ...
            'options.MaxFunctionEvaluations must be a positive integer. Use default value instead.');
        options = rmfield(options, 'MaxFunctionEvaluations');
    end
end

% ftarget
if isfield(options, 'ftarget')
    if ~isrealscalar(options.ftarget)
        warning('BDS:set_options:InvalidFtarget', ...
            'options.ftarget must be a real scalar. Use default value instead.');
        options = rmfield(options, 'ftarget');
    end
end

% StepTolerance
if isfield(options, 'StepTolerance')
    if ~((isrealscalar(options.StepTolerance) && options.StepTolerance > 0) || ...
         (isnumvec(options.StepTolerance) && all(options.StepTolerance > 0) && ...
          isfield(options, 'num_blocks') && ...
          length(options.StepTolerance) <= options.num_blocks && ...
          length(options.StepTolerance) <= n))
        warning('BDS:set_options:InvalidStepTolerance', ...
            "options.StepTolerance must be a positive scalar or a positive vector with length matching options.num_blocks and not exceeding the problem dimension n. Use default value instead.");
        options = rmfield(options, 'StepTolerance');
    end
end

% use_function_value_stop
if isfield(options, 'use_function_value_stop')
    if ~(islogical(options.use_function_value_stop) && isscalar(options.use_function_value_stop))
        warning('BDS:set_options:InvalidUseFunctionValueStop', ...
            'options.use_function_value_stop must be a logical scalar. Use default value instead.');
        options = rmfield(options, 'use_function_value_stop');
    end
end

% func_window_size
if isfield(options, 'func_window_size')
    if ~(isintegerscalar(options.func_window_size) && options.func_window_size > 0)
        warning('BDS:set_options:InvalidFuncWindowSize', ...
            'options.func_window_size must be a positive integer. Use default value instead.');
        options = rmfield(options, 'func_window_size');
    end
end

% func_tol_1 / func_tol_2
if isfield(options, 'func_tol_1')
    if ~(isrealscalar(options.func_tol_1) && options.func_tol_1 > 0)
        warning('BDS:set_options:InvalidFuncTol1', ...
            'options.func_tol_1 must be a positive real scalar. Use default value instead.');
        options = rmfield(options, 'func_tol_1');
    end
end
if isfield(options, 'func_tol_2')
    if ~(isrealscalar(options.func_tol_2) && options.func_tol_2 > 0)
        warning('BDS:set_options:InvalidFuncTol2', ...
            'options.func_tol_2 must be a positive real scalar. Use default value instead.');
        options = rmfield(options, 'func_tol_2');
    end
end
if isfield(options, 'func_tol_1') && isfield(options, 'func_tol_2')
    if options.func_tol_1 < options.func_tol_2
        warning('BDS:set_options:InconsistentFuncTols', ...
            'options.func_tol_1 must be >= options.func_tol_2. Use default value instead.');
        options = rmfield(options, 'func_tol_1');
        options = rmfield(options, 'func_tol_2');
    end
end

% use_estimated_gradient_stop
if isfield(options, 'use_estimated_gradient_stop')
    if ~(islogical(options.use_estimated_gradient_stop) && isscalar(options.use_estimated_gradient_stop))
        warning('BDS:set_options:InvalidUseEstimatedGradientStop', ...
            'options.use_estimated_gradient_stop must be a logical scalar. Use default value instead.');
        options = rmfield(options, 'use_estimated_gradient_stop');
    end
end

% grad_window_size
if isfield(options, 'grad_window_size')
    if ~(isintegerscalar(options.grad_window_size) && options.grad_window_size > 0)
        warning('BDS:set_options:InvalidGradWindowSize', ...
            'options.grad_window_size must be a positive integer. Use default value instead.');
        options = rmfield(options, 'grad_window_size');
    end
end

% grad_tol_1 / grad_tol_2
if isfield(options, 'grad_tol_1')
    if ~(isrealscalar(options.grad_tol_1) && options.grad_tol_1 > 0)
        warning('BDS:set_options:InvalidGradTol1', ...
            'options.grad_tol_1 must be a positive real scalar. Use default value instead.');
        options = rmfield(options, 'grad_tol_1');
    end
end
if isfield(options, 'grad_tol_2')
    if ~(isrealscalar(options.grad_tol_2) && options.grad_tol_2 > 0)
        warning('BDS:set_options:InvalidGradTol2', ...
            'options.grad_tol_2 must be a positive real scalar. Use default value instead.');
        options = rmfield(options, 'grad_tol_2');
    end
end
if isfield(options, 'grad_tol_1') && isfield(options, 'grad_tol_2')
    if options.grad_tol_1 < options.grad_tol_2
        warning('BDS:set_options:InconsistentGradTols', ...
            'options.grad_tol_1 must be >= options.grad_tol_2. Use default value instead.');
        options = rmfield(options, 'grad_tol_1');
        options = rmfield(options, 'grad_tol_2');
    end
end

% Algorithm
Algorithm_list = ["cbds", "pbds", "pads", "rbds", "ds"];
if isfield(options, 'Algorithm')
    if ~(ischarstr(options.Algorithm) ...
        && any(ismember(lower(string(options.Algorithm)), Algorithm_list)))
        warning('BDS:set_options:InvalidAlgorithm', ...
            'options.Algorithm must be one of: cbds, pbds, pads, rbds, ds. Use default value instead.');
        options = rmfield(options, 'Algorithm');
    end
end

% direction_set (basis matrix of size n-by-n)
if isfield(options, 'direction_set')
    if ~(ismatrix(options.direction_set) && (size(options.direction_set,1) == n) ...
        && (size(options.direction_set,2) == n))
        warning('BDS:set_options:InvalidDirectionSet', ...
            'options.direction_set must be an n-by-n matrix (n is dimension of the problem). Use default value instead.');
        options = rmfield(options, 'direction_set');
    end
end

% num_blocks
if isfield(options, 'num_blocks')
    if ~(isintegerscalar(options.num_blocks) && options.num_blocks > 0)
        warning('BDS:set_options:InvalidNumBlocks', ...
            'options.num_blocks must be a positive integer. Use default value instead.');
        options = rmfield(options, 'num_blocks');
    elseif options.num_blocks > n
        warning('BDS:set_options:NumBlocksTooLarge', ...
            'options.num_blocks cannot exceed the dimension of n. Use default value instead.');
        options = rmfield(options, 'num_blocks');
    end
end

% batch_size
if isfield(options, 'batch_size')
    if ~(isintegerscalar(options.batch_size) && options.batch_size > 0)
        warning('BDS:set_options:InvalidBatchSize', ...
            'options.batch_size must be a positive integer. Use default value instead.');
        options = rmfield(options, 'batch_size');
    end
    if isfield(options, 'num_blocks') && options.batch_size > options.num_blocks
        warning('BDS:set_options:BatchSizeTooLarge', ...
            'options.batch_size cannot exceed options.num_blocks. Use default value instead.');
        options = rmfield(options, 'batch_size');
    end
    if options.batch_size > n
        warning('BDS:set_options:BatchSizeTooLarge', ...
            'options.batch_size cannot exceed the dimension of n. Use default value instead.');
        options = rmfield(options, 'batch_size');
    end
end

% replacement_delay
if isfield(options, 'replacement_delay')
    if ~(isintegerscalar(options.replacement_delay) && options.replacement_delay >= 0)
        warning('BDS:set_options:InvalidReplacementDelay', ...
            'options.replacement_delay must be a non-negative integer. Use default value instead.');
        options = rmfield(options, 'replacement_delay');
    end
    if (isfield(options, 'num_blocks') && isfield(options, 'batch_size')) && ...
            (options.replacement_delay >= floor(options.num_blocks / options.batch_size) - 1)
        warning('BDS:set_options:ReplacementDelayTooLarge', ...
            'options.replacement_delay must be less than floor(num_blocks / batch_size) - 1. Use default value instead.');
        options = rmfield(options, 'replacement_delay');
    end
end

% grouped_direction_indices
if isfield(options, 'grouped_direction_indices')
    if ~iscell(options.grouped_direction_indices)
        warning('BDS:set_options:InvalidGroupedDirectionIndices', ...
            'options.grouped_direction_indices must be a cell array. Use default value instead.');
        options = rmfield(options, 'grouped_direction_indices');
    else
        total_directions = 0;
        for k = 1:length(options.grouped_direction_indices)
            group = options.grouped_direction_indices{k};
            if ~(isnumvec(group) && all(group >= 1) && all(group <= n) && length(unique(group)) == length(group))
                warning('BDS:set_options:InvalidGroupedDirectionIndices', ...
                    'Each group in options.grouped_direction_indices must be a vector of unique integers between 1 and n. Use default value instead.');
                options = rmfield(options, 'grouped_direction_indices');
                break;
            end
            total_directions = total_directions + length(group);
        end
        if isfield(options, 'grouped_direction_indices') && total_directions ~= n
            warning('BDS:set_options:InvalidGroupedDirectionIndices', ...
                'The total number of directions in options.grouped_direction_indices must equal n. Use default value instead.');
            options = rmfield(options, 'grouped_direction_indices');
        end
    end
end

% block_visiting_pattern
if isfield(options, 'block_visiting_pattern')
    pat_list = ["sorted", "random", "parallel"];
    if ~(ischarstr(options.block_visiting_pattern) ...
        && any(ismember(lower(string(options.block_visiting_pattern)), pat_list)))
        warning('BDS:set_options:InvalidBlockVisitingPattern', ...
            'options.block_visiting_pattern must be one of: sorted, random, parallel. Use default value instead.');
        options = rmfield(options, 'block_visiting_pattern');
    end
end

% alpha_init
if isfield(options, 'alpha_init')
    if ~((isrealscalar(options.alpha_init) && options.alpha_init > 0) || ...
         (isnumvec(options.alpha_init) && all(options.alpha_init > 0) && ...
          isfield(options, 'num_blocks') && ...
          length(options.alpha_init) <= options.num_blocks && ...
          length(options.alpha_init) <= n) || ...
         (ischarstr(options.alpha_init) && strcmpi(options.alpha_init, 'auto')))
        warning('BDS:set_options:InvalidAlphaInit', ...
            "options.alpha_init must be a positive scalar, the string 'auto', or a positive vector with length matching options.num_blocks and not exceeding the problem dimension n. Use default value instead.");
        options = rmfield(options, 'alpha_init');
    end
end

% expand
if isfield(options, 'expand')
    if ~(isrealscalar(options.expand) && options.expand >= 1)
        warning('BDS:set_options:InvalidExpand', ...
            'options.expand must be a real scalar >= 1. Use default value instead.');
        options = rmfield(options, 'expand');
    end
end

% shrink
if isfield(options, 'shrink')
    if ~(isrealscalar(options.shrink) && options.shrink > 0 && options.shrink < 1)
        warning('BDS:set_options:InvalidShrink', ...
            'options.shrink must be a real scalar in (0, 1). Use default value instead.');
        options = rmfield(options, 'shrink');
    end
end

% is_noisy
if isfield(options, 'is_noisy')
    if ~(islogical(options.is_noisy) && isscalar(options.is_noisy))
        warning('BDS:set_options:InvalidIsNoisy', ...
            'options.is_noisy must be a logical scalar. Use default value instead.');
        options = rmfield(options, 'is_noisy');
    end
end

% forcing_function
if isfield(options, 'forcing_function')
    if ~isa(options.forcing_function, 'function_handle')
        warning('BDS:set_options:InvalidForcingFunction', ...
            'options.forcing_function must be a function handle. Use default value instead.');
        options = rmfield(options, 'forcing_function');
    else
        % Test if the function accepts scalar input
        try
            test_input = 1; % Example scalar input
            test_output = options.forcing_function(test_input);
            if ~isscalar(test_output)
                warning('BDS:set_options:InvalidForcingFunction', ...
                    'options.forcing_function must return a scalar for scalar input. Use default value instead.');
                options = rmfield(options, 'forcing_function');
            end
        catch
            warning('BDS:set_options:InvalidForcingFunction', ...
                'options.forcing_function must accept scalar input. Use default value instead.');
            options = rmfield(options, 'forcing_function');
        end
    end
end

% reduction_factor (3-vector with ordering constraints)
if isfield(options, 'reduction_factor')
    if ~(isnumvec(options.reduction_factor) && length(options.reduction_factor) == 3)
        warning('BDS:set_options:InvalidReductionFactor', ...
            'options.reduction_factor must be a 3-dimensional real vector');
    else
        reduction_factor = options.reduction_factor(:);
        if ~(reduction_factor(1) <= reduction_factor(2) && ...
             reduction_factor(2) <= reduction_factor(3) && ...
             reduction_factor(1) >= 0 && reduction_factor(2) > 0)
            warning('BDS:set_options:InvalidReductionFactor', ...
                'options.reduction_factor must satisfy reduction_factor(1) <= reduction_factor(2) <= reduction_factor(3), reduction_factor(1) >= 0, and reduction_factor(2) > 0. Use default value instead.');
            options = rmfield(options, 'reduction_factor');
        end
    end
end

% polling_inner
if isfield(options, 'polling_inner')
    pi_list = ["opportunistic", "complete"];
    if ~(ischarstr(options.polling_inner) ...
        && any(ismember(lower(string(options.polling_inner)), pi_list)))
        warning('BDS:set_options:InvalidPollingInner', ...
            'options.polling_inner must be one of: opportunistic, complete. Use default value instead.');
        options = rmfield(options, 'polling_inner');
    end
end

% cycling_inner
if isfield(options, 'cycling_inner')
    if ~(isintegerscalar(options.cycling_inner) && options.cycling_inner >= 0 && options.cycling_inner <= 3)
        warning('BDS:set_options:InvalidCyclingInner', ...
            'options.cycling_inner must be an integer in {0,1,2,3}. Use default value instead.');
        options = rmfield(options, 'cycling_inner');
    end
end

% seed
if isfield(options, 'seed')
    if ~(isintegerscalar(options.seed) && options.seed >= 0)
        warning('BDS:set_options:InvalidSeed', ...
            'options.seed must be a non-negative integer. Use default value instead.');
        options = rmfield(options, 'seed');
    end
end

% output flags
flag_fields = {'output_xhist','output_alpha_hist','output_block_hist', 'output_grad_hist'};
for k = 1:numel(flag_fields)
    f = flag_fields{k};
    if isfield(options, f)
        if ~(islogical(options.(f)) && isscalar(options.(f)))
            warning('BDS:set_options:InvalidOutputFlag', ...
                'options.%s must be a logical scalar. Use default value instead.', f);
            options = rmfield(options, f);
        end
    end
end

% iprint
if isfield(options, 'iprint')
    if ~(isintegerscalar(options.iprint) && options.iprint >= 0 && options.iprint <= 3)
        warning('BDS:set_options:InvalidIprint', ...
            'options.iprint must be an integer in {0,1,2,3}. Use default value instead.');
        options = rmfield(options, 'iprint');
    end
end

% debug_flag
if isfield(options, 'debug_flag')
    if ~(islogical(options.debug_flag) && isscalar(options.debug_flag))
        warning('BDS:set_options:InvalidDebugFlag', ...
            'options.debug_flag must be a logical scalar. Use default value instead.');
        options = rmfield(options, 'debug_flag');
    end
end

end