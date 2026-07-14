function verification_file = run_stage6_trace_equivalence_gate(output_dir)
%RUN_STAGE6_TRACE_EQUIVALENCE_GATE runs the fixed 180-run Stage 6 gate.

assert(nargin == 1 && (ischar(output_dir) || isstring(output_dir)), ...
    'A single output directory is required.');
output_dir = char(output_dir);
assert(~isempty(output_dir), 'The output directory cannot be empty.');

problem_names = {'FMINSRF2', 'FLETCHCR', 'GENHUMPS', 'COOLHANSLS', ...
    'EXTROSNB', 'DIXON3DQ', 'HILBERTB', 'MSQRTALS', 'SBRYBND'};
noise_levels = [1e-1, 1e-2];
run_indices = 1:5;
options.max_eval_factor = 200;
options.step_tolerance = 1e-6;
options.output_dir = output_dir;

verification_file = verify_trace_ds_cbds_baseline( ...
    problem_names, noise_levels, run_indices, options);
loaded = load(verification_file, 'verification');
verification = loaded.verification;

assert(height(verification) == 180, ...
    'The Stage 6 gate must contain exactly 180 solver-runs.');
assert(all(verification.formal_exact), ...
    'Formal-solver equivalence failed.');
assert(all(verification.trace_internal_exact), ...
    'Internal trace reconstruction failed.');
assert(all(verification.stage3_exact), ...
    'Stage 3 trajectory equivalence failed.');

end
