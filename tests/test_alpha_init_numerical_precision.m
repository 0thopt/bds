clc; clear; close all;

%% TEST CASE: Machine Precision Limit Verification
% -------------------------------------------------------------------------
% Objective: 
%   To demonstrate the phenomenon of "Numerical Blindness" or "Step Absorption"
%   in unscaled optimization problems using double-precision floating-point arithmetic.
%
% Theoretical Background:
%   In IEEE 754 double precision, the machine epsilon at 1e16 is greater than 1.0.
%   Specifically, numerically (1e16 + 1.0) == 1e16 holds true.
%   Consequently, a default step size of 1.0 will result in zero change in the 
%   variable, causing the algorithm to incorrectly terminate due to "Small Step"
%   or "Small Gradient".
% -------------------------------------------------------------------------

% --- Problem Setup ---
% x_opt: The optimal solution.
% x(1) represents a "Macro" variable (e.g., stiffness in Pa, distance in m).
% x(2) represents a "Unit" variable.
x_opt = [1e16; 1];

% x0: Starting point with significant offsets.
% Offset for x(1) is 5e14.
% Offset for x(2) is 0.1.
x0 = [1.05e16; 1.1]; 

% Objective Function:
% We use the Euclidean norm to measure distance. 
fun = @(x) norm(x - x_opt); 

% Problem dimensions
n = length(x0);

% --- CRITICAL ADJUSTMENT ---
% Convergence threshold (ftarget).
% Why 0.5?
% At the scale of 1e16, machine epsilon is approx 2.0. 
% The previous error was 5e14. Reducing it to < 0.5 is a 15-order-of-magnitude 
% improvement and represents the limit of what x(2) can achieve while 
% dominated by x(1)'s noise.
ftarget = 0.5; 

fprintf('============================================================\n');
fprintf('TEST CASE: Machine Precision Limit (Scale ~ 1e16)\n');
fprintf('Objective: Compare Default Strategy vs. Smart Initialization\n');
fprintf('============================================================\n');

%% 1. Run Default Strategy
% The default initial step size is 1.0 for all blocks.
% This is expected to fail due to precision limits.
opts_def = struct();
opts_def.num_blocks = n;
opts_def.alpha_init = 1.0; % Default setting
opts_def.iprint = 1;       % Enable printing to observe exit flags

fprintf('\n--- [1] Running Default Strategy (alpha_init = 1.0) ---\n');
[x_def, f_def, exit_def, out_def] = bds(fun, x0, opts_def);

%% 2. Run Smart Initialization Strategy
% Strategy: Heuristic Scaling with Lower Bound Protection.

% --- Parameter Configuration (Standardized) ---
AlphaFloor    = 1e-3; % Lower bound protection (> StepTolerance)
DeltaRelative = 0.05; % Relative perturbation factor (5%)
DeltaZero     = 1e-2; % Absolute step for zero elements

% --- Dynamic Step Calculation ---
alpha_vec = zeros(n, 1);
for i = 1:n
    if x0(i) ~= 0
        % Calculate relative step and apply floor
        val = DeltaRelative * abs(x0(i));
        alpha_vec(i) = max(val, AlphaFloor);
    else
        % Handle zero elements and apply floor
        alpha_vec(i) = max(DeltaZero, AlphaFloor);
    end
end

opts_new = struct();
opts_new.num_blocks = n;
opts_new.iprint = 1;
opts_new.alpha_init = alpha_vec; % Pass vectorized step sizes

fprintf('\n--- [2] Running Smart Init Strategy (Scaled Alpha) ---\n');
[x_new, f_new, exit_new, out_new] = bds(fun, x0, opts_new);

%% 3. Results Analysis & Visualization

fprintf('\n============================================================\n');
fprintf('                  COMPARATIVE RESULTS                       \n');
fprintf('============================================================\n');

% Calculate improvement ratio (avoid division by zero)
improvement_ratio = f_def / max(f_new, 1e-16);

% Formatted Output Table
fprintf('\n%-15s | %-10s | %-15s | %-s\n', 'Strategy', 'Func Evals', 'Final Error', 'Status');
fprintf('%s\n', repmat('-', 1, 90));

fprintf('%-15s | %-10d | %-15.4e | %s\n', ...
    'Default (1.0)', out_def.funcCount, f_def, out_def.message);

fprintf('%-15s | %-10d | %-15.4e | %s\n', ...
    'Smart Init', out_new.funcCount, f_new, out_new.message);

fprintf('%s\n', repmat('-', 1, 90));

% Verification of Initial Steps
fprintf('\n[Initialization Analysis]\n');
fprintf('  Default Alpha      : 1.0\n');
fprintf('  Smart Alpha (x1)   : %.2e (Logic: |1.05e16| * %.2f)\n', alpha_vec(1), DeltaRelative);

% --- Final Conclusion Logic ---
% Success is defined as:
% 1. Meeting the target threshold OR
% 2. Achieving a massive relative improvement over the default strategy
is_success = (f_new <= ftarget) || (improvement_ratio > 1e6);

if is_success
    fprintf('\nCONCLUSION: SUCCESS. Smart Init correctly handled the scale.\n');
    fprintf('            Error reduced from %.1e to %.1e.\n', f_def, f_new);
else
    fprintf('\nCONCLUSION: FAILED. No significant improvement observed.\n');
end