function [B, use_newuoa] = def_subspace(d, grad_hist, grad_xhist)
% define subspace basis B from:
%   (1) last successful step d,
%   (2) negative gradient -g,
%   (3) preconditioned negative gradient -(W*g) using last secant (s,y).
%
% Inputs:
%   d           : last accepted step in R^n (can be zero)
%   grad_hist   : [n x K] gradient history, last col is g_k
%   grad_xhist  : [n x K] point history aligned to grad_hist, last col is x_k
%
% Output:
%   B           : orthonormal basis (n x dim), dim<=3
%   use_newuoa  : true if dim>=1

    Bcols = {};

    % -------- (1) last successful step d --------
    if norm(d) < 1e-10
        B = [];
        use_newuoa = false;
        return;
    else
        nd = norm(d);
        Bcols{end+1} = d / nd;
    end
    
    % -------- (2) negative gradient -g --------
    gk = grad_hist(:,end);
    ng = -gk;
    ngn = norm(ng);
    if ngn < 1e-10
        B = [];
        use_newuoa = false;
        return;
    else
        Bcols{end+1} = ng / ngn;
    end

    % -------- (3) preconditioned negative gradient -(W*g) --------
    % build diagonal W from last secant (s,y):
    %   s = x_k - x_{k-1}, y = g_k - g_{k-1}
    %   diag(H) ~ |y| ./ max(|s|, tolS)   (positive, robust)
    %   W = diag(1 ./ clip(diag(H), hmin, hmax))
    xk   = grad_xhist(:,end);
    xkm1 = grad_xhist(:,end-1);
    gkm1 = grad_hist(:,end-1);

    if norm(xk - xkm1) < 1e-10 && norm(gkm1) < 1e-10
        B = [];
        use_newuoa = false;
        return;
    else
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
        npg = norm(pg);
        if npg < 1e-10
            B = [];
            use_newuoa = false;
            return;
        else
            Bcols{end+1} = pg / npg;
        end
    end

    % -------- assemble & orthonormalize --------
    if isempty(Bcols)
        B = [];
        use_newuoa = false;
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
        use_newuoa = true;
    else
        B = [];
        use_newuoa = false;
    end
end
