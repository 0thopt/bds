clc; clear; close all;

% =========================================================================
% Revised Test Scenario: Scale up function value, not coordinates
% Goal: Create a scenario where f > 1e30, while avoiding machine precision 
%       issues with x.
% =========================================================================

% 1. Define objective function: Scaled sum of squares
% When x = 1e6, x^2 = 1e12.
% f(x) = 1e20 * 1e12 = 1e32 (successfully exceeds 1e30).
fun_scaled = @(x) 1e20 * sum(x.^2);

% 2. Set initial point
x0 = [1e6; 1e6]; 

fprintf('========================================\n');
fprintf('Test Scenario: f(x) is huge (1e32), but x is moderate (1e6)\n');
fprintf('Initial point x0: [%.1e, %.1e]\n', x0(1), x0(2));
fprintf('Initial function value f(x0): %.1e\n', fun_scaled(x0));
fprintf('========================================\n\n');

% ------------------------------------------------
% Test 1: Run bds_simplified (Control Group)
% ------------------------------------------------
fprintf('>>> Running bds_simplified...\n');
try
    % As long as there are no precision issues, the simplified version should run normally.
    [xopt_simple, fopt_simple, ~, output_simple] = bds_simplified(fun_scaled, x0);
    
    fprintf('   Result xopt: [%.1e, %.1e]\n', xopt_simple(1), xopt_simple(2));
    fprintf('   Optimal value fopt: %.1e\n', fopt_simple);
    
    if fopt_simple < 1e25 % Success if it decreases significantly
        fprintf('   [Conclusion]: bds_simplified moved successfully.\n');
    else
        fprintf('   [Conclusion]: bds_simplified failed (check for other issues).\n');
    end
catch ME
    fprintf('   Program Error: %s\n', ME.message);
end

fprintf('\n------------------------------------------------\n');

% ------------------------------------------------
% Test 2: Run bds (Verify your modification)
% ------------------------------------------------
fprintf('>>> Running bds (Full Version)...\n');
try
    options = struct();
    options.iprint = 0;
    options.MaxFunctionEvaluations = 1000;
    
    [xopt_bds, fopt_bds, exitflag, output_bds] = bds(fun_scaled, x0, options);
    
    fprintf('   Result xopt: [%.1e, %.1e]\n', xopt_bds(1), xopt_bds(2));
    fprintf('   Optimal value fopt: %.1e\n', fopt_bds);
    fprintf('   Exit flag: %d (%s)\n', exitflag, output_bds.message);
    
    % Judgment logic
    if fopt_bds < 1e25
        fprintf('\n   [Final Conclusion]: bds SUCCESS!\n');
        fprintf('             This proves your eval_fun modification is effective.\n');
        fprintf('             Although f reached 1e32, the algorithm did not truncate it.\n');
    else
        fprintf('\n   [Final Conclusion]: bds FAILED.\n');
        fprintf('             Truncation issue persists, or eval_fun was not saved?\n');
    end
catch ME
    fprintf('   Program Error: %s\n', ME.message);
end