function [xopt, fopt, exitflag, output] = bdss(fun, x0, options)

% ---------- defaults ----------
if nargin < 3
    options = struct(); 
end
n  = numel(x0);

% Set maximum function evaluations for bdss
if isfield(options, 'MaxFunctionEvaluations') && ~isempty(options.MaxFunctionEvaluations)
    MaxFunctionEvaluations = options.MaxFunctionEvaluations;
else
    MaxFunctionEvaluations = 500 * n;
end
MaxIterations = MaxFunctionEvaluations;

% Set dim for subspace
if isfield(options, 'subspace_dim') && ~isempty(options.subspace_dim)
    dim = min(options.subspace_dim, 3);  % cap dim to 3
else
    dim = 3;
end

% Set subspace solver, where 'newuoa' is default
if ~isfield(options,'subsolver') || isempty(options.subsolver)
    subsolver = 'newuoa';
else
    subsolver = lower(string(options.subsolver));
end

% Set options for bds
if isfield(options, 'options_bds')     
    options_bds = options.options_bds;     
else
    options_bds = struct(); 
end

% request BDS to output histories to record
options_bds.gradient_estimation_complete = true;
options_bds.output_xhist = true;

% ---------- state ----------
xopt = x0;
exitflag = 0;

% histories (global)
fhist  = nan(1, MaxFunctionEvaluations);
xhist  = nan(n, MaxFunctionEvaluations);
nf = 0;                          % number of function evaluations used
nf_rem = MaxFunctionEvaluations;        % remaining budget

grad_hist  = [];                  % collected from BDS outputs
grad_xhist = [];

smalld_cnt = 0;                % count of consecutive small steps in subsolver
should_restart_bds = false;  % whether to use the default initial step size in BDS

