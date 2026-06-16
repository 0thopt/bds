function [f, g] = chrosen(x) % Chained Rosenbrock function
% This file is cited from https://github.com/libprima/prima/blob/main/matlab/tests/private/chrosen.m, which
% is written by Zaikun Zhang.
%

alpha = 4.0;
f = sum((x(1:end-1)-1).^2 + alpha*(x(2:end) - x(1:end-1).^2).^2);
if nargout >= 2
    n = length(x);
    g = zeros(n, 1);
    for i = 1:n-1
        g(i)   = g(i) + 2*(x(i)-1)-alpha*4*x(i)*(x(i+1)-x(i)^2);
        g(i+1) = g(i+1) + alpha*2*(x(i+1)-x(i)^2);
    end
end
