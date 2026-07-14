function [xopt, fopt, output, trace] = trace_ds_cbds_baseline(fun, true_fun, x0, options)
%TRACE_DS_CBDS_BASELINE reproduces the unaccelerated DS/CBDS path with a trace.

if nargin < 4
    options = struct();
end

x0 = double(x0(:));
n = numel(x0);
options = trace_options(options, n, x0);
maxfun = options.MaxFunctionEvaluations;
alpha_tol = options.StepTolerance;

D = get_direction_set(n, options);
num_blocks = options.num_blocks;
grouped_direction_indices = divide_direction_set(n, num_blocks, options);
alpha_all = options.alpha_init;

xhist = nan(n, maxfun);
noisy_raw_hist = nan(1, maxfun);
noisy_decision_hist = nan(1, maxfun);
true_hist = nan(1, maxfun);
alpha_hist = alpha_all(:);
blocks_hist = nan(1, maxfun);
invalid_points = [];
trace = initialize_trace(n, maxfun - 1);
block_state = initialize_block_state(n, num_blocks, maxfun - 1);

[fbase, fbase_raw, is_valid] = eval_fun(fun, x0);
true_base = true_fun(x0);
nf = 1;
xhist(:, nf) = x0;
noisy_raw_hist(nf) = fbase_raw;
noisy_decision_hist(nf) = fbase;
true_hist(nf) = true_base;
if ~is_valid
    invalid_points = [invalid_points, x0];
end

xbase = x0;
xopt = x0;
fopt = fbase;
fopt_all = nan(1, num_blocks);
xopt_all = nan(n, num_blocks);
num_visited_blocks = 0;
event_count = 0;
iteration = 0;
terminate = false;
exitflag = get_exitflag("MAXIT_REACHED");

if fbase <= options.ftarget
    terminate = true;
    exitflag = get_exitflag("FTARGET_REACHED");
elseif nf >= maxfun
    terminate = true;
    exitflag = get_exitflag("MAXFUN_REACHED");
end

