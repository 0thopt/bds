function [xopt, fopt, exitflag, output] = lean_evolved_bds_reference_for_iseqiv(fun, x0, options)
%LEAN_EVOLVED_BDS_REFERENCE_FOR_ISEQIV Reference wrapper for iseqiv checks.
%
% The options argument is intentionally ignored so that this wrapper tests
% the fixed reference behavior of lean_evolved_bds.m.

if nargin < 3
    options = struct();
end
unused_options = options; %#ok<NASGU>

[xopt, fopt, exitflag, output] = lean_evolved_bds(@safe_fun, x0);

    function f = safe_fun(x)
        [f, ~, ~] = eval_fun(fun, x);
    end

end
