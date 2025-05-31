function [istop, alfa_max] = stop(n, alfa_d, nf, alfa_stop, nf_max)
    istop = 0;
    alfa_max = 0.0;

    % Calculate the maximum step length
    for i = 1:n
        if alfa_d(i) > alfa_max
            alfa_max = alfa_d(i);
        end
    end

    % % Use standard deviation to check convergence
    % if ni >= (n + 1)
    %     ffm = f;
    %     for i = 1:n
    %         ffm = ffm + fstop(i);
    %     end
    %     ffm = ffm / (n + 1);

    %     ffstop = (f - ffm)^2;
    %     for i = 1:n
    %         ffstop = ffstop + (fstop(i) - ffm)^2;
    %     end
    %     ffstop = sqrt(ffstop / (n + 1));
    % end

    % Terminate by step size
    if alfa_max <= alfa_stop
        istop = 1;
    end

    % Terminate by number of function evaluations
    if nf >= nf_max
        istop = 2;
    end
end