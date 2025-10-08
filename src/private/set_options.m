function options = set_options(options, x0)

% Get the dimension of the problem.
n = numel(x0);

% Define the list of allowed fields.
field_list = {
    'Algorithm'
    'block_visiting_pattern'
    'num_blocks'
    'batch_size'
    'MaxFunctionEvaluations'
    'direction_set'
    'grouped_direction_indices'
    'block_selection_weight'
    'is_noisy'
    'expand'
    'shrink'
    'forcing_function'
    'reduction_factor'
    'alpha_init'
    'StepTolerance'
    'ftarget'
    'polling_inner'
    'cycling_inner'
    'batch_size'
    'replacement_delay'
    'seed'
    'output_xhist'
    'output_alpha_hist'
    'output_block_hist'
    'output_xhist'
    'iprint'
    'debug_flag'
    'use_function_value_stop'
    'func_window_size'
    'func_tol_1'
    'func_tol_2'
    'use_estimated_gradient_stop'
    'grad_window_size'
    'grad_tol_1'
    'grad_tol_2'
    'gradient_estimation_complete'
    'bb1'
    'bb2'
    'spectral_cauchy'
    'dogleg'
    };

% Get the field names of options.
field_names = fieldnames(options); % Return a cell array of single-quoted strings.

% Check for unknown fields.
unknown_fields = field_names(~ismember(field_names, field_list));
if ~isempty(unknown_fields)
    error('There exists unknown field in options: %s', strjoin(unknown_fields, ', '));
