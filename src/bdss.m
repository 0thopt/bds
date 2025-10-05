function [xopt, fopt, exitflag, output] = bdss(fun, x0, options)

% ---------- defaults ----------
if nargin < 3
    options = struct(); 
end
n  = numel(x0);

% outer options
if isfield(options, 'MaxFunctionEvaluations') && ~isempty(options.MaxFunctionEvaluations)
    MaxFunctionEvaluations = options.MaxFunctionEvaluations;
else
    MaxFunctionEvaluations = 500 * n;
end
MaxIterations = MaxFunctionEvaluations;

% BDS / NEWUOA options
if isfield(options, 'options_bds')     
    options_bds = options.options_bds;     
else
    options_bds = struct(); 
end
if isfield(options, 'options_newuoa')  
    options_newuoa  = options.options_newuoa;  
else
    options_newuoa = struct();
end

% request BDS to output histories (for building subspace)
options_bds.subspace     = true;
options_bds.output_xhist = true;

% ---------- state ----------
xopt = x0;
exitflag = 0;

% histories (global)
fhist  = nan(1, MaxFunctionEvaluations);
xhist  = nan(n, MaxFunctionEvaluations);
nf = 0;                          % number of function evaluations used
nf_rem = MaxFunctionEvaluations;        % remaining budget (after initial eval)

grad_hist  = [];                  % collected from BDS outputs
grad_xhist = [];

smalld_cnt = 0;                % count of consecutive small steps in NEWUOA
should_restart_bds = false;  % whether to restart BDS (false)

for iter = 1:MaxIterations

    if nf_rem <= 0
        exitflag = get_exitflag("MAXFUN_REACHED");
        break; 
    end
    
    % ========== 1) run one BDS round ==========
    % Pass remaining budget to BDS (conservative: let BDS use what's left; 
    % NEWUOA will take care of its own budget)
    options_bds.MaxFunctionEvaluations = min(500*n, nf_rem);

    if ~should_restart_bds && iter > 1
        options_bds.alpha_init = alpha_final;  % warm start
    end

    keyboard
    [xopt_bds, fopt_bds, exitflag_bds, out_bds] = bds(fun, xopt, options_bds);
    bds_step = xopt_bds - xopt;
    alpha_final = out_bds.alpha_final;
    keyboard

    d = xopt_bds - xopt;

    % BDS accounting
    cnt_bds = out_bds.funcCount;

    % append BDS trajectory if provided
    function_evals_bds = min(numel(out_bds.fhist), nf_rem);  % 直接计算并裁剪到剩余预算
    fhist(nf+1:nf+function_evals_bds) = out_bds.fhist(1:function_evals_bds);
    xhist(:, nf+1:nf+function_evals_bds) = out_bds.xhist(:,1:function_evals_bds);
    nf = nf + function_evals_bds;

    nf_rem = nf_rem - cnt_bds;
    if nf_rem <= 0
        xopt = xopt_bds; 
        fopt = fopt_bds; 
        exitflag = get_exitflag("MAXFUN_REACHED");
        break;
    end

    % If BDS did not use subspace, exit main loop
    if ~(exitflag_bds == get_exitflag("SUBSPACE")) 
        exitflag = exitflag_bds;
        break;
    end

    % adopt BDS best point
    xopt = xopt_bds;
    fopt = fopt_bds;
    
    % collect grads/historical data for subspace. grad_hist and grad_xhist may be empty.
    if isfield(out_bds, 'grad_hist') && ~isempty(out_bds.grad_hist)
        grad_hist  = [grad_hist, out_bds.grad_hist];
    end
    if isfield(out_bds, 'grad_xhist') && ~isempty(out_bds.grad_xhist)
        grad_xhist = [grad_xhist, out_bds.grad_xhist];
    end

    % ========== 2) build subspace basis B (guarded) ==========
    B = [];
    use_newuoa = false;
    if exitflag_bds == get_exitflag("SUBSPACE") && ...
        (~isempty(out_bds.grad_hist) && ~isempty(out_bds.grad_xhist)) && ...
        (size(grad_hist, 2) >=2 && size(grad_xhist,2) >=2)
        [B, use_newuoa] = def_subspace(d, grad_hist, grad_xhist);
    end

    if isempty(B) || ~use_newuoa
        % cannot form a reliable subspace this round
        should_restart_bds = false;
        continue;
    end

    % ========== 3) solve subproblem by NEWUOA on subspace ==========
    % prepare NEWUOA budget
    dim = size(B,2);
    maxfun_newuoa = min(500*dim, nf_rem);         % %% FIX: hard cap + remaining
    if maxfun_newuoa <= 0
        exitflag = get_exitflag("MAXFUN_REACHED");
        break;
    end

    % rhobeg / rhoend sensible defaults if missing
    if ~isfield(options_newuoa,'rhoend') || isempty(options_newuoa.rhoend)
        options_newuoa.rhoend = max(1e-6, 1e-3*options_newuoa.rhobeg);  % %% FIX
    end
    if ~isfield(options_newuoa,'rhobeg') || isempty(options_newuoa.rhobeg)
        options_newuoa.rhobeg = max(1e-3, min(1, norm(B,2)));  % %% FIX
    end
    options_newuoa.maxfun = maxfun_newuoa;
    options_newuoa.output_xhist = true;               % request NEWUOA to output trajectory
    options_newuoa.iprint = 2;                        % print NEWUOA output
    keyboard
    % call NEWUOA in subspace (objective: d ↦ f(xopt + B*d))
    [dopt, fopt_newuoa, ~, out_newuoa] = newuoa( ...
        @(d) fun(xopt + B*d), zeros(dim,1), options_newuoa);   % %% FIX: remove undefined eval_fun
    keyboard
    % accounting for NEWUOA
    cnt_new = out_newuoa.funcCount;
    nf_rem = nf_rem - cnt_new;                       % %% FIX: deduct only new counts

    % append NEWUOA path (projected to R^n)
    if isfield(out_newuoa,'fhist') && ~isempty(out_newuoa.fhist)
        function_evals_newuoa = numel(out_newuoa.fhist);
        function_evals_to_record = min(function_evals_newuoa, MaxFunctionEvaluations - nf);  % clip to buffer
        fhist(nf+1:nf+function_evals_to_record) = out_newuoa.fhist(1:function_evals_to_record);
        if isfield(out_newuoa,'xhist') && ~isempty(out_newuoa.xhist)
            X = xopt + B * out_newuoa.xhist(:,1:function_evals_to_record);  % ▷ project subspace traj to R^n
            xhist(:, nf+1:nf+function_evals_to_record) = X;
        end
        nf = nf + function_evals_to_record;
    end

    % accept subspace step
    normd = norm(dopt);
    if fopt_newuoa < fopt
        xopt = xopt + B*dopt; 
        fopt = fopt_newuoa;
        smalld_cnt = 0;                                    % 成功就清零
    else
        should_restart_bds = false;                        % 失败就继续 BDS
        if normd <= 0.1*options_newuoa.rhoend              % %% FIX: 小步但无改进
            smalld_cnt = smalld_cnt + 1;
        else
            smalld_cnt = 0;
        end
        if smalld_cnt >= 3                                 % 三次小步退出（与 newuoas 对齐）
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
keyboard
end
