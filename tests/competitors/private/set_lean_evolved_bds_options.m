function options = set_lean_evolved_bds_options(options, n, x0)
%SET_LEAN_EVOLVED_BDS_OPTIONS Normalize options for lean_evolved_bds_options.
%
% This helper follows the shape of BDS set_options.m for the fields currently
% supported by lean_evolved_bds_options.m, while keeping Lean's reference
% defaults so that the all-on default path remains equivalent to
% lean_evolved_bds.m.

reject_unsupported_bds_outer_options(options);

options = set_default_if_missing(options, 'MaxFunctionEvaluations', ...
    get_lean_evolved_bds_default_constant("MaxFunctionEvaluations_dim_factor") * n);
options.MaxFunctionEvaluations = normalize_max_function_evaluations(options.MaxFunctionEvaluations);

options = set_default_if_missing(options, 'num_blocks', n);
options.num_blocks = normalize_num_blocks(options.num_blocks, n);
options = set_default_if_missing(options, 'direction_set', eye(n));
options.direction_set = normalize_direction_set(options.direction_set, n);
validate_grouped_direction_indices(options, n, options.num_blocks);

options = set_default_if_missing(options, 'ftarget', get_lean_evolved_bds_default_constant("ftarget"));
options.ftarget = normalize_ftarget(options.ftarget);

options = set_default_if_missing(options, 'StepTolerance', ...
    get_lean_evolved_bds_default_constant("StepTolerance"));
options.StepTolerance = normalize_step_tolerance(options.StepTolerance, options.num_blocks);

options = set_default_if_missing(options, 'alpha_init', ...
    get_lean_evolved_bds_default_constant("alpha_init"));
options.alpha_init = normalize_alpha_init(options.alpha_init, options.num_blocks, n, x0, options.StepTolerance);

options = set_default_if_missing(options, 'is_noisy', ...
    get_lean_evolved_bds_default_constant("is_noisy"));
options.is_noisy = normalize_logical_scalar(options.is_noisy, 'is_noisy');
[default_expand, default_shrink] = lean_expand_shrink_defaults(options.is_noisy);
options = set_default_if_missing(options, 'expand', default_expand);
options.expand = normalize_expand(options.expand);
options = set_default_if_missing(options, 'shrink', default_shrink);
options.shrink = normalize_shrink(options.shrink);

options = set_default_if_missing(options, 'forcing_function', ...
    get_lean_evolved_bds_default_constant("forcing_function"));
options.forcing_function = normalize_forcing_function(options.forcing_function);
options = set_default_if_missing(options, 'reduction_factor', ...
    get_lean_evolved_bds_default_constant("reduction_factor"));
options.reduction_factor = normalize_reduction_factor(options.reduction_factor);

options = set_default_if_missing(options, 'output_xhist', ...
    get_lean_evolved_bds_default_constant("output_xhist"));
options.output_xhist = normalize_logical_scalar(options.output_xhist, 'output_xhist');
options.output_xhist = guard_xhist_memory(options.output_xhist, n, options.MaxFunctionEvaluations);
options = set_default_if_missing(options, 'output_alpha_hist', ...
    get_lean_evolved_bds_default_constant("output_alpha_hist"));
options.output_alpha_hist = normalize_logical_scalar(options.output_alpha_hist, 'output_alpha_hist');
options.output_alpha_hist = guard_alpha_hist_memory( ...
    options.output_alpha_hist, options.num_blocks, options.MaxFunctionEvaluations);
options = set_default_if_missing(options, 'output_block_hist', ...
    get_lean_evolved_bds_default_constant("output_block_hist"));
options.output_block_hist = normalize_logical_scalar(options.output_block_hist, 'output_block_hist');
options = set_default_if_missing(options, 'output_grad_hist', ...
    get_lean_evolved_bds_default_constant("output_grad_hist"));
options.output_grad_hist = normalize_logical_scalar(options.output_grad_hist, 'output_grad_hist');

options = set_default_if_missing(options, 'productive_direction_memory_size', max(1, min(n, 5)));
options.productive_direction_memory_size = normalize_positive_integer( ...
    options.productive_direction_memory_size, 'productive_direction_memory_size');
options = set_default_if_missing(options, 'momentum_decay', 0.6);
options.momentum_decay = normalize_momentum_decay(options.momentum_decay);
options = set_default_if_missing(options, 'use_productive_direction_memory', true);
options.use_productive_direction_memory = normalize_logical_scalar( ...
    options.use_productive_direction_memory, 'use_productive_direction_memory');
options = set_default_if_missing(options, 'use_sweep_pattern_direction', true);
options.use_sweep_pattern_direction = normalize_logical_scalar( ...
    options.use_sweep_pattern_direction, 'use_sweep_pattern_direction');
options = set_default_if_missing(options, 'use_momentum_extrapolation', true);
options.use_momentum_extrapolation = normalize_logical_scalar( ...
    options.use_momentum_extrapolation, 'use_momentum_extrapolation');
