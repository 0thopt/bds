function [x, info, output] = lam(fun, x, lb, ub, options)

    % initialization
    n = length(x);
    nfails = 0;
    if isfield(options, 'tol')
        alfa_stop = options.tol;
    else
        alfa_stop = 1e-6; % default tolerance
    end
    bl = lb;
    bu = ub;
    if isfield(options, 'nf_max')
        nf_max = options.nf_max;
    else
        nf_max = 500 * n; % default maximum function evaluations
    end
    maxiter = nf_max;
    % Initialize the history of function values.
    fhist = NaN(1, nf_max);
    xhist = NaN(n, nf_max);
    if isfield(options, 'iprint')
        iprint = options.iprint;
    else
        iprint = 0; % default print level
    end
    num_fal = 0;
    flag_fail = zeros(1, n);
    % fstop = zeros(1, n+1);
    alfa_d = zeros(1, n);
    d = ones(1, n);
    nf = 0;

    if isfield(options, 'Algorithm')
        Algorithm = options.Algorithm;
    else
        Algorithm = 'LAM1'; % default algorithm. It can be 'LAM', 'LAM1', or 'LAM2'.
    end

    format100 = ' ni=%4d  nf=%5d   f=%12.5e   alfamax=%12.5e\n';

    %---- choice of the starting stepsizes along the directions --------
    for i = 1:n
        % alfa_d(i) = max(1e-3, min(1.0, abs(x(i))));
        % Initialize the step sizes to 1.0 for all directions.
        alfa_d(i) = 1.0;
        if iprint >= 1
            fprintf(' alfainiz(%d)=%e\n', i, alfa_d(i));
        end
    end
    alfa_max = max(alfa_d);
    f = fun(x);
    nf = nf + 1;
    if nf < nf_max
        fhist(nf) = f;
        xhist(:, nf) = x;
    end
    i_corr = 1;
    % fstop(i_corr) = f;

    if strcmpi(Algorithm, 'LAM2')
        icorrbest = -1;
        ficorbest = f;
        xicorbest = x;
    end

    % dm = zeros(1, n);
    xk = x;
    % xk_1 = x;
    fk = f;
    % fk_1 = f;

    %---------------------------
    %     main loop
    %---------------------------
    for ni = 1:maxiter
        if iprint >= 0
            fprintf(format100, ni, nf, f, alfa_max);
        end

        nf_current = nf; % Store the current number of function evaluations

        %-------------------------------------
        %    sampling along coordinate i_corr
        %-------------------------------------
        [alfa, fz, nf, i_corr_fall, ls_output] = linesearchbox_cont(fun, nf_max, Algorithm, ...
    n, x, f, d, alfa_d, i_corr, alfa_max, iprint, bl, bu, nf);
        
        alfa_d = ls_output.alfa_d;
        fhist(nf_current+1:nf_current+length(ls_output.fhist)) = ls_output.fhist;
        xhist(:, nf_current+1:nf_current+length(ls_output.fhist)) = ls_output.xhist;

        % If the step size alpha is large enough, update the solution and function value,
        % and reset the failure flag and counter. For LAM2, also update the best found solution if improved.
        % If alpha is too small, mark as failure and update counters if failures are below threshold.
        if abs(alfa) >= 1e-12
            flag_fail(i_corr) = 0;
            % The same as our implementation of lam, the Algorithm will update x and f after the linesearch.
            if strcmpi(Algorithm, 'LAM') || strcmpi(Algorithm, 'LAM1')
                x(i_corr) = x(i_corr) + alfa * d(i_corr);
                f = fz;
            else
                if fz < ficorbest
                    icorrbest = i_corr;
                    ficorbest = fz;
                    xicorbest = x;
                    xicorbest(i_corr) = x(i_corr) + alfa * d(i_corr);
                end
            end
            % fstop(i_corr) = f;
            num_fal = 0;
            ni = ni + 1;
        else
            flag_fail(i_corr) = 1;
            if i_corr_fall < 2
                % fstop(i_corr) = fz;
                num_fal = num_fal + 1;
                ni = ni + 1;
            end
        end

        % [istop, alfa_max] = stop(obj, n, alfa_d, nf, ni, fstop, f, alfa_stop, nf_max, flag_fail);
        [istop, alfa_max] = stop(n, alfa_d, nf, alfa_stop, nf_max);

        if istop >= 1
            if iprint >= 0
                fprintf(format100, ni, nf, f, alfa_max);
            end
            break;
        end

        % Different from our implementation, the index of the next coordinate is updated here, where
        % it is incremented by 1, and wraps around to 1 if it exceeds n.
        if i_corr < n
            i_corr = i_corr + 1;
        else
            i_corr = 1;
            if strcmpi(Algorithm, 'LAM')
                if norm(xk - x) < 1e-16
                    % the iteration was a failure, reduce the stepsizes
                    for i = 1:n
                        alfa_d(i) = 0.5 * alfa_d(i);
                    end
                end
            end
            if strcmpi(Algorithm, 'LAM2')
                if icorrbest > -1
                    x = xicorbest;
                    f = ficorbest;
                end
            end
            if abs(f - fk) < 1e-5
                nfails = nfails + 1;
            end
            fk = f;
            xk = x;
        end
    end

    if nf < nf_max
        bestf = min(fhist(1:nf));
        fhist(nf+1:nf_max) = bestf;
    end
    info = struct('iters', ni, 'f', f, 'g_norm', max(alfa_d));
    output.fhist = fhist(1:nf);
    output.xhist = xhist(:, 1:nf);
    output.nf = nf;
end