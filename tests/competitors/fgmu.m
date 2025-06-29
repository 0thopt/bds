function [xopt, fopt, exitflag, output] = fgmu(fun, x0, options)
% FGMU: Accelerated Random Search Algorithm (Nesterov, 2011) - Black-box Optimization Version
% Inputs:
%   fun: Function handle (accepts x as input, returns scalar function value)
%   x0: Initial point (n-dimensional vector)
%   options: Struct with optional fields:
%       - maxfun: Maximum function evaluations (default = 500 * n)
%       - epsilon: Target accuracy (default = 1e-6)
% Outputs:
%   xopt: Best solution found
%   fopt: Best function value found
%   exitflag: Exit condition flag
%   output: Struct containing optimization history and details

% Set options to an empty structure if it is not provided.
if nargin < 3
    options = struct();
end
n = length(x0);
if isfield(options, 'maxfun')
    maxfun = options.maxfun;
else
    maxfun = 500 * n; % Default maximum function evaluations
end
fhist = zeros(maxfun, 1); % Function value history

x = x0;
v = x0;
% Sequence parameter. In fact, gamma should be greater than or equal to tau, which is the
% strong convexity parameter when function is strongly convex. Here, function is a black-box
% optimization problem, so we set tau = 0. Thus, it is reasonable to set gamma = 1.0.
gamma = 1.0;
% Initialize estimated Lipschitz constant.
L_est = 1.0;
% Initialize smoothness parameter.
mu = min(0.1, 0.01 * norm(x0));

nf = 1;
fopt = fun(x0);
xopt = x0;
fhist(1) = fopt;

% Store previous step information for Lipschitz constant estimation. The reason that we 
% set prev_g_hat to zeros is that we will adjust the Lipschitz constant dynamically from the second iteration.
prev_y = x0;
prev_g_hat = zeros(n, 1);

% main loop
max_iter = maxfun; % Maximum iterations based on function evaluations
for k = 1:max_iter

    % === 1. Compute the extrapolated point y_k ===
    theta = 1/(16*(n+1)^2*L_est);
    alpha = solve_alpha_equation(gamma, theta, 0); % Solve the equation of alpha (tau=0)
    beta = alpha * gamma / (gamma + alpha*0);      % not strongly convex (tau=0)
    y = (1 - beta)*x + beta*v;

    % === 2. Random direction and gradient estimation ===
    u = randn(n, 1); % Standard Gaussian direction
    f_plus = fun(y + mu*u);  % Forward perturbation function value
    nf = nf + 1; % Increment function evaluation count
    fhist(nf) = f_plus; % Store function value history
    if nf >= maxfun
        break; % Stop if maximum function evaluations reached
    end
    f_minus = fun(y - mu*u); % Backward perturbation function value
    nf = nf + 1; % Increment function evaluation count
    fhist(nf) = f_minus; % Store function value history
    if nf >= maxfun
        break; % Stop if maximum function evaluations reached
    end
    g_hat = (f_plus - f_minus)/(2*mu) * u; % Central difference gradient estimation

    % === 3. Update main sequence ===
    h = 1/(4*(n+4)*L_est); % Step size (depends on L_est)
    xnew = y - h * g_hat;

    % === 4. Update momentum sequence ===
    gamma_new = (1 - alpha)*gamma + alpha*0; % gamma_{k+1} (tau=0)
    lambda = alpha*0 / gamma_new; % lambda_k (tau=0)
    v_new = (1 - lambda)*v + lambda*y - (theta/alpha)*g_hat;

    % === 5. Adaptive parameter adjustment ===
    % 5.1 Update Lipschitz estimate (dynamic estimation of smooth function gradient Lipschitz constant)
    if k > 1
        delta_g = norm(g_hat - prev_g_hat);
        delta_y = norm(y - prev_y);
        if delta_y > 1e-10
            L_candidate = delta_g / delta_y;
            % Aggressively update in early iterations, more conservatively in later iterations
            if k < 0.2*max_iter
                L_est = max(L_est, 1.5 * L_candidate);
            else
                L_est = max(L_est, L_candidate);
            end
        end
    end

    % 5.2 Step size backtracking check
    fnew = f(xnew);
    if fnew > fopt - 0.5*h*norm(g_hat)^2
        h = 0.5 * h; % Reduce step size
        xnew = y - h * g_hat; % Recompute
        fnew = f(xnew);
    end

    % 5.3 Smoothness parameter decay (decrease with iterations)
    if mod(k, ceil(sqrt(n))) == 0
        mu = max(0.8*mu, (epsilon^(3/4))/(n^(0.5)*L_est^(0.75)));
    end

    % === 6. Update iteration point ===
    prev_y = y;
    prev_g_hat = g_hat;
    x = xnew;
    v = v_new;
    gamma = gamma_new;

    % Update historical best solution
    if fnew < fopt
        fopt = fnew;
        xopt = xnew;
    end

    % Show progress
    if verbose > 0 && mod(k, verbose) == 0
        fprintf('Iter %5d: fopt = %.6e, L_est = %.2f, mu = %.2e\n',...
            k, fopt, L_est, mu);
    end
end

output.nf = nf; % Number of function evaluations
output.fhist = fhist(1:nf); % Truncate history

end

function alpha = solve_alpha_equation(gamma, theta, tau)
% Solve the equation: alpha^2/theta = (1-alpha)*gamma + alpha*tau
% Transform to quadratic equation: alpha^2 + theta*(tau - gamma)*alpha - theta*gamma = 0
a = 1;
b = theta*(tau - gamma);
c = -theta*gamma;

% Solve quadratic equation (take positive root)
discriminant = b^2 - 4*a*c;
alpha = (-b + sqrt(discriminant))/(2*a);
end