function verify_preconditions(fun, x0, options)
%VERIFY_PRECONDITIONS verifies the preconditions for the input arguments of the function.
%

if ~(ischarstr(fun) || isa(fun, "function_handle"))
    error("fun should be a function handle.");
end

if ~isrealvector(x0)
    error("x0 should be a real vector.");
end

if isfield(options, "num_blocks")
    if ~(isintegerscalar(options.num_blocks) && options.num_blocks > 0)
        error("options.num_blocks should be a positive integer.");
    end
end

block_visiting_pattern_list = ["sorted", "random", "parallel"];
if isfield(options, "block_visiting_pattern")
    if ~(ischarstr(options.block_visiting_pattern) && any(ismember(lower(options.block_visiting_pattern), lower(block_visiting_pattern_list))))
        error("options.block_visiting_pattern should be a string in the block_visiting_pattern_list");
    end
end

if isfield(options, "batch_size")
    if ~(isintegerscalar(options.batch_size) && options.batch_size > 0)
        error("options.batch_size should be a positive integer.");
    end
end

if isfield(options, "MaxFunctionEvaluations")
    if ~(isintegerscalar(options.MaxFunctionEvaluations) && options.MaxFunctionEvaluations > 0)
        error("options.MaxFunctionEvaluations should be a positive integer.");
    end
end

if isfield(options, "MaxFunctionEvaluations_factor")
    if ~(isintegerscalar(options.MaxFunctionEvaluations_factor) && options.MaxFunctionEvaluations_factor > 0)
        error("options.MaxFunctionEvaluations_factor should a positive integer.");
    end
end

if isfield(options, "direction_set")
    if ~(ismatrix(options.direction_set) && size(options.direction_set, 1) == length(x0) && size(options.direction_set, 2) == length(x0))
        error("options.direction_set should be a square matrix with the order being the length of x0.");
    end
end

if isfield(options, "is_noisy")
    if ~islogical(options.is_noisy)
        error("options.is_noisy should be a logical value.");
    end
end

if isfield(options, "ds_expand_small")
    if ~(isrealscalar(options.expand) && options.expand >= 1)
        error("options.expand should be a real number greater than or equal to 1.");
    end
end

if isfield(options, "ds_shrink_small")
    if ~(isrealscalar(options.shrink) && options.shrink > 0 && options.shrink < 1)
        error("options.shrink should be a real number in (0, 1).");
    end
end

if isfield(options, "ds_expand_small_noisy")
    if ~(isrealscalar(options.expand) && options.expand >= 1)
        error("options.expand should be a real number greater than or equal to 1.");
    end
end

if isfield(options, "ds_shrink_small_noisy")
    if ~(isrealscalar(options.shrink) && options.shrink > 0 && options.shrink < 1)
        error("options.shrink should be a real number in (0, 1).");
    end
end

if isfield(options, "ds_expand_big")
    if ~(isrealscalar(options.expand) && options.expand >= 1)
        error("options.expand should be a real number greater than or equal to 1.");
    end
end

if isfield(options, "ds_shrink_big")
    if ~(isrealscalar(options.shrink) && options.shrink > 0 && options.shrink < 1)
        error("options.shrink should be a real number in (0, 1).");
    end
end

if isfield(options, "ds_expand_big_noisy")
    if ~(isrealscalar(options.expand) && options.expand >= 1)
        error("options.expand should be a real number greater than or equal to 1.");
    end
end

if isfield(options, "ds_shrink_big_noisy")
    if ~(isrealscalar(options.shrink) && options.shrink > 0 && options.shrink < 1)
        error("options.shrink should be a real number in (0, 1).");
    end
end

if isfield(options, "expand_small")
    if ~(isrealscalar(options.expand) && options.expand >= 1)
        error("options.expand should be a real number greater than or equal to 1.");
    end
end

if isfield(options, "shrink_small")
    if ~(isrealscalar(options.shrink) && options.shrink > 0 && options.shrink < 1)
        error("options.shrink should be a real number in (0, 1).");
    end
