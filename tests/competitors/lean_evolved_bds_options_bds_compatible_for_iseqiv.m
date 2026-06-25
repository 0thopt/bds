function [xopt, fopt, exitflag, output] = lean_evolved_bds_options_bds_compatible_for_iseqiv(fun, x0, options)
%LEAN_EVOLVED_BDS_OPTIONS_BDS_COMPATIBLE_FOR_ISEQIV All-off Lean wrapper.

if nargin < 3 || isempty(options)
    options = struct();
end

options.use_productive_direction_memory = false;
options.use_sweep_pattern_direction = false;
options.use_momentum_extrapolation = false;

[xopt, fopt, exitflag, output] = lean_evolved_bds_options(fun, x0, options);

end
