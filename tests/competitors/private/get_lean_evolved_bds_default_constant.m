function constant_value = get_lean_evolved_bds_default_constant(constant_name)
%GET_LEAN_EVOLVED_BDS_DEFAULT_CONSTANT Defaults for lean_evolved_bds_options.
%
% These defaults intentionally preserve the reference Lean solver where it
% differs from bds.m. Explicit user options remain authoritative.

switch constant_name
    case "MaxFunctionEvaluations_dim_factor"
        constant_value = 200;
    case "ftarget"
        constant_value = -inf;
    case "StepTolerance"
        constant_value = 1e-6;
    case "block_visiting_pattern"
        constant_value = "sorted";
    case "alpha_init"
        constant_value = 1;
    case "expand"
        constant_value = 2.0;
    case "shrink"
        constant_value = 0.5;
    case "expand_noisy"
        constant_value = 1.5;
    case "shrink_noisy"
        constant_value = 0.5;
    case "is_noisy"
        constant_value = false;
    case "forcing_function"
        constant_value = @(alpha) alpha^2;
    case "reduction_factor"
        constant_value = [0, eps, eps];
    case "polling_inner"
        constant_value = "opportunistic";
    case "cycling_inner"
        constant_value = 1;
    case "output_xhist"
        constant_value = false;
    case "output_alpha_hist"
        constant_value = false;
    case "output_block_hist"
        constant_value = false;
    case "output_grad_hist"
        constant_value = false;
    case "iprint"
        constant_value = 0;
    otherwise
        error("Unknown Lean Evolved BDS constant name '%s'.", constant_name);
end
end
