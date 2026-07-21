function alpha_init = auto_alpha_init_candidate(x0, StepTolerance, c_x, c_tau)
%AUTO_ALPHA_INIT_CANDIDATE Compute a test-only automatic initial-step candidate.

validate_coefficient(c_x, 'c_x');
validate_coefficient(c_tau, 'c_tau');

if ~(isnumeric(x0) && isreal(x0) && isvector(x0) && ...
        all(isfinite(x0(:))))
    error('auto_alpha_init_candidate:InvalidX0', ...
        'x0 must be a real numeric vector.');
end
if ~(isnumeric(StepTolerance) && isreal(StepTolerance) && ...
        (isscalar(StepTolerance) || isvector(StepTolerance)) && ...
        all(isfinite(StepTolerance(:))) && all(StepTolerance(:) >= 0))
    error('auto_alpha_init_candidate:InvalidStepTolerance', ...
        'StepTolerance must be a nonnegative real scalar or vector.');
end

abs_x0 = abs(x0(:));
step_tolerance = StepTolerance(:);
if isscalar(step_tolerance)
    step_tolerance = repmat(step_tolerance, size(abs_x0));
elseif numel(step_tolerance) ~= numel(abs_x0)
    error('auto_alpha_init_candidate:InvalidStepToleranceLength', ...
        'A vector StepTolerance must have the same length as x0.');
end

alpha_init = max(c_x * abs_x0, c_tau * step_tolerance);
zero_coordinate = (abs_x0 == 0);
alpha_init(zero_coordinate) = max( ...
    1, c_tau * step_tolerance(zero_coordinate));
if any(~isfinite(alpha_init)) || any(alpha_init <= 0)
    error('auto_alpha_init_candidate:InvalidResult', ...
        'The automatic initial steps must be finite and positive.');
end

end

function validate_coefficient(value, name)

if ~(isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value) && value > 0)
    error('auto_alpha_init_candidate:InvalidCoefficient', ...
        '%s must be a finite positive real scalar.', name);
end

end