else
    % Although the field names are valid, conflicts may arise if the user provides values for certain fields simultaneously.
    % We need to resolve such priority issues to avoid ambiguity.
    if isfield(options, 'Algorithm')
        Algorithm_list = {'ds', 'cbds', 'pbds', 'rbds', 'pads'};
        if isfield(options, 'Algorithm') && ~ismember(lower(options.Algorithm), Algorithm_list)
            error('The Algorithm input is invalid');
        end
        if any(isfield(options, {'block_visiting_pattern', 'num_blocks', 'batch_size'}))
            warning('Algorithm and block_visiting_pattern/num_blocks/batch_size are mutually exclusive. Algorithm will be used.');
            % Remove block_visiting_pattern, num_blocks, and batch_size from options.
            options = rmfield(options, intersect(fieldnames(options), {'block_visiting_pattern', 'num_blocks', 'batch_size'}));
        else
            if isfield(options, 'Algorithm')
                options.Algorithm = lower(options.Algorithm);
                switch lower(options.Algorithm)
                    case 'ds'
                        options.num_blocks = 1;
                        options.batch_size = 1;
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
                        options.replacement_delay = n - 1;
                        options.block_visiting_pattern = 'sorted';
                    case 'pads'
                        options.num_blocks = n;
                        options.batch_size = n;
                        options.block_visiting_pattern = 'parallel';
                end
            end
        end
        options = rmfield(options, 'Algorithm');
    end

    % Set the value of num_blocks.
    if ~isfield(options, 'num_blocks')
        % If num_blocks is not provided, set it to n, the dimension of the problem.
        options.num_blocks = n;
    end
    % Preprocess the number of blocks.
    if isfield(options, 'num_blocks')
        if options.num_blocks > n
            warning('The number of blocks should be less than or equal to the dimension of the problem.\n');
            warning('The number of blocks is set to be the dimension of the problem.\n');
            options.num_blocks = n;
        end
    end

    % Set the value of batch_size.
    if ~isfield(options, 'batch_size')
        options.batch_size = options.num_blocks;
    end
    % Ensure batch_size does not exceed num_blocks.
    if options.batch_size > options.num_blocks
        warning('The number of batch_size should be less than or equal to the number of blocks.');
        fprintf('\n!!! THE NUMBER OF BATCH_SIZE IS SET TO BE THE NUMBER OF BLOCKS !!!\n');
       options.batch_size = options.num_blocks;
    end

    % Set the default value of block_visiting_pattern if it is not provided.
    if ~isfield(options, 'block_visiting_pattern')
        options.block_visiting_pattern = 'sorted';
    end

    if ~isfield(options, 'block_selection_weight')
        % If block_selection_weight is not provided, let each block have an equal probability of being selected.
        options.block_selection_weight = ones(1, options.num_blocks) / options.num_blocks;
    end

    % Set the default value of is_noisy if it is not provided.
    if ~isfield(options, 'is_noisy')
        options.is_noisy = false;
    end

    % Set the value of expand and shrink based on the dimension of the problem and the Algorithm,
    % and whether the problem is noisy or not. The default values of expand and shrink are
    % selected based on the S2MPJ problems (see https://github.com/GrattonToint/S2MPJ).
    % If options contain expand or shrink, then expand or shrink is set to the corresponding value.
    if ~isfield(options, "expand")
        if options.num_blocks == 1
            if n <= 5
                options.expand = get_default_constant("ds_expand_small");
            else
                % Decide the expand value according to whether the problem is noisy or not.
                if options.is_noisy
                    options.expand = get_default_constant("ds_expand_big_noisy");
                else
                    options.expand = get_default_constant("ds_expand_big");
                end
            end
        else
            if n <= 5
                options.expand = get_default_constant("expand_small");
            else
                if options.is_noisy
                    options.expand = get_default_constant("expand_big_noisy");
                else
                    options.expand = get_default_constant("expand_big");
                end
            end
        end
    else
        options.expand = options.expand;
    end

    if ~isfield(options, "shrink")
        if options.num_blocks == 1
            if n <= 5
                options.shrink = get_default_constant("ds_shrink_small");
            else
                if options.is_noisy
                    options.shrink = get_default_constant("ds_shrink_big_noisy");
                else
                    options.shrink = get_default_constant("ds_shrink_big");
                end
            end
        else
            if n <= 5
                options.shrink = get_default_constant("shrink_small");
            else
                if options.is_noisy
                    options.shrink = get_default_constant("shrink_big_noisy");
                else
                    options.shrink = get_default_constant("shrink_big");
                end
            end
        end
    else
        options.shrink = options.shrink;
    end
    
    % If replacement_delay is r, then the block that is selected in the current
    % iteration will not be selected in the next r iterations. Note that replacement_delay cannot exceed
    % floor(num_blocks/batch_size)-1. The reason we set the default value of replacement_delay to
    % floor(num_blocks/batch_size)-1 is that the performance will be better when replacement_delay is larger.
    if isfield(options, "replacement_delay")
        options.replacement_delay = min(options.replacement_delay, floor(options.num_blocks/options.batch_size)-1);
    else
        options.replacement_delay = floor(options.num_blocks/options.batch_size)-1;
    end

    % Set the maximum number of function evaluations. If the options do not contain MaxFunctionEvaluations,
    % it is set to MaxFunctionEvaluations_dim_factor*n, where n is the dimension of the problem.
    if ~isfield(options, "MaxFunctionEvaluations")
        options.MaxFunctionEvaluations = get_default_constant("MaxFunctionEvaluations_dim_factor")*n;
    end

    % Set the initial step sizes. If options do not contain the field of alpha_init, then the
    % initial step size of each block is set to 1. If alpha_init is a positive scalar, then the initial step
    % size of each block is set to alpha_init. If alpha_init is a vector, then the initial step size
    % of the i-th block is set to alpha_init(i). If alpha_init is "auto", then the initial step size is
    % set according to the coordinates of x0 with respect to the directions in D(:, 1 : 2 : 2*n-1).
    if isfield(options, "alpha_init")
        if isscalar(options.alpha_init)
            options.alpha_init = options.alpha_init * ones(options.num_blocks, 1);
        elseif length(options.alpha_init) == options.num_blocks
            options.alpha_init = options.alpha_init(:);
        % elseif strcmpi(options.alpha_init,"auto")
        %     % x0_coordinates is the coordinates of x0 with respect to the directions in
        %     % D(:, 1 : 2 : 2*n-1), where D(:, 1 : 2 : 2*n-1) is a basis of R^n.
        %     x0_coordinates = D(:, 1 : 2 : 2*n-1) \ x0;
        %     alpha_all = 0.5 * max(1, abs(x0_coordinates));
        end
    else
        options.alpha_init = ones(options.num_blocks, 1);
    end

    % The above procedures handle some fields that depend on problem-specific information and are not 
    % determined solely by user input. To avoid resetting their default values, we remove these fields from options.
    field_list = setdiff(field_list, {'Algorithm', 'block_visiting_pattern', 'num_blocks', 'direction_set', ...
    'block_selection_weight', 'grouped_direction_indices', 'batch_size', 'expand', 'shrink', ...
    'MaxFunctionEvaluations', 'alpha_init', 'replacement_delay'});

    for i = 1:length(field_list)
        field_name = field_list{i};
        if ~isfield(options, field_name)
            % Get the default value of those fields that are not related to the problem information
            % from the get_default_constant function.
            options.(field_name) = get_default_constant(field_name);
        end
    end

    % Initialize alpha_hist if output_alpha_hist is true and alpha_hist does not exceed the
    % maximum memory size allowed.
    if options.output_alpha_hist
        try
            % Test allocation of alpha_hist whether it exceeds the maximum memory size allowed.
            alpha_hist_test = NaN(options.num_blocks, 500*length(x0));
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
            xhist_test = NaN(length(x0), 500*length(x0));
            clear xhist_test
        catch
            options.output_xhist = false;
            warning("xhist will be not included in the output due to the limit of memory.");
        end
    end
end





