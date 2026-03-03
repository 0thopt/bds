clc; clear; close all;

% =========================================================================
% Test Scenario: The "Fatal Attraction"
% Goal: Provide an absolute, crystal-clear proof that mapping NaN to Inf 
%       is superior to mapping NaN to 1e30. 
%       
%       In this test, the TRUE global minimum is exactly 0.
%       - The 1e30 version will be lured into a NaN trap, completely miss 
%         the true minimum, and return a massive fake value (1e30).
%       - The Inf version will cleanly reject the trap, descend properly, 
%         and find the absolute true minimum (0).
% =========================================================================

% The objective function: Scaled bowl. True minimum is f(0,0) = 0.
fun_test = @(x) clear_comparison_fun(x);

% Initial point
x0 = [2; 2]; 

fprintf('========================================\n');
fprintf('Test Scenario: True global minimum is f = 0 at [0, 0].\n');
fprintf('Initial point x0: [%.1f, %.1f]\n', x0(1), x0(2));
fprintf('Initial function value f(x0): %.1e\n', 1e31 * sum(x0.^2));
fprintf('Trap condition: If x(1) >= 2.5, function crashes (returns NaN).\n');
fprintf('========================================\n\n');

% ------------------------------------------------
% Test 1: Run bds (NaN replaced by 1e30)
% ------------------------------------------------
fprintf('>>> Running bds (NaN replaced by 1e30)...\n');
try
    options = struct();
    options.iprint = 0;
    options.MaxFunctionEvaluations = 500;
    
    [xopt_bds, fopt_bds, exitflag_bds, output_bds] = bds(fun_test, x0, options);
    
    fprintf('   Result xopt: [%.1f, %.1f]\n', xopt_bds(1), xopt_bds(2));
    fprintf('   Optimal value fopt: %.1e\n', fopt_bds);
    
    if fopt_bds > 1e29
        fprintf('\n   [Conclusion]: bds completely FAILED.\n');
        fprintf('                 It evaluated a NaN, converted it to 1e30.\n');
        fprintf('                 Because 1e30 < 8e31 (its starting value), it thought\n');
        fprintf('                 the NaN crash was a massive improvement!\n');
        fprintf('                 It got stuck in the error zone and entirely missed\n');
        fprintf('                 the true minimum of 0.\n');
    else
        fprintf('\n   [Conclusion]: bds behaved unexpectedly.\n');
    end
catch ME
    fprintf('   Program Error: %s\n', ME.message);
end

fprintf('\n------------------------------------------------\n');

% ------------------------------------------------
% Test 2: Run bds_norma (NaN replaced by Inf)
% ------------------------------------------------
fprintf('>>> Running bds_norma (NaN replaced by Inf)...\n');
try
    options = struct();
    options.iprint = 0;
    options.MaxFunctionEvaluations = 500;
    
    [xopt_norma, fopt_norma, exitflag_norma, output_norma] = bds_norma(fun_test, x0, options);
    
    fprintf('   Result xopt: [%.1f, %.1f]\n', xopt_norma(1), xopt_norma(2));
    fprintf('   Optimal value fopt: %.1e\n', fopt_norma);
    
    if fopt_norma < 1e-5
        fprintf('\n   [Conclusion]: bds_norma absolute SUCCESS!\n');
        fprintf('                 It converted NaN to Inf. Since Inf < 8e31 is False,\n');
        fprintf('                 it correctly rejected the trap as a dead end.\n');
        fprintf('                 It then safely walked downhill and successfully\n');
        fprintf('                 found the TRUE global minimum: 0.\n');
    else
        fprintf('\n   [Conclusion]: bds_norma behaved unexpectedly.\n');
    end
catch ME
    fprintf('   Program Error: %s\n', ME.message);
end

% ------------------------------------------------
% Helper Function Definition
% ------------------------------------------------
function f = clear_comparison_fun(x)
    % The algorithm starts at x(1)=2. If it polls +1 in the x1 direction,
    % it reaches x(1)=3, triggering this trap.
    if x(1) >= 2.5
        f = nan;
    else
        % A steep bowl where normal values easily exceed 1e30
        f = 1e31 * sum(x.^2);
    end
end