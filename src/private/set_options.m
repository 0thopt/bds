function options = set_options(options, x0)

% Get the dimension of the problem.
n = numel(x0);

% Define the list of allowed fields.
field_list = {
    'Algorithm'
    'Scheme'
    'num_blocks'
    'batch_size'
    'MaxFunctionEvaluations'
    'direction_set'
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
    'with_cycling_memory'
    'batch_size'
    'replacement_delay'
    'seed'
    'output_xhist'
    'output_alpha_hist'
    'output_block_hist'
    'verbose'
    'debug_flag'
    };

% Get the field names of options.
field_names = fieldnames(options); % Return a cell array of single-quoted strings.

% Check for unknown fields.
unknown_fields = field_names(~ismember(field_names, field_list));
if ~isempty(unknown_fields)
    % Print each unknown field.
    for i = 1:length(unknown_fields)
        fprintf('Unknown field "%s" is found in options.\n', unknown_fields{i});
    end
    % Display an error message.
    error('There exists unknown field in options.');
else
    % Although the field names are valid, conflicts may arise if the user provides values for certain fields simultaneously.
    % We need to resolve such priority issues to avoid ambiguity.
    if isfield(options, 'Algorithm') 
        if any(isfield(options, {'Scheme', 'num_blocks', 'batch_size'}))
            warning('Algorithm and Scheme/num_blocks/batch_size are mutually exclusive. Algorithm will be used.');
            % Remove Scheme, num_blocks, and batch_size from options.
            options = rmfield(options, intersect(fieldnames(options), {'Scheme', 'num_blocks', 'batch_size'}));
        else
            % Algorithm_list = ["ds", "cbds", "pbds", "rbds", "pads"];
            Algorithm_list = {'ds', 'cbds', 'pbds', 'rbds', 'pads'};
            if isfield(options, 'Algorithm') && ~ismember(lower(options.Algorithm), Algorithm_list)
                error('The Algorithm input is invalid');
            end
            if isfield(options, 'Algorithm')
                options.Algorithm = lower(options.Algorithm);
                switch lower(options.Algorithm)
                    case 'ds'
                        options.num_blocks = 1;
                        options.batch_size = 1;
                    case 'cbds'
                        options.num_blocks = n;
                        options.batch_size = n;
                        options.scheme = 'cyclic';
                    case 'pbds'
                        options.num_blocks = n;
                        options.batch_size = n;
                        options.scheme = 'random';
                    case 'rbds'
                        options.num_blocks = n;
                        options.batch_size = 1;
                        options.replacement_delay = n - 1;
                        options.scheme = 'cyclic';
                    case 'pads'
                        options.num_blocks = n;
                        options.batch_size = n;
                        options.scheme = 'parallel';
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

    % Set the default value of scheme if it is not provided.
    if ~isfield(options, 'scheme')
        options.scheme = 'cyclic';
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
        % n == 1 is treated as a special case, and we can treat the Algorithm as "ds".
        if n == 1 || options.num_blocks == 1
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
        if n == 1 || options.num_blocks == 1
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

    % Remove those fields that will work corporatively with the problem.
    % The fields are: Algorithm, Scheme, num_blocks, direction_set, batch_size, expand, shrink, 
    % replacement_delay, MaxFunctionEvaluations, alpha_init.
    % The above fields are removed from the field_list to avoid setting the default value of them again.
    field_list = setdiff(field_list, {'Algorithm', 'Scheme', 'num_blocks', 'direction_set', 'batch_size', ...
    'expand', 'shrink', 'replacement_delay', 'MaxFunctionEvaluations', 'alpha_init'});
    
    for i = 1:length(field_list)
        field_name = field_list{i};
        if ~isfield(options, field_name)
            % Set the default value of the field if it is not provided or set before.
            % The default value is obtained from the get_default_constant function.
            options.(field_name) = get_default_constant(field_name);
        end
    end
end



