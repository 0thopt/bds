function [B, use_subspace] = def_subspace(d, grad_hist, grad_xhist, dim)
% define subspace basis B from:
%   (1) last successful step d,
%   (2) negative gradient -g,
%   (3) preconditioned negative gradient -(W*g) using last secant (s,y).
%
% Inputs:
%   d           : last accepted step in R^n (can be zero)
%   grad_hist   : [n x K] gradient history, last col is g_k
%   grad_xhist  : [n x K] point history aligned to grad_hist, last col is x_k
%   dim         : max dimension of subspace (1 <= dim <= 3)
%                 If dim = 1, we only use -g;
%                 If dim = 2, we use {d, -g};
%                 If dim = 3, we use {d, -g, -(W*g)}.
%
% Output:
%   B           : orthonormal basis (n x dim), 2<= dim <= 3
%   use_subspace  : true if dim>=1

    Bcols = {};

    n = length(d);
    thr = 10*sqrt(max(n,1))*eps;

    % ----- target set by dim -----
    % dim=1: {-g}; dim=2: {d,-g}; dim=3: {d,-g,-Wg}
    want_d   = (dim >= 2);
    want_pgn = (dim >= 3);

    % (1) last successful step d
    if want_d
        if norm(d) > thr && norm(d) < 1e30
            Bcols{end+1} = d / norm(d);
        end
    end

    % (2) negative gradient -g
    %  We need -g regardless of dim, since it is the most important direction.
    gk = grad_hist(:,end);
    ng = -gk;
    if norm(ng) > thr && norm(ng) < 1e30
        Bcols{end+1} = ng / norm(ng);
    end

    % (3) preconditioned negative gradient -(W*g)
    % build diagonal W from last secant (s,y):
    %   s = x_k - x_{k-1}, y = g_k - g_{k-1}
    %   diag(H) ~ |y| ./ max(|s|, tolS)   (positive, robust)
    %   W = diag(1 ./ clip(diag(H), hmin, hmax))
    if want_pgn && (size(grad_hist,2) >= 2 && size(grad_xhist,2) >= 2)
        xk   = grad_xhist(:,end);
        xkm1 = grad_xhist(:,end-1);
        gkm1 = grad_hist(:,end-1);

        s = xk - xkm1;
        y = gk - gkm1;

        tolS  = 1e-12 * max(1, norm(xk));
        h_raw = abs(y) ./ max(abs(s), tolS);    % elementwise positive 'curvatures'
        hmin  = 1e-8;  hmax = 1e8;
        h     = min(max(h_raw, hmin), hmax);    % clip to [hmin, hmax]
        w     = 1 ./ h;                         % diagonal preconditioner
        wmin  = 1e-8;  wmax = 1e8;
        w     = min(max(w, wmin), wmax);

        pg = -(w .* gk);                        % preconditioned -g
        if norm(pg) > thr && norm(pg) < 1e30
            Bcols{end+1} = pg / norm(pg);
        end
    end

    % -------- assemble & orthonormalize --------
    if isempty(Bcols)
        B = [];
        use_subspace = false;
        return;
    end

    B0 = [Bcols{:}];
    % drop near-duplicate columns before QR
    keep = true(1, size(B0,2));
    for j = 2:size(B0,2)
        for i = 1:j-1
            if keep(i) && abs(B0(:,i)'*B0(:,j)) > 0.9999
                keep(j) = false; break;
            end
        end
    end
    B0 = B0(:, keep);

    [Q,R] = qr(B0, 0);
    tolR  = 1e-12 * max(1, norm(R,2));
    rnk   = sum(abs(diag(R)) > tolR);

    if rnk >= 1
        B = Q(:,1:rnk);
        use_subspace = true;
    else
        B = [];
        use_subspace = false;
    end
    
end