while ~terminate && iteration < maxfun
    iteration = iteration + 1;
    block_indices = 1:num_blocks;

    for i_block = 1:numel(block_indices)
        if terminate || nf >= maxfun
            break;
        end

        block = block_indices(i_block);
        direction_indices = grouped_direction_indices{block};
        alpha_before = alpha_all(block);
        block_base_x = xbase;
        block_base_noisy = fbase;
        block_base_true = true_base;
        sub_xopt = xbase;
        sub_fopt = fbase;
        sub_true_opt = true_base;
        selected_event = 0;
        sufficient_decrease = false;
        inner_terminate = false;
        inner_exitflag = nan;
        block_events = zeros(1, numel(direction_indices));
        n_block_eval = 0;
        max_inner_evaluations = maxfun - nf;
        block_state.visit(num_visited_blocks + 1) = num_visited_blocks + 1;
        block_state.iteration(num_visited_blocks + 1) = iteration;
        block_state.block(num_visited_blocks + 1) = block;
        block_state.evaluation_start(num_visited_blocks + 1) = nf + 1;
        block_state.alpha_before(num_visited_blocks + 1) = alpha_before;
        block_state.base_point_before(:, num_visited_blocks + 1) = block_base_x;
        block_state.base_noisy_before(num_visited_blocks + 1) = block_base_noisy;
        block_state.base_true_before(num_visited_blocks + 1) = block_base_true;

        for polling_order = 1:numel(direction_indices)
            direction_index = direction_indices(polling_order);
            xtrial = block_base_x + alpha_before * D(:, direction_index);
            [ftrial, ftrial_raw, trial_is_valid] = eval_fun(fun, xtrial);
            true_trial = true_fun(xtrial);

            nf = nf + 1;
            event_count = event_count + 1;
            n_block_eval = n_block_eval + 1;
            block_events(n_block_eval) = event_count;
            xhist(:, nf) = xtrial;
            noisy_raw_hist(nf) = ftrial_raw;
            noisy_decision_hist(nf) = ftrial;
            true_hist(nf) = true_trial;
            if ~trial_is_valid
                invalid_points = [invalid_points, xtrial];
            end

            if (ftrial < sub_fopt) || (isnan(sub_fopt) && ~isnan(ftrial))
                sub_xopt = xtrial;
                sub_fopt = ftrial;
                sub_true_opt = true_trial;
                selected_event = event_count;
            end

            trace.evaluation(event_count) = nf;
            trace.iteration(event_count) = iteration;
            trace.block_visit(event_count) = num_visited_blocks + 1;
            trace.block(event_count) = block;
            trace.polling_order(event_count) = polling_order;
            trace.direction_index(event_count) = direction_index;
            trace.coordinate(event_count) = ceil(direction_index / 2);
            trace.sign(event_count) = 1 - 2 * mod(direction_index + 1, 2);
            trace.alpha_before(event_count) = alpha_before;
            trace.base_point_before(:, event_count) = block_base_x;
            trace.trial_point(:, event_count) = xtrial;
            trace.base_noisy_before(event_count) = block_base_noisy;
            trace.trial_noisy(event_count) = ftrial;
            trace.trial_noisy_raw(event_count) = ftrial_raw;
            trace.base_true_before(event_count) = block_base_true;
            trace.trial_true(event_count) = true_trial;
            trace.noisy_success(event_count) = ...
                ftrial + options.reduction_factor(1) * ...
                options.forcing_function(alpha_before) < block_base_noisy;
            trace.true_success(event_count) = ...
                true_trial + options.reduction_factor(1) * ...
                options.forcing_function(alpha_before) < block_base_true;
            trace.is_valid(event_count) = trial_is_valid;

            if ftrial <= options.ftarget || n_block_eval >= max_inner_evaluations
                inner_terminate = true;
                if ftrial <= options.ftarget
                    inner_exitflag = get_exitflag("FTARGET_REACHED");
                else
                    inner_exitflag = get_exitflag("MAXFUN_REACHED");
                end
                break;
            end

            sufficient_decrease = ...
                ftrial + options.reduction_factor(1) * ...
                options.forcing_function(alpha_before) / 2 < block_base_noisy;
            if sufficient_decrease
                direction_indices = cycling(direction_indices, polling_order, ...
                    options.cycling_inner);
                break;
            end
        end

        num_visited_blocks = num_visited_blocks + 1;
        blocks_hist(num_visited_blocks) = block;
        grouped_direction_indices{block} = direction_indices;
        fopt_all(block) = sub_fopt;
        xopt_all(:, block) = sub_xopt;

        update_base = (sub_fopt + options.reduction_factor(1) * ...
            options.forcing_function(alpha_before) < block_base_noisy) ...
            || (isnan(block_base_noisy) && ~isnan(sub_fopt));
        if (sub_fopt + options.reduction_factor(3) * ...
                options.forcing_function(alpha_before) < block_base_noisy) ...
                || (isnan(block_base_noisy) && ~isnan(sub_fopt))
            alpha_all(block) = options.expand * alpha_before;
            step_update_code = int8(1);
        elseif (sub_fopt + options.reduction_factor(2) * ...
                options.forcing_function(alpha_before) >= block_base_noisy) ...
                || (isnan(sub_fopt) && ~isnan(block_base_noisy))
            alpha_all(block) = options.shrink * alpha_before;
            step_update_code = int8(-1);
        else
            step_update_code = int8(0);
        end

        active_events = block_events(1:n_block_eval);
        if selected_event > 0
            trace.selected_trial(selected_event) = true;
            trace.would_update_base(selected_event) = update_base;
        end
        trace.step_update_code(active_events) = step_update_code;
        trace.alpha_after(active_events) = alpha_all(block);

        stop_for_small_alpha = ~inner_terminate && all(alpha_all < alpha_tol);
        if inner_terminate
            terminate = true;
            exitflag = inner_exitflag;
        elseif stop_for_small_alpha
            terminate = true;
            exitflag = get_exitflag("SMALL_ALPHA");
        elseif update_base
            xbase = sub_xopt;
            fbase = sub_fopt;
            true_base = sub_true_opt;
            if selected_event > 0
                trace.accepted(selected_event) = true;
                trace.base_changed(selected_event) = true;
            end
        end

        trace.false_acceptance(active_events) = ...
            trace.accepted(active_events) & ~trace.true_success(active_events);
        trace.false_rejection(active_events) = ...
            ~trace.noisy_success(active_events) & trace.true_success(active_events);

        trace.base_point_after(:, active_events) = repmat(xbase, 1, n_block_eval);
        trace.base_noisy_after(active_events) = fbase;
        trace.base_true_after(active_events) = true_base;
        if terminate
            trace.termination_after_block(active_events(end)) = true;
            trace.exitflag_after_block(active_events(end)) = exitflag;
        end
        block_state.evaluation_end(num_visited_blocks) = nf;
        block_state.selected_evaluation(num_visited_blocks) = ...
            selected_evaluation(trace, selected_event);
        block_state.would_update_base(num_visited_blocks) = ...
            update_base && selected_event > 0;
        block_state.accepted(num_visited_blocks) = ...
            any(trace.accepted(active_events));
        block_state.base_changed(num_visited_blocks) = ...
            any(trace.base_changed(active_events));
        block_state.step_update_code(num_visited_blocks) = step_update_code;
        block_state.alpha_after(num_visited_blocks) = alpha_all(block);
        block_state.base_point_after(:, num_visited_blocks) = xbase;
        block_state.base_noisy_after(num_visited_blocks) = fbase;
        block_state.base_true_after(num_visited_blocks) = true_base;
        block_state.terminated(num_visited_blocks) = terminate;
        if terminate
            block_state.exitflag(num_visited_blocks) = exitflag;
        end
    end

    alpha_hist(:, end + 1) = alpha_all(:); %#ok<AGROW>
    [~, best_block] = min(fopt_all, [], 'omitnan');
    if ~isempty(best_block) && fopt_all(best_block) < fopt
        fopt = fopt_all(best_block);
        xopt = xopt_all(:, best_block);
    end

    if ~terminate && nf >= maxfun
        terminate = true;
        exitflag = get_exitflag("MAXFUN_REACHED");
    elseif ~terminate && all(alpha_all < alpha_tol)
        terminate = true;
        exitflag = get_exitflag("SMALL_ALPHA");
    end