end

function options = set_default_if_missing(options, name, value)
if ~isfield(options, name) || isempty(options.(name))
    options.(name) = value;
end
end

function reject_unsupported_bds_outer_options(options)
unsupported = {'batch_size', 'block_visiting_pattern', 'replacement_delay'};
present = intersect(fieldnames(options), unsupported);
if ~isempty(present)
    error('lean_evolved_bds_options:UnsupportedOuterOption', ...
        ['The following BDS outer-loop options are not supported yet: %s. ', ...
        'Use options.num_blocks and options.grouped_direction_indices only.'], ...
        strjoin(present, ', '));
end
end

function MaxFunctionEvaluations = normalize_max_function_evaluations(MaxFunctionEvaluations)
if ~(isintegerscalar(MaxFunctionEvaluations) && MaxFunctionEvaluations > 0)
    error('lean_evolved_bds_options:InvalidMaxFunctionEvaluations', ...
        'options.MaxFunctionEvaluations must be a positive integer.');
end
MaxFunctionEvaluations = double(MaxFunctionEvaluations);
end

function num_blocks = normalize_num_blocks(num_blocks, n)
if ~(isintegerscalar(num_blocks) && num_blocks > 0 && num_blocks <= n)
    error('lean_evolved_bds_options:InvalidNumBlocks', ...
        'options.num_blocks must be a positive integer not exceeding n.');
end
num_blocks = double(num_blocks);
end

function direction_set = normalize_direction_set(direction_set, n)
if ~(ismatrix(direction_set) && size(direction_set, 1) == n && size(direction_set, 2) == n)
    error('lean_evolved_bds_options:InvalidDirectionSet', ...
        'options.direction_set must be an n-by-n matrix.');
end
end

function validate_grouped_direction_indices(options, n, num_blocks)
if ~isfield(options, 'grouped_direction_indices') || isempty(options.grouped_direction_indices)
    return;
end
if ~iscell(options.grouped_direction_indices)
    error('lean_evolved_bds_options:InvalidGroupedDirectionIndices', ...
        'options.grouped_direction_indices must be a cell array.');
end
if numel(options.grouped_direction_indices) ~= num_blocks
    error('lean_evolved_bds_options:InvalidGroupedDirectionIndices', ...
        'The length of options.grouped_direction_indices must equal options.num_blocks.');
end