for iter = 1:MaxIterations

    if nf_rem <= 0
        exitflag = get_exitflag("MAXFUN_REACHED");
        break; 
    end
    
    % ========== 1) run one BDS round ==========
    % Pass remaining budget to BDS (conservative: let BDS use what's left)
    options_bds.MaxFunctionEvaluations = nf_rem;

    if ~should_restart_bds && iter > 1
        options_bds.alpha_init = alpha_final; % warm start BDS with last round's final step size
    end

    [xopt_bds, fopt_bds, exitflag_bds, out_bds] = bds(fun, xopt, options_bds);
    alpha_final = out_bds.alpha_final;
    bds_step = xopt_bds - xopt;
    
    d = xopt_bds - xopt;

    % adopt BDS best point
    xopt = xopt_bds;
    fopt = fopt_bds;

    % BDS accounting
    cnt_bds = out_bds.funcCount;

    % append BDS trajectory if provided
    function_evals_bds = min(numel(out_bds.fhist), nf_rem);
    fhist(nf+1:nf+function_evals_bds) = out_bds.fhist(1:function_evals_bds);
    xhist(:, nf+1:nf+function_evals_bds) = out_bds.xhist(:,1:function_evals_bds);
    nf = nf + function_evals_bds;
    nf_rem = nf_rem - cnt_bds;
    if nf_rem <= 0
        exitflag = get_exitflag("MAXFUN_REACHED");
        break;
    end
    
    % If BDS exits not by complete gradient estimation, terminate bdss
    if ~(exitflag_bds == get_exitflag("gradient_estimation_complete")) 
        exitflag = exitflag_bds;
        break;
    end
    
    % collect grads/historical data for subspace. grad_hist and grad_xhist may be empty.
    if isfield(out_bds, 'grad_hist') && ~isempty(out_bds.grad_hist)
        grad_hist  = [grad_hist, out_bds.grad_hist];
    end
    if isfield(out_bds, 'grad_xhist') && ~isempty(out_bds.grad_xhist)
        grad_xhist = [grad_xhist, out_bds.grad_xhist];
    end

    % ========== 2) build subspace basis B (guarded) ==========
    B = [];
    use_subspace = false;
    if exitflag_bds == get_exitflag("gradient_estimation_complete") && ...
        (~isempty(out_bds.grad_hist) && ~isempty(out_bds.grad_xhist)) && ...
        (size(grad_hist, 2) >= 2 && size(grad_xhist,2) >= 2)
        [B, use_subspace] = def_subspace(d, grad_hist, grad_xhist, dim);
        if ~isempty(B) && use_subspace
            gk = grad_hist(:,end);
            g_sub = norm(B.'*gk);                  % ||B^T g||, a metric consistent with d-space
        end
    end
    
    if isempty(B) || ~use_subspace
        % cannot form a reliable subspace this round
        should_restart_bds = false;
        continue;
    end

    % ========== 3) solve subproblem by subsolver on subspace ==========
    % prepare subsolver budget
    dim = size(B,2);
    maxfun_subsolver = min(500*dim, nf_rem);         % %% FIX: hard cap + remaining
    if maxfun_subsolver <= 0
        exitflag = get_exitflag("MAXFUN_REACHED");
        break;
    end

    subfun = @(d) fun(xopt + B*d);    % subspace objective
    s_step = max(alpha_final);
    s_move = norm(bds_step);
    s_base = max( s_step, min( sqrt(s_step*s_move), 0.25*s_move ) );

    rho_min = max( sqrt(eps) * max(1, norm(xopt)), 1e-12 );
    rho_end = max( 1e-2 * s_base, rho_min );
    rho_beg = max( s_base, 10*rho_end );

    switch char(subsolver)
        case 'newuoa'
            options_newuoa.rhoend = rho_end;      % trust-region radius at termination
            options_newuoa.rhobeg = rho_beg;      % initial trust-region radius
            options_newuoa.maxfun = maxfun_subsolver;
            options_newuoa.output_xhist = true;   % request NEWUOA to output trajectory
            options_newuoa.iprint = 0; 
            % call NEWUOA in subspace (objective: d ↦ f(xopt + B*d))
            [dopt, fopt_subsolver, ~, out_subsolver] = newuoa(subfun, zeros(dim,1), options_newuoa);
        case 'bds'
            options_bds_sub.gradient_estimation_complete = false; % do not need gradient estimation in subsolver
            options_bds_sub.MaxFunctionEvaluations = maxfun_subsolver;
            options_bds_sub.output_xhist = true;              % request BDS to output trajectory
            options_bds_sub.iprint = 0;                       % print BDS output
            % Based on empirical analysis, these parameters provide superior performance 
            % for subspace optimization compared to default BDS settings. The improvement
            % is particularly significant for problems with dimension n ∈ [6,20], where
            % the computational cost of the subsolver is comparable to that of the main BDS
            % iterations. In this dimensional range, dynamic step size adjustment yields
            % substantial efficiency gains. For higher-dimensional problems (n > 20), where
            % the subsolver cost becomes negligible relative to BDS iterations, these
            % parameter modifications produce less pronounced benefits.
            options_bds_sub.alpha_init = rho_beg;            % initial step size
            options_bds_sub.StepTolerance = rho_end;           % termination by step size
            % options_bds_sub.alpha_init = 1;            % initial step size
            % options_bds_sub.StepTolerance = 1e-6;           % termination by step size
            [dopt, fopt_subsolver, ~, out_subsolver] = bds(subfun, zeros(dim,1), options_bds_sub);
        case 'simplex'
            c_fun = 1e-3;
            tolx  = 0.1 * rho_end;
            tolf  = max(c_fun * g_sub * rho_end, 1e-12);
            options_simplex = optimset('Display','off', ...
                            'MaxFunEvals', maxfun_subsolver, ...
                            'MaxIter', 1e12, ...
                            'TolX', tolx, 'TolFun', tolf);
            [dopt, fopt_subsolver, ~, out_subsolver] = fminsearch_with_history(subfun, zeros(dim,1), options_simplex);
        case 'bfgs'
            c_opt = 1e-3;
            options_bfgs = optimoptions("fminunc", ...
                "Algorithm", "quasi-newton", ...
                "HessUpdate", "bfgs", ...
                "MaxFunctionEvaluations", maxfun_subsolver, ...
                "MaxIterations", 10^20, ...
                "StepTolerance", 0.1*rho_end, ...
                "OptimalityTolerance", max(c_opt * g_sub, 1e-12));
            [dopt, fopt_subsolver, ~, out_subsolver] = fminunc_with_history(subfun, zeros(dim,1), options_bfgs);
        otherwise
            error('bdss:unknown_subsolver', 'Unknown subsolver: %s', subsolver);
    end
    
    % accounting for subsolver
    cnt_new = out_subsolver.funcCount;
    nf_rem = nf_rem - cnt_new;

    % append subsolver path (projected to R^n)
    if isfield(out_subsolver,'fhist') && ~isempty(out_subsolver.fhist)
        function_evals_subsolver = numel(out_subsolver.fhist);
        function_evals_to_record = min(function_evals_subsolver, MaxFunctionEvaluations - nf);  % clip to buffer
        fhist(nf+1:nf+function_evals_to_record) = out_subsolver.fhist(1:function_evals_to_record);
        if isfield(out_subsolver,'xhist') && ~isempty(out_subsolver.xhist)
            X = xopt + B * out_subsolver.xhist(:,1:function_evals_to_record);  % ▷ project subspace traj to R^n
            xhist(:, nf+1:nf+function_evals_to_record) = X;
        end
        nf = nf + function_evals_to_record;
    end

    % accept subspace step
    normd = norm(dopt);
    if fopt_subsolver < fopt
        should_restart_bds = true;
        xopt = xopt + B*dopt; 
        fopt = fopt_subsolver;
        % Reset counter on success
        smalld_cnt = 0;                                    
    else
        % No improvement from subsolver, let BDS continue with its own step size strategy
        % in the next iteration.
        should_restart_bds = false;
        if normd <= 0.1 * rho_end
            % Small step but no improvement
            smalld_cnt = smalld_cnt + 1;
        else
            smalld_cnt = 0;
        end
        % Count small steps. If it reaches 3 times, terminate(keep consistent with newuoas)
        if smalld_cnt >= 3
            exitflag = 2; 
            break;
        end
    end

    if nf_rem <= 0
        exitflag = get_exitflag("MAXFUN_REACHED");
        break;
    end
end

% ---------- finalize output ----------
output.funcCount = nf;
output.fhist     = fhist(1:nf);
output.xhist     = xhist(:,1:nf);
output.remain    = nf_rem;
output.lastIter  = iter;

end
