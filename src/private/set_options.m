function options = set_options(options, n)
% TODO: summary of this function.

% Define the list of allowed fields.
% The order follows the documentation in bds.m.
field_list = {
    'MaxFunctionEvaluations'
    'ftarget'
    'StepTolerance'
    'use_function_value_stop'
    'func_window_size'
    'func_tol'
    'use_estimated_gradient_stop'
    'grad_window_size'
    'grad_tol'
    'Algorithm'
    'direction_set'
    'num_blocks'
    'batch_size'
    'replacement_delay'
    'grouped_direction_indices'
    'block_visiting_pattern'
    'alpha_init'
    'expand'
    'shrink'
    'is_noisy'
    'forcing_function'
    'reduction_factor'
    'polling_inner'
    'cycling_inner'
    'seed'
    'output_xhist'
    'output_alpha_hist'
    'output_block_hist'
    'output_grad_hist'
    'iprint'
    'debug_flag'
    'gradient_estimation_complete' % Internal flag used in bds.m logic
    };

% Get the field names of options and convert to cell array of strings.
field_names = fieldnames(options);
% Check for unknown fields. If any unknown fields are found, throw an error.
% Rationale: Using a warning here might allow the program to continue execution,
% which could lead to unexpected behavior if the user provided incorrect or
% misspelled field names. Additionally, some MATLAB environments or configurations
% might suppress warnings, making it harder for users to identify the issue.
% By throwing an error, we ensure that the user is immediately notified of the
% problem and can correct the input options before proceeding.
unknown_fields = field_names(~ismember(field_names, field_list));
if ~isempty(unknown_fields)
    error('BDS:set_options:UnknownField', ...
        'The following fields in options are not recognized: %s', strjoin(unknown_fields, ', '));
end

% At this point, all fields in options are valid field names, as any unknown fields
% have already caused an error earlier. The next step ensures that
% the values associated with these fields are valid. If any field contains an
% invalid value, the validate_options function will throw an error and terminate
% execution. This strict validation ensures that the options structure is fully
% consistent before proceeding.
options = validate_options(options, n);

% Although the field names are valid and the corresponding values are valid after the above step,
% conflicts may arise if the user provides values for some certain fields simultaneously.
% We need to resolve such priority issues to avoid ambiguity. The following procedures
% handle such conflicts and set default values for missing fields.

% Set the maximum number of function evaluations.
% If the options do not contain MaxFunctionEvaluations,
% it is set to MaxFunctionEvaluations_dim_factor*n, where n is the dimension of the problem.
if ~isfield(options, "MaxFunctionEvaluations")
    options.MaxFunctionEvaluations = get_default_constant("MaxFunctionEvaluations_dim_factor")*n;
end

% We handle Algorithm early because it determines defaults for num_blocks, batch_size, etc.
if isfield(options, 'Algorithm')
    if any(isfield(options, {'block_visiting_pattern', 'num_blocks', 'batch_size'}))
        warning('Algorithm and block_visiting_pattern/num_blocks/batch_size are mutually exclusive. Algorithm will be used.');
        % Remove block_visiting_pattern, num_blocks, and batch_size from options.
        options = rmfield(options, intersect(fieldnames(options), {'block_visiting_pattern', 'num_blocks', 'batch_size'}));
    end
    options.Algorithm = lower(options.Algorithm);
    switch lower(options.Algorithm)
        case 'cbds'
            options.num_blocks = n;
            options.batch_size = n;
            options.block_visiting_pattern = 'sorted';
        case 'pbds'
            options.num_blocks = n;
            options.batch_size = n;
            options.block_visiting_pattern = 'random';
        case 'rbds'
            options.num_blocks = n;
            options.batch_size = 1;
            options.block_visiting_pattern = 'random';
        case 'pads'
            options.num_blocks = n;
            options.batch_size = n;
            options.block_visiting_pattern = 'parallel';
        case 'ds'
            options.num_blocks = 1;
            options.batch_size = 1;
    end
end