used_indices = [];
for k = 1:num_blocks
    group = options.grouped_direction_indices{k};
    if ~(isnumeric(group) && isvector(group) && all(isfinite(group)) ...
            && all(group == floor(group)) && all(group >= 1) && all(group <= n) ...
            && numel(unique(group)) == numel(group))
        error('lean_evolved_bds_options:InvalidGroupedDirectionIndices', ...
            ['Each group in options.grouped_direction_indices must contain ', ...
            'unique integer dimension indices between 1 and n.']);
    end
    used_indices = [used_indices, group(:)']; %#ok<AGROW>
end
if numel(used_indices) ~= n || numel(unique(used_indices)) ~= n
    error('lean_evolved_bds_options:InvalidGroupedDirectionIndices', ...
        'options.grouped_direction_indices must partition 1:n exactly once.');
end
end

function ftarget = normalize_ftarget(ftarget)
if ~isrealscalar(ftarget)
    error('lean_evolved_bds_options:InvalidFtarget', ...
        'options.ftarget must be a real scalar.');
end
end

function StepTolerance = normalize_step_tolerance(StepTolerance, num_blocks)
if isscalar(StepTolerance)
    StepTolerance = StepTolerance * ones(num_blocks, 1);
else
    StepTolerance = StepTolerance(:);
end
if numel(StepTolerance) ~= num_blocks || any(StepTolerance < 0)
    error('lean_evolved_bds_options:InvalidStepTolerance', ...
        'options.StepTolerance must be a nonnegative scalar or a num_blocks-vector.');
end
end

function alpha_init = normalize_alpha_init(alpha_init, num_blocks, n, x0, StepTolerance)
if ischarstr(alpha_init) && strcmpi(alpha_init, 'auto')
    if num_blocks ~= n
        error('lean_evolved_bds_options:InvalidAlphaInit', ...
            'options.alpha_init = "auto" is supported only when options.num_blocks equals n.');
    end
    alpha_init = auto_alpha_init(x0, StepTolerance);
    return;
end
if isscalar(alpha_init)
    alpha_init = alpha_init * ones(num_blocks, 1);
else
    alpha_init = alpha_init(:);
end
if numel(alpha_init) ~= num_blocks || any(alpha_init <= 0)
    error('lean_evolved_bds_options:InvalidAlphaInit', ...
        'options.alpha_init must be a positive scalar, a num_blocks-vector, or "auto".');
end
end

function alpha_init = auto_alpha_init(x0, StepTolerance)
n = numel(x0);
alpha_init = zeros(n, 1);
abs_x0 = abs(x0(:));
tau = StepTolerance(:);

nonzero_abs_x0 = abs_x0(abs_x0 > 0);
if isempty(nonzero_abs_x0)
    x0_scale_ratio = 1;
else
    x0_scale_ratio = max(nonzero_abs_x0) / min(nonzero_abs_x0);
end

for i = 1:n
    abs_x0_i = abs_x0(i);
    if abs_x0_i == 0
        alpha_init(i) = 1;
    elseif abs_x0_i <= 1
        alpha_init(i) = max(abs_x0_i, tau(i));
    elseif x0_scale_ratio <= 1e2
        alpha_init(i) = abs_x0_i;
    else
        alpha_init(i) = 1 + log(abs_x0_i);
    end
end
end

function value = normalize_logical_scalar(value, name)
if ~(islogical(value) && isscalar(value))
    error('lean_evolved_bds_options:InvalidLogicalOption', ...
        'options.%s must be a logical scalar.', name);
end
end

function [expand, shrink] = lean_expand_shrink_defaults(is_noisy)
if is_noisy
    expand = get_lean_evolved_bds_default_constant("expand_noisy");
    shrink = get_lean_evolved_bds_default_constant("shrink_noisy");
else
    expand = get_lean_evolved_bds_default_constant("expand");
    shrink = get_lean_evolved_bds_default_constant("shrink");
end
end

function expand = normalize_expand(expand)
if ~(isrealscalar(expand) && expand >= 1)
    error('lean_evolved_bds_options:InvalidExpand', ...
        'options.expand must be a real scalar >= 1.');
end
end

function shrink = normalize_shrink(shrink)
if ~(isrealscalar(shrink) && shrink > 0 && shrink < 1)
    error('lean_evolved_bds_options:InvalidShrink', ...
        'options.shrink must be a real scalar in (0, 1).');
end
end

function forcing_function = normalize_forcing_function(forcing_function)
if ~isa(forcing_function, 'function_handle')
    error('lean_evolved_bds_options:InvalidForcingFunction', ...
        'options.forcing_function must be a function handle.');
end
try
    test_output = forcing_function(1);
catch
    error('lean_evolved_bds_options:InvalidForcingFunction', ...
        'options.forcing_function must accept scalar input.');
end
if ~isscalar(test_output)
    error('lean_evolved_bds_options:InvalidForcingFunction', ...
        'options.forcing_function must return a scalar for scalar input.');
end
end

function reduction_factor = normalize_reduction_factor(reduction_factor)
if ~(isnumvec(reduction_factor) && numel(reduction_factor) == 3)
    error('lean_evolved_bds_options:InvalidReductionFactor', ...
        'options.reduction_factor must be a 3-dimensional real vector.');
end
reduction_factor = reduction_factor(:)';
if ~(reduction_factor(1) <= reduction_factor(2) ...
        && reduction_factor(2) <= reduction_factor(3) ...
        && reduction_factor(1) >= 0 ...
        && reduction_factor(2) > 0)
    error('lean_evolved_bds_options:InvalidReductionFactor', ...
        ['options.reduction_factor must satisfy reduction_factor(1) <= ', ...
        'reduction_factor(2) <= reduction_factor(3), reduction_factor(1) >= 0, ', ...
        'and reduction_factor(2) > 0.']);
end
end

function output_xhist = guard_xhist_memory(output_xhist, n, MaxFunctionEvaluations)
if ~output_xhist
    return;
end
try
    xhist_test = nan(n, MaxFunctionEvaluations);
    clear xhist_test
catch
    output_xhist = false;
    warning('lean_evolved_bds_options:XhistMemory', ...
        'xhist will not be included in the output due to the limit of memory.');
end
end

function output_alpha_hist = guard_alpha_hist_memory(output_alpha_hist, num_blocks, MaxFunctionEvaluations)
if ~output_alpha_hist
    return;
end
try
    alpha_hist_test = nan(num_blocks, MaxFunctionEvaluations);
    clear alpha_hist_test
catch
    output_alpha_hist = false;
    warning('lean_evolved_bds_options:AlphaHistMemory', ...
        'alpha_hist will not be included in the output due to the limit of memory.');
end
end

function value = normalize_positive_integer(value, name)
if ~(isintegerscalar(value) && value > 0)
    error('lean_evolved_bds_options:InvalidPositiveIntegerOption', ...
        'options.%s must be a positive integer.', name);
end
value = double(value);
end

function momentum_decay = normalize_momentum_decay(momentum_decay)
if ~(isrealscalar(momentum_decay) && momentum_decay >= 0 && momentum_decay < 1)
    error('lean_evolved_bds_options:InvalidMomentumDecay', ...
        'options.momentum_decay must be a real scalar in [0, 1).');
end
end