end

trace = truncate_trace(trace, event_count);
trace.block_state = truncate_block_state(block_state, num_visited_blocks);
output.funcCount = nf;
output.xhist = xhist(:, 1:nf);
output.fhist = noisy_raw_hist(1:nf);
output.noisy_decision_fhist = noisy_decision_hist(1:nf);
output.true_fhist = true_hist(1:nf);
output.alpha_hist = alpha_hist;
output.blocks_hist = blocks_hist(1:num_visited_blocks);
output.invalid_points = invalid_points;
output.returned_true_value = true_fun(xopt);
output.best_true_value = min(output.true_fhist, [], 'omitnan');
output.final_base = xbase;
output.final_base_noisy = fbase;
output.final_base_true = true_base;
output.iterations = iteration;
output.exitflag = exitflag;
output.message = exit_message(exitflag);

end

function options = trace_options(options, n, x0)
if ~isfield(options, 'Algorithm') && ~isfield(options, 'num_blocks')
    options.Algorithm = 'cbds';
end
options = set_default(options, 'use_productive_direction_memory', false);
options = set_default(options, 'use_sweep_pattern_direction', false);
options = set_default(options, 'use_momentum_extrapolation', false);
options = set_default(options, 'output_xhist', true);
options = set_default(options, 'output_alpha_hist', true);
options = set_default(options, 'output_block_hist', true);
options = set_default(options, 'decision_source', 'noisy');
options = set_accelerated_bds_options(options, n, x0);

if ~strcmpi(options.decision_source, 'noisy')
    error('trace_ds_cbds_baseline:DecisionSource', ...
        'Stage 6 traces must use the normal noisy decision source.');
end
if options.use_productive_direction_memory || options.use_sweep_pattern_direction ...
        || options.use_momentum_extrapolation
    error('trace_ds_cbds_baseline:AccelerationEnabled', ...
        'The baseline tracer requires all acceleration switches to be off.');
end
if options.batch_size ~= options.num_blocks ...
        || ~strcmpi(options.block_visiting_pattern, 'sorted') ...
        || ~strcmpi(options.polling_inner, 'opportunistic')
    error('trace_ds_cbds_baseline:UnsupportedConfiguration', ...
        'The baseline tracer supports full sorted opportunistic polling only.');
