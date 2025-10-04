function [xopt, fopt, exitflag, output] = bdss(fun, x0, options)

% ---------- defaults ----------
if nargin < 3
    options = struct(); 
end
n  = numel(x0);

% outer options
MaxFunctionEvaluations = 500 * n;
MaxIterations = MaxFunctionEvaluations;

% inner options (user may pass more fields; we keep and override only needed)
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
fopt = fun(xopt);
exitflag = 0;

% histories (global)
fhist  = nan(1, MaxFunctionEvaluations);
xhist  = nan(n, MaxFunctionEvaluations);
nf_rem = MaxFunctionEvaluations - 1;        % remaining budget (after initial eval)

grad_hist  = [];                  % collected from BDS outputs
grad_xhist = [];

% record initial point
fhist(1)   = fopt;
xhist(:,1) = xopt;
offset     = 1;
nf_total   = 1;

for iter = 1:MaxIterations
    if nf_rem <= 0
        break; 
    end

    % ========== 1) run one BDS round ==========
    % Pass remaining budget to BDS (conservative: let BDS use what's left; NEWUOA later会再裁剪)
    options_bds.MaxFunctionEvaluations = nf_rem;                               % %% FIX
    [xopt_bds, fopt_bds, exitflag_bds, out_bds] = bds(fun, xopt, options_bds);

    % BDS accounting
    cnt_bds = out_bds.funcCount;

    % append BDS trajectory if provided
    % if isfield(out_bds, 'fhist') && ~isempty(out_bds.fhist)
    %     k = numel(out_bds.fhist);
    %     k = min(k, nf_rem);                        % clip to remaining buffer
    %     fhist(offset+1:offset+k) = out_bds.fhist(1:k);
    %     if isfield(out_bds, 'xhist') && ~isempty(out_bds.xhist)
    %         xhist(:, offset+1:offset+k) = out_bds.xhist(:,1:k);
    %     end
    %     offset   = offset + k;
    %     nf_total = nf_total + k;
    % end
    k = min(numel(out_bds.fhist), nf_rem);  % 直接计算并裁剪到剩余预算
    fhist(offset+1:offset+k) = out_bds.fhist(1:k);
    xhist(:, offset+1:offset+k) = out_bds.xhist(:,1:k);
    offset = offset + k;
    nf_total = nf_total + k;

    nf_rem = nf_rem - cnt_bds;                    % %% FIX: only deduct the new count
    if nf_rem <= 0
        xopt = xopt_bds; 
        fopt = fopt_bds; 
        exitflag = exitflag_bds; 
        break;
    end

    % adopt BDS best point
    xopt = xopt_bds;
    fopt = fopt_bds;

    % collect grads/historical data for subspace
    grad_hist = [grad_hist, out_bds.grad];
    grad_xhist = [grad_xhist, xopt_bds];

    % ========== 2) build subspace basis B (guarded) ==========
    use_newuoa = false;
    B = [];
    if ~isempty(grad_hist) && size(grad_hist,2) >= 1 && ~isempty(grad_xhist) && size(grad_xhist,2) >= 2
        g_last  = grad_hist(:, end);
        dx_last = grad_xhist(:, end) - grad_xhist(:, end-1);
        B = [g_last, dx_last];

        % rank/orth check
        [Q,R] = qr(B,0);                           % %% FIX: orthonormalize
        tolR   = 1e-12 * max(1, norm(R,2));
        rnk    = sum(abs(diag(R)) > tolR);

        if rnk >= 1
            B   = Q(:,1:rnk);
            dim = size(B,2);
            use_newuoa = (dim >= 1);
        end
    end

    if ~use_newuoa
        % cannot form a reliable subspace this round
        if nf_rem <= 0
            break;
        else
            continue;
        end
    end

    % ========== 3) solve subproblem by NEWUOA on subspace ==========
    % prepare NEWUOA budget
    dim = size(B,2);
    maxfun_newuoa = min(500*dim, nf_rem);         % %% FIX: hard cap + remaining
    if maxfun_newuoa <= 0
        break;
    end

    % rhobeg / rhoend sensible defaults if missing
    if ~isfield(options_newuoa,'rhobeg') || isempty(options_newuoa.rhobeg)
        options_newuoa.rhobeg = max(1e-3, min(1, norm(B,2)));  % %% FIX
    end
    if ~isfield(options_newuoa,'rhoend') || isempty(options_newuoa.rhoend)
        options_newuoa.rhoend = max(1e-6, 1e-3*options_newuoa.rhobeg);  % %% FIX
    end
    options_newuoa.maxfun = maxfun_newuoa;
    options_newuoa.output_xhist = true;               % request NEWUOA to output trajectory

    % call NEWUOA in subspace (objective: d ↦ f(xopt + B*d))
    [dopt, fopt_newuoa, ~, out_newuoa] = newuoa( ...
        @(d) fun(xopt + B*d), zeros(dim,1), options_newuoa);   % %% FIX: remove undefined eval_fun

    % accounting for NEWUOA
    cnt_new = out_newuoa.funcCount;
    nf_rem = nf_rem - cnt_new;                       % %% FIX: deduct only new counts

    % append NEWUOA path (projected to R^n)
    if isfield(out_newuoa,'fhist') && ~isempty(out_newuoa.fhist)
        k = numel(out_newuoa.fhist);
        k = min(k, MaxFunctionEvaluations - offset);            % clip to buffer
        fhist(offset+1:offset+k) = out_newuoa.fhist(1:k);
        if isfield(out_newuoa,'xhist') && ~isempty(out_newuoa.xhist)
            X = xopt + B * out_newuoa.xhist(:,1:k);             % ▷ project subspace traj to R^n
            xhist(:, offset+1:offset+k) = X;
        end
        offset   = offset + k;
        nf_total = nf_total + k;
    end

    % accept subspace step
    if fopt_newuoa < fopt
        xopt = xopt + B*dopt;
        fopt = fopt_newuoa;
    end

    if nf_rem <= 0, break; end
end

% ---------- finalize output ----------
output.funcCount = nf_total;
output.fhist     = fhist(1:offset);
output.xhist     = xhist(:,1:offset);
output.remain    = nf_rem;
output.lastIter  = iter;
end
