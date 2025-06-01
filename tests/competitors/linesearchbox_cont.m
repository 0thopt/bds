function [alfa, fz, nf, i_corr_fall, output] = linesearchbox_cont(fun, MaxFunctionEvaluations, Algorithm, ...
    n, x, f, d, alfa_d, j, alfa_max, iprint, bl, bu, nf, ni)
    
    % In python, variables can be modified without returning them,
    % but in MATLAB, we need to return them explicitly. Thus, we introduce the variable output
    % to hold the output values including alfa, alfa_d, d, x.
    % Also, in matlab, return will directly return the output variable, so we need to set the output variable
    % before the return statement. This is very important!

    z = x;
    % gamma is the sufficient decrease parameter
    gamma = 1e-6;
    % delta is the expanding factor for the step size
    delta = 0.5;
    % delta1 is the shrinking factor for the step size
    delta1 = 0.5;
    % Small step counter for direction reversal. If it is equal to 2, which means the step size is already too small for
    % both d(j) and -d(j), we will not shrink the step size again. Otherwise, we will shrink the step size by multiplying 
    % it with delta.
    i_corr_fall = 0;
    ifront = 0;
    output = struct();

    MaxFunctionEvaluations_exhausted = nf;
    % Adjust the maximum number of function evaluations for the inner LS loop.
    MaxFunctionEvaluations = MaxFunctionEvaluations - nf;
    % Reset the function evaluation counter for the inner LS loop.
    nf = 0;
    fhist = NaN(1, MaxFunctionEvaluations);
    xhist = NaN(n, MaxFunctionEvaluations);

    if iprint >= 1
        fprintf('j =%d    d(j) =%f alfa=%e\n', j, d(j), alfa_d(j));
    end

    % Check if the step size is too relatively small. If so, we set alfa to zero
    % and return the current function value. We want to see the real performance of the algorithm
    % in the case of small step sizes, so we do not stop the algorithm here.
    % if abs(alfa_d(j)) <= 1e-3 * min(1.0, alfa_max)
    %     alfa = 0.0;
    %     if iprint >= 1
    %         fprintf('  alfa piccolo\n');
    %         fprintf(' alfa_d(j)=%e    alfamax=%e\n', alfa_d(j), alfa_max);
    %     end
    %     fz = f;
    %     output.alfa_d = alfa_d;
    %     output.d = d;
    %     output.fhist = fhist(1:nf);
    %     output.xhist = xhist(:, 1:nf);
    %     output.x = z;
    %     return;
    % end

    for ielle = 1:2
        % d is a vector of dimension n, and we are interested in the j-th component here.
        % If d(j) = 1, we are going to check the (0, ..., 0,  1, 0, ..., 0) direction,
        % where the 1 is at the j-th position.
        if d(j) > 0.0
            % If the step size in the positive direction exceeds the upper bound, 
            % set alfa to the maximum allowed value. Otherwise, set alfa to the distance
            % to the upper bound and mark that the boundary is reached.
            % If verbose output is enabled, print a message indicating that the point is on the boundary.
            if (alfa_d(j) - (bu(j) - x(j))) < -1e-6
                % alfa = max(1e-24, alfa_d(j));
                % 1e-10 is corrsponding to the c in the paper: << Worst Case Complexity Bounds for Linesearch-Type
                % Derivative-Free Optimization Algorithms >>.
                alfa = max(1e-10 * alfa_max, alfa_d(j));
            else
                alfa = bu(j) - x(j);
                ifront = 1;
                if iprint >= 1
                    fprintf(' When d(j) > 0.0, the step size already exceeds the upper bound before starting the search, so we set alfa to the maximum allowed value.\n');
                    fprintf(' point on the boundary. *\n');
                end
            end
        else
            % If the step size in the negative direction exceeds the lower bound, set alfa to the maximum 
            % allowed value. Otherwise, set alfa to the distance to the lower bound and mark that the boundary 
            % is reached. If verbose output is enabled, print a message indicating that the point is on the boundary.
            if (alfa_d(j) - (x(j) - bl(j))) < -1e-6
                % alfa = max(1e-24, alfa_d(j));
                % 1e-10 is corrsponding to the c in the paper: << Worst Case Complexity Bounds for Linesearch-Type
                % Derivative-Free Optimization Algorithms >>.
                alfa = max(1e-10 * alfa_max, alfa_d(j));
            else
                alfa = x(j) - bl(j);
                ifront = 1;
                if iprint >= 1
                    fprintf(' When d(j) < 0.0, the step size already exceeds the lower bound before starting the search, so we set alfa to the maximum allowed value.\n');
                    fprintf(' point on the boundary. *\n');
                end
            end
        end

        % If the step size alpha is too small, reverse the direction, increment the small step counter,
        % and set alpha to zero. If verbose output is enabled, print information about the direction 
        % reversal and alpha. Then continue to the next iteration. We want to see the real performance of 
        % the algorithm in the case of small step sizes, so we do not stop the algorithm here.
        % if abs(alfa) <= 1e-3 * min(1.0, alfa_max)
        %     d(j) = -d(j);
        %     i_corr_fall = i_corr_fall + 1;
        %     ifront = 0;
        %     if iprint >= 1
        %         % fprintf(' direzione opposta per alfa piccolo\n');
        %         fprintf(' opposite direction due to small alpha\n');
        %         fprintf(' j =%d    d(j) =%f\n', j, d(j));
        %         fprintf(' alfa=%e    alfamax=%e\n', alfa, alfa_max);
        %     end
        %     alfa = 0.0;
        %     continue;
        % end

        alfaex = alfa;
        z(j) = x(j) + alfa * d(j);
        fz = fun(z);
        nf = nf + 1;
        fhist(nf) = fz;
        xhist(:, nf) = z;
        % Stop the loop if no more function evaluations can be performed. 
        % Note that this should be checked after evaluating the objective function immediately.
        if nf >= MaxFunctionEvaluations
            break;
        end
        if iprint >= 1
            fprintf(' fz =%f   alfa =%e\n', fz, alfa);
        end
        if iprint >= 2
            for ii = 1:n
                fprintf(' z(%d)=%f\n', ii, z(ii));
            end
        end

        fpar = f - gamma * alfa^2;
        % if ni == 317
        %     keyboard
        % end
        if fz < fpar
            % expansion step
            while true
                % If ifront is set to be 1, it means that the first trial point is already on the boundary.
                % In this case, LAM1 or LAM2 will not perform the expansion step, and we will stop the search.
                if ifront == 1
                    if iprint >= 1
                        % fprintf(' accetta punto sulla frontiera fz =%f   alfa =%f\n', fz, alfa);
                        fprintf(' When the first trial point satisfies the sufficient decrease condition and is already on the boundary, we accept it and stop the search.\n');
                        fprintf(' accepted point on the boundary: fz = %f   alfa = %f\n', fz, alfa);
                    end
                    if strcmpi(Algorithm, 'LAM1') || strcmpi(Algorithm, 'LAM2')
                        alfa_d(j) = delta * alfa;
                    end
                    output.d = d;
                    output.alfa_d = alfa_d;
                    output.fhist = fhist(1:nf);
                    output.xhist = xhist(:, 1:nf);
                    nf = nf + MaxFunctionEvaluations_exhausted; % Update the total number of function evaluations
                    return;
                end

                if d(j) > 0.0
                    if (alfa / delta1 - (bu(j) - x(j))) < -1e-6
                        alfaex = alfa / delta1;
                    else
                        alfaex = bu(j) - x(j);
                        ifront = 1;
                        if iprint >= 1
                            fprintf(' When d(j) > 0.0 and the trial point statisfies the sufficient decrease and the step size already exceeds the upper bound, we set alfaex to the maximum allowed value.\n');
                            % fprintf(' punto espan. sulla front.\n');
                            fprintf(' expansion point on the boundary.\n');
                        end
                    end
                else
                    if (alfa / delta1 - (x(j) - bl(j))) < -1e-6
                        alfaex = alfa / delta1;
                    else
                        alfaex = x(j) - bl(j);
                        ifront = 1;
                        if iprint >= 1
                            % fprintf(' punto espan. sulla front.\n');
                            fprintf(' When d(j) < 0.0 and trial point statisfies the sufficient decrease and the step size already exceeds the lower bound, we set alfaex to the maximum allowed value.\n');
                            fprintf(' expansion point on the boundary.\n');
                        end
                    end
                end

                z(j) = x(j) + alfaex * d(j);
                fzdelta = fun(z);
                nf = nf + 1;
                fhist(nf) = fzdelta;
                xhist(:, nf) = z;
                % Stop the loop if no more function evaluations can be performed. 
                % Note that this should be checked after evaluating the objective function immediately.
                if nf >= MaxFunctionEvaluations
                    break;
                end

                if iprint >= 1
                    fprintf(' fzex=%f  alfaex=%f\n', fzdelta, alfaex);
                end
                % keyboard
                % Very important note: the original code has a bug here!!!
                % Since the Algorithm has already accepted the first trial point,
                % it should check the sufficient decrease condition with respect to the first trial point,
                % not the original function value f. Another important note is that
                % the sufficient decrease condition should use the step size alfa, not alfaex. The reason is that
                % we should use the distance between z and its neighbour point and the distance should be
                % (expand-1) * alfa, not (expand-1) * alfaex. In the original code, expand is set to be 1, so
                % the disance is just alfa.
                % fpar = f - gamma * alfaex^2;
                % fpar = fz - gamma * alfaex^2;
                fpar = fz - gamma * alfa^2;
                % if ni == 129
                %     keyboard
                % end
                % keyboard
                if fzdelta < fpar
                    fz = fzdelta;
                    alfa = alfaex;
                else
                    % For LAM1 and LAM2, the step size update for each direction depends only on its own performance,
                    % and is not affected by the performance of other directions.
                    if strcmpi(Algorithm, 'LAM1') || strcmpi(Algorithm, 'LAM2')
                        alfa_d(j) = delta * alfa;
                    end
                    if iprint >= 1
                        % fprintf(' accetta punto fz =%f   alfa =%f\n', fz, alfa);
                        fprintf(' The while loop is exited because the trial point does not satisfy the sufficient decrease condition.\n');
                        % fprintf(' accepted point on the boundary: fz = %f   alfa = %f\n', fz, alfa);
                    end
                    % The following line is important, as the Algorithm will use the latest alfa when it 
                    % visits the direction j again. The original code does include this line, which is a bug
                    % and will cause the Algorithm to use the wrong step size in the next iteration.
                    alfa_d(j) = alfa;
                    output.d = d;
                    output.alfa_d = alfa_d;
                    output.fhist = fhist(1:nf);
                    output.xhist = xhist(:, 1:nf);
                    nf = nf + MaxFunctionEvaluations_exhausted; % Update the total number of function evaluations
                    % keyboard
                    return;
                end
            end
        else
            % opposite direction
            d(j) = -d(j);
            ifront = 0;
            if iprint >= 1
                % fprintf(' direzione opposta\n');
                fprintf(' opposite direction\n');
                fprintf(' j =%d    d(j) =%f\n', j, d(j));
            end
        end
    end

    % 
    % if strcmpi(Algorithm, 'LAM1') || strcmpi(Algorithm, 'LAM2')
    %     % If the step size is too small, reverse the direction, increment
    %     if i_corr_fall ~= 2
    %         alfa_d(j) = delta * alfa_d(j);
    %     end
    % end

    alfa = 0.0;
    fz = f;
    if iprint >= 1
        fprintf(' failure along the direction\n');
    end
    if strcmpi(Algorithm, 'LAM1') || strcmpi(Algorithm, 'LAM2')
        alfa_d(j) = delta * alfa_d(j);
    end
    output.d = d;
    output.alfa_d = alfa_d;
    output.fhist = fhist(1:nf);
    output.xhist = xhist(:, 1:nf);
    nf = nf + MaxFunctionEvaluations_exhausted; % Update the total number of function evaluations

end