end

if isfield(options, "expand_big")
    if ~(isrealscalar(options.expand) && options.expand >= 1)
        error("options.expand should be a real number greater than or equal to 1.");
    end
end

if isfield(options, "shrink_big")
    if ~(isrealscalar(options.shrink) && options.shrink > 0 && options.shrink < 1)
        error("options.shrink should be a real number in (0, 1).");
    end
end

if isfield(options, "expand_big_noisy")
    if ~(isrealscalar(options.expand) && options.expand >= 1)
        error("options.expand should be a real number greater than or equal to 1.");
    end
end

if isfield(options, "shrink_big_noisy")
    if ~(isrealscalar(options.shrink) && options.shrink > 0 && options.shrink < 1)
        error("options.shrink should be a real number in (0, 1).");
    end
end

if isfield(options, "forcing_function")
    if ~isa(options.forcing_function, "function_handle")
        error("options.forcing_function should be a function handle.");
    end
end

if isfield(options, "reduction_factor")
    if ~(isnumvec(options.reduction_factor) && length(options.reduction_factor) == 3)
        error("options.reduction_factor should be a 3-dimensional real vector.");
    end
    if ~(options.reduction_factor(1) <= options.reduction_factor(2) && ...
            options.reduction_factor(2) <= options.reduction_factor(3) && ...
        options.reduction_factor(1) >= 0 && options.reduction_factor(2) > 0)
        error("options.reduction_factor should satisfy the conditions where 0 <= reduction_factor(1) <= reduction_factor(2) <= reduction_factor(3) and reduction_factor(2) > 0.")
    end
end

if isfield(options, "StepTolerance")
    if ~(isrealscalar(options.StepTolerance) && options.StepTolerance >= 0)
        error("options.StepTolerance should be a real number greater than or equal to 0.");
    end
end

if isfield(options, "alpha_init")
    if ~((isrealscalar(options.alpha_init) && options.alpha_init > 0) || ...
        (isnumvec(options.alpha_init) && length(options.alpha_init) == options.     num_blocks && all(options.alpha_init > 0)) || ...
        (ischarstr(options.alpha_init) && strcmpi(options.alpha_init, "auto")))
        error("options.alpha_init should be a positive scalar or a positive real vector with length equal to num_blocks or a string 'auto'.");
    end
end

if isfield(options, "ftarget")
    if ~(isrealscalar(options.ftarget))
        error("options.ftarget should be a real number.");
    end
end

if isfield(options, "polling_inner")
    if ~ischarstr(options.polling_inner)
        error("options.polling_inner should be a string.");
    end
end

if isfield(options, "cycling_inner")
    if ~(isintegerscalar(options.cycling_inner) && options.cycling_inner >= 0 && options.cycling_inner <= 3)
        error("options.cycling_inner should be a nonnegative integer less than or equal to 3.");
    end
end

if isfield(options, "batch_size")
    if ~(isintegerscalar(options.batch_size) && options.batch_size > 0)
        error("options.batch_size should be a positive integer.");
    end
end

if isfield(options, "replacement_delay")
    if ~isintegerscalar(options.replacement_delay)
        error("options.replacement_delay should be an integer.");
    end
end

if isfield(options, "output_xhist")
    if ~islogical(options.output_xhist)
        error("options.output_xhist should be a logical value.");
    end
end

if isfield(options, "output_alpha_hist")
    if ~islogical(options.output_alpha_hist)
        error("options.output_alpha_hist should be a logical value.");
    end
end

if isfield(options, "output_block_hist")
    if ~islogical(options.output_block_hist)
        error("options.output_block_hist should be a logical value.");
    end
end

if isfield(options, "iprint")
    if  ~(isintegerscalar(options.iprint) && options.iprint >= 0 && options.iprint <= 3)
        error("options.iprint should be a nonnegative integer less than or equal to 3.");
    end
end

end
