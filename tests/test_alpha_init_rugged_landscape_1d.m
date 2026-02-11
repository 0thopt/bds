clc; clear; close all;

%% TEST CASE: The "Rugged Landscape" Problem (Corrected)
% -------------------------------------------------------------------------
% Objective:
%   To demonstrate the benefit of Smart Initialization on "General Scales"
%   (e.g., 1e5) where numerical precision is NOT the issue, but "Local Traps" are.
%
% Theoretical Construction:
%   Global Trend: f_global = (x - 100000)^2
%   Local Trap:   f_local  = A * cos(omega * x)
%
%   Gradient Analysis at Start (x0 = 110000):
%   1. Global Slope: 2 * (110000 - 100000) = 20,000 (Pushing downhill)
%   2. Trap Slope:   A * omega = 4e4 * 1.0 = 40,000 (Resisting motion)
%
%   Since Trap Slope (40,000) > Global Slope (20,000), a small step algorithm
%   (like Default alpha=1.0) will be trapped in the first local minimum.
%   A scaled step algorithm (Smart Init) will step OVER the trap.
% -------------------------------------------------------------------------

% --- Problem Setup ---
% Optimal solution at 100,000 (General engineering scale)
x_opt = 100000;

% Start point at 110,000 (Offset by 10,000)
x0 = 110000;

% Define Function: Quadratic Basin + Deep Ripple Traps
% Increased frequency to 1.0 to ensure Local Gradient > Global Gradient
fun = @(x) (x - x_opt).^2 + 4e4 * (1 - cos(1.0 * (x - x_opt)));

n = length(x0);
% Target: Find the global basin (error < 1000 is considered success here)
% Note: The function value itself will be large due to the quadratic term.

fprintf('============================================================\n');
fprintf('TEST CASE: Rugged Landscape (Scale ~ 1e5)\n');
fprintf('Objective: Escaping Local Minima via Scaled Steps\n');
fprintf('Condition: Local Gradient (40k) > Global Gradient (20k)\n');
fprintf('============================================================\n');

%% 1. Run Default Strategy
opts_def = struct();
opts_def.num_blocks = n;
opts_def.alpha_init = 1.0; % Tiny step relative to ripple wavelength (~6.28)
opts_def.iprint = 1;

fprintf('\n--- [1] Running Default Strategy (alpha = 1.0) ---\n');
[x_def, f_def, exit_def, out_def] = bds(fun, x0, opts_def);

%% 2. Run Smart Initialization Strategy
% Strategy: Heuristic Scaling with Lower Bound Protection.
% Parameters as agreed:
AlphaFloor    = 1e-3;
DeltaRelative = 0.05; 
DeltaZero     = 1e-2;

% Calculate Smart Alpha
alpha_vec = zeros(n, 1);
for i = 1:n
    if x0(i) ~= 0
        % Logic: 5% of 110,000 = 5,500.
        % This step size is much larger than the ripple wavelength (2*pi ~ 6.28).
        val = DeltaRelative * abs(x0(i));
        alpha_vec(i) = max(val, AlphaFloor);
    else
        alpha_vec(i) = max(DeltaZero, AlphaFloor);
    end
end

opts_new = struct();
opts_new.num_blocks = n;
opts_new.alpha_init = alpha_vec;
opts_new.iprint = 1;

fprintf('\n--- [2] Running Smart Init Strategy (Scaled Alpha) ---\n');
[x_new, f_new, exit_new, out_new] = bds(fun, x0, opts_new);

%% 3. Results Analysis & Visualization

fprintf('\n============================================================\n');
fprintf('                  COMPARATIVE RESULTS                       \n');
fprintf('============================================================\n');

% Calculate distance to global optimum
dist_def = abs(x_def - x_opt);
dist_new = abs(x_new - x_opt);

% Define success: Getting within 1% of the optimal value (finding the basin)
is_success_def = dist_def < 1000;
is_success_new = dist_new < 1000;

status_def = "TRAPPED (Local Min)";
if is_success_def, status_def = "SUCCESS (Global Basin)"; end

status_new = "TRAPPED (Local Min)";
if is_success_new, status_new = "SUCCESS (Global Basin)"; end

fprintf('%-15s | %-10s | %-15s | %-s\n', 'Strategy', 'Func Evals', 'Final Distance', 'Result');
fprintf('%s\n', repmat('-', 1, 90));

fprintf('%-15s | %-10d | %-15.4e | %s\n', ...
    'Default (1.0)', out_def.funcCount, dist_def, status_def);

fprintf('%-15s | %-10d | %-15.4e | %s\n', ...
    'Smart Init', out_new.funcCount, dist_new, status_new);

fprintf('%s\n', repmat('-', 1, 90));

fprintf('\n[Mechanism Analysis]\n');
fprintf('  Ripple Wavelength : ~ 6.3 (2*pi/1.0)\n');
fprintf('  Default Step      : 1.0 (Smaller than ripple -> Gets caught)\n');
fprintf('  Smart Step        : %.0f (Larger than ripple -> Steps over)\n', alpha_vec(1));

if ~is_success_def && is_success_new
    fprintf('\nCONCLUSION: SUCCESS. Smart Init successfully escaped the local trap.\n');
else
    fprintf('\nCONCLUSION: Unexpected result. Check gradient calculations.\n');
end