% Set the directions.
if ~isfield(options, 'direction_set')
    options.direction_set = eye(n);
end

% Set the number of blocks (num_blocks) if it is not provided.
if ~isfield(options, 'num_blocks')
    options.num_blocks = n;
end

% Note: StepTolerance logic requires options.num_blocks to be defined, so it is placed here
% despite appearing earlier in the comment of bds.m.
% Set the step size threshold for termination. The algorithm terminates when the step size for each 
% block falls below their corresponding threshold.
% If StepTolerance is not provided, it is set to 1e-6 for each block.
% If StepTolerance is a numeric vector, its length must match options.num_blocks.
if isfield(options, "StepTolerance")
    if isscalar(options.StepTolerance)
        options.StepTolerance = options.StepTolerance * ones(options.num_blocks, 1);
    elseif length(options.StepTolerance) == options.num_blocks
        options.StepTolerance = options.StepTolerance(:);
    else
        warning('BDS:set_options:InvalidStepTolerance', ...
            'options.StepTolerance is invalid. Default value (1e-6 for each block) will be used.');
        options.StepTolerance = 1e-6 * ones(options.num_blocks, 1);
    end
else
    options.StepTolerance = 1e-6 * ones(options.num_blocks, 1);
end

% Set the value of batch_size.
if ~isfield(options, 'batch_size')
    options.batch_size = options.num_blocks;
elseif options.batch_size > options.num_blocks
    warning('BDS:set_options:InvalidBatchSize', ...
        'batch_size cannot exceed num_blocks. Set batch_size to num_blocks.');
    options.batch_size = options.num_blocks;
end

% If replacement_delay is r, the block selected in the current iteration will not
% be selected again in the next r iterations.
% While a larger replacement_delay can potentially improve performance, we set it
% to the maximum allowable value to prioritize performance.
% Note that replacement_delay cannot exceed floor(num_blocks/batch_size) - 1.
if isfield(options, "replacement_delay")
    if options.replacement_delay > floor(options.num_blocks/options.batch_size) - 1
        warning('BDS:set_options:ReplacementDelayTooLarge', ...
            'replacement_delay is too large. Setting to the maximum allowable value.');
        options.replacement_delay = floor(options.num_blocks/options.batch_size) - 1;
    end
else
    options.replacement_delay = floor(options.num_blocks/options.batch_size) - 1;
end

% Set the default value of block_visiting_pattern if it is not provided.
if ~isfield(options, 'block_visiting_pattern')
    options.block_visiting_pattern = get_default_constant("block_visiting_pattern");
end

% Set the initial step sizes.
% If options do not contain the field of alpha_init, then the initial step size of each block is set
% to 1. If alpha_init is a positive scalar, then the initial step size of each block is set to 
% alpha_init. If alpha_init is a vector, then the initial step size of the i-th block is set to 
% alpha_init(i). If alpha_init is "auto", then the initial step size is set according to the 
% coordinates of x0 with respect to the directions in D(:, 1 : 2 : 2*n-1).
if isfield(options, "alpha_init")
    if isscalar(options.alpha_init)
        options.alpha_init = options.alpha_init * ones(options.num_blocks, 1);
    elseif length(options.alpha_init) == options.num_blocks
        options.alpha_init = options.alpha_init(:);
    else
        warning('BDS:set_options:InvalidAlphaInitLength', ...
            'options.alpha_init has incompatible length; default value (ones) will be used.');
        options.alpha_init = ones(options.num_blocks, 1);
    % elseif strcmpi(options.alpha_init,"auto")
    %     % x0_coordinates is the coordinates of x0 with respect to the directions in
    %     % D(:, 1 : 2 : 2*n-1), where D(:, 1 : 2 : 2*n-1) is a basis of R^n.
    %     x0_coordinates = D(:, 1 : 2 : 2*n-1) \ x0;
    %     alpha_all = 0.5 * max(1, abs(x0_coordinates));
    end
else
    options.alpha_init = ones(options.num_blocks, 1);
end

