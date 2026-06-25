function [xopt, fopt, exitflag, output] = lean_evolved_bds_options_default_for_iseqiv(fun, x0, options)
%LEAN_EVOLVED_BDS_OPTIONS_DEFAULT_FOR_ISEQIV Default wrapper for iseqiv checks.
%
% The options argument is intentionally ignored so that this wrapper tests
% the default algorithmic behavior of lean_evolved_bds_options.m. The solver
% itself returns BDS-style output; this wrapper reduces output to algorithmic
% essentials for comparison against the legacy Lean reference.

if nargin < 3
    options = struct();
end
unused_options = options; %#ok<NASGU>

[xopt, fopt, exitflag, output] = lean_evolved_bds_options(fun, x0);
output = algorithmic_output_for_iseqiv(output);

end

function output = algorithmic_output_for_iseqiv(raw_output)
output.funcCount = raw_output.funcCount;
end
