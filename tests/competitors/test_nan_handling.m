clc; clear; close all;

% 1. Define a "trap" function
% Goal: Minimize x(1)^2 + x(2)^2 (Minimum is at the origin)
% Trap: If x(1) > 2, the function directly returns NaN
fun_trap = @(x) conditional_nan(x);

% 2. Set an initial point located in the "bad region" (where function returns NaN)
x0 = [3; 3]; 

fprintf('========================================\n');
fprintf('Test Scenario: Initial point x0 returns NaN\n');
fprintf('Initial point: [%f, %f]\n', x0(1), x0(2));
fprintf('========================================\n\n');

% ------------------------------------------------
% Test 1: Running bds_simplified (without eval_fun protection)
% ------------------------------------------------
fprintf('>>> Running bds_simplified...\n');
try
    [xopt_simple, fopt_simple, ~, output_simple] = bds_simplified(fun_trap, x0);
    fprintf('   Result: xopt = [%f, %f]\n', xopt_simple(1), xopt_simple(2));
    fprintf('   Optimal value fopt = %f\n', fopt_simple);
    fprintf('   Function Evaluations: %d\n', output_simple.funcCount);
    
    if isnan(fopt_simple)
        fprintf('   [Conclusion]: bds_simplified FAILED. Because it cannot compare "fnew < NaN", it did not move a single step.\n');
    end
catch ME
    fprintf('   Program Error: %s\n', ME.message);
end

fprintf('\n------------------------------------------------\n');

% ------------------------------------------------
% Test 2: Running bds (with eval_fun protection)
% ------------------------------------------------
fprintf('>>> Running bds (with eval_fun)...\n');
try
    % Use default options
    options = struct(); 
    options.iprint = 0; % Suppress internal printing for cleaner output
    [xopt_bds, fopt_bds, ~, output_bds] = bds(fun_trap, x0, options);
    
    fprintf('   Result: xopt = [%f, %f]\n', xopt_bds(1), xopt_bds(2));
    fprintf('   Optimal value fopt = %f (True value)\n', fopt_bds);
    fprintf('   Function Evaluations: %d\n', output_bds.funcCount);
    
    if fopt_bds < 1e-5
        fprintf('   [Conclusion]: bds SUCCESS. It treats NaN as Inf (via eval_fun), allowing it to accept the first valid point and converge successfully.\n');
    end
catch ME
    fprintf('   Program Error: %s\n', ME.message);
end

% ------------------------------------------------
% Helper Function Definition
% ------------------------------------------------
function f = conditional_nan(x)
    % If x(1) > 2, return NaN; otherwise, return sum of squares
    % if x(1) > 2
    %     f = nan;
    % else
    %     f = sum(x.^2);
    % end
    if rand > 0.9
        error('Random evaluation failure.');
    else
        f = sum(x.^2);
    end
end