end
if options.use_function_value_stop || options.use_estimated_gradient_stop
    error('trace_ds_cbds_baseline:UnsupportedStoppingTest', ...
        'Optional function-value and estimated-gradient stopping must be off.');
end
end

function trace = initialize_trace(n, n_events)
trace.evaluation = zeros(1, n_events);
trace.iteration = zeros(1, n_events);
trace.block_visit = zeros(1, n_events);
trace.block = zeros(1, n_events);
trace.polling_order = zeros(1, n_events);
trace.direction_index = zeros(1, n_events);
trace.coordinate = zeros(1, n_events);
trace.sign = zeros(1, n_events);
trace.alpha_before = nan(1, n_events);
trace.alpha_after = nan(1, n_events);
trace.base_point_before = nan(n, n_events);
trace.trial_point = nan(n, n_events);
trace.base_point_after = nan(n, n_events);
trace.base_noisy_before = nan(1, n_events);
trace.trial_noisy = nan(1, n_events);
trace.trial_noisy_raw = nan(1, n_events);
trace.base_true_before = nan(1, n_events);
trace.trial_true = nan(1, n_events);
trace.base_noisy_after = nan(1, n_events);
trace.base_true_after = nan(1, n_events);
trace.noisy_success = false(1, n_events);
trace.true_success = false(1, n_events);
trace.selected_trial = false(1, n_events);
trace.would_update_base = false(1, n_events);
trace.accepted = false(1, n_events);
trace.base_changed = false(1, n_events);
trace.false_acceptance = false(1, n_events);
trace.false_rejection = false(1, n_events);
trace.is_valid = false(1, n_events);
trace.step_update_code = zeros(1, n_events, 'int8');
trace.termination_after_block = false(1, n_events);
trace.exitflag_after_block = nan(1, n_events);
end

function state = initialize_block_state(n, num_blocks, max_visits)
state.visit = zeros(1, max_visits);
state.iteration = zeros(1, max_visits);
state.block = zeros(1, max_visits);
state.evaluation_start = zeros(1, max_visits);
state.evaluation_end = zeros(1, max_visits);
state.selected_evaluation = zeros(1, max_visits);
state.alpha_before = nan(1, max_visits);
state.alpha_after = nan(1, max_visits);
state.base_point_before = nan(n, max_visits);
state.base_point_after = nan(n, max_visits);
state.base_noisy_before = nan(1, max_visits);
state.base_noisy_after = nan(1, max_visits);
state.base_true_before = nan(1, max_visits);
state.base_true_after = nan(1, max_visits);
state.accepted = false(1, max_visits);
state.would_update_base = false(1, max_visits);
state.base_changed = false(1, max_visits);
state.step_update_code = zeros(1, max_visits, 'int8');
state.terminated = false(1, max_visits);
state.exitflag = nan(1, max_visits);
end

function trace = truncate_trace(trace, n_events)
names = fieldnames(trace);
for i_name = 1:numel(names)
    name = names{i_name};
    value = trace.(name);
    trace.(name) = value(:, 1:n_events);
end
end

function state = truncate_block_state(state, n_visits)
names = fieldnames(state);
for i_name = 1:numel(names)
    name = names{i_name};
    value = state.(name);
    state.(name) = value(:, 1:n_visits);
end
end

function evaluation = selected_evaluation(trace, event_index)
if event_index > 0
    evaluation = trace.evaluation(event_index);
else
    evaluation = 0;
end
end

function message = exit_message(exitflag)
switch exitflag
    case get_exitflag("FTARGET_REACHED")
        message = "The target of the objective function is reached.";
    case get_exitflag("MAXFUN_REACHED")
        message = "The maximum number of function evaluations is reached.";
    case get_exitflag("MAXIT_REACHED")
        message = "The maximum number of iterations is reached.";
    case get_exitflag("SMALL_ALPHA")
        message = "The StepTolerance of the step size is reached.";
    otherwise
        message = "Unknown exitflag";
end
end

function options = set_default(options, name, value)
if ~isfield(options, name) || isempty(options.(name))
    options.(name) = value;
end
end