% Set whether the objective function is noisy.
% Note: is_noisy determines the defaults for expand and shrink, so it must be set first before
% setting expand and shrink.
if ~isfield(options, 'is_noisy')
    options.is_noisy = get_default_constant("is_noisy");
end

% Set the value of expand and shrink according to the dimension of the problem
% and whether the problem is noisy or not, also according to the Algorithm.
% n == 1 is treated as a special case, and we consider the Algorithm to be "ds".
if (isfield(options, "Algorithm") && (strcmpi(options.Algorithm, "ds"))) || n == 1
    if n <= 5
        expand = get_default_constant("ds_expand_small");
        shrink = get_default_constant("ds_shrink_small");
    else
        % Judge whether the problem is noisy or not.
        if isfield(options, "is_noisy") && options.is_noisy
            expand = get_default_constant("ds_expand_big_noisy");
            shrink = get_default_constant("ds_shrink_big_noisy");
        else
            expand = get_default_constant("ds_expand_big");
            shrink = get_default_constant("ds_shrink_big");
        end
    end
else
    if n <= 5
        expand = get_default_constant("expand_small");
        shrink = get_default_constant("shrink_small");
    else
        % Judge whether the problem is noisy or not.
        if isfield(options, "is_noisy") && options.is_noisy
            expand = get_default_constant("expand_big_noisy");
            shrink = get_default_constant("shrink_big_noisy");
        else
            expand = get_default_constant("expand_big");
            shrink = get_default_constant("shrink_big");
        end
    end
end

% Set the values of options.expand and options.shrink.
% The values of expand and shrink have been determined earlier based on the problem dimension,
% whether the problem is noisy, and the selected Algorithm. If the user has not provided values
% for expand or shrink, the precomputed default values are used. Since the options structure has
% already been validated by remove_invalid_options, any user-provided values are assumed to be valid
% and will not be overwritten.
if ~isfield(options, "expand")
    options.expand = expand;
end
if ~isfield(options, "shrink")
    options.shrink = shrink;
end

% The above procedures handle some fields that depend on problem-specific information and are not
% determined solely by user input.
% We define a list of fields that have been handled manually above.
manual_fields = {'MaxFunctionEvaluations', 'Algorithm', 'direction_set', 'num_blocks', ...
                 'StepTolerance', 'batch_size', 'replacement_delay', 'block_visiting_pattern', ...
                 'alpha_init', 'is_noisy', 'expand', 'shrink', 'grouped_direction_indices'};

% For the remaining fields, set default values using get_default_constant if they are missing.
% We iterate through field_list to maintain the order defined in bds.m.
for i = 1:length(field_list)
    field_name = field_list{i};
    if ~ismember(field_name, manual_fields)
        if ~isfield(options, field_name)
            % Get the default value of those fields that are not related to the problem information
            % from the get_default_constant function.
            options.(field_name) = get_default_constant(field_name);
        end
    end
end

% Initialize alpha_hist if output_alpha_hist is true and alpha_hist does not exceed the
% maximum memory size allowed.
% Both NaN and zero have the same memory allocation in MATLAB, as they are stored
% as double-precision floating-point numbers. For the purpose of memory allocation
% testing, either NaN or zero can be used interchangeably. Here, nan is chosen
% arbitrarily, as the choice does not affect subsequent computations.
if options.output_alpha_hist
    try
        % Test allocation of alpha_hist whether it exceeds the maximum memory size allowed.
        alpha_hist_test = nan(options.num_blocks, options.MaxFunctionEvaluations);
        clear alpha_hist_test
    catch
        options.output_alpha_hist = false;
        warning("alpha_hist will not be included in the output due to the limit of memory.")
    end
end
% If xhist exceeds the maximum memory size allowed, then we will not output xhist.
if  options.output_xhist
    try
        % Test allocation of xhist whether it exceeds the maximum memory size allowed.
        xhist_test = nan(n, options.MaxFunctionEvaluations);
        clear xhist_test
    catch
        options.output_xhist = false;
        warning("xhist will be not included in the output due to the limit of memory.");
    end
end
end