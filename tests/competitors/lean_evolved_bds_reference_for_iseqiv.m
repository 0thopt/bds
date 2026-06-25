function [xopt, fopt, exitflag, output] = lean_evolved_bds_reference_for_iseqiv(fun, x0, options)
%LEAN_EVOLVED_BDS_REFERENCE_FOR_ISEQIV Reference wrapper for iseqiv checks.
%
% The options argument is intentionally ignored so that this wrapper tests
% the fixed reference behavior of lean_evolved_bds.m. The output is reduced
% to algorithmic essentials because lean_evolved_bds_options.m follows the
% BDS output contract rather than the legacy Lean output fields.

if nargin < 3
    options = struct();
end
unused_options = options; %#ok<NASGU>

[xopt, fopt, exitflag, output] = lean_evolved_bds(@safe_fun, x0);
output = algorithmic_output_for_iseqiv(output);

    function f = safe_fun(x)
        [f, ~, ~] = eval_fun(fun, x);
    end

end

function output = algorithmic_output_for_iseqiv(raw_output)
output.funcCount = raw_output.funcCount;
end
