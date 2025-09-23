function gradient_accuracy_threshold = get_gradient_accuracy(alpha_all, alpha_tol)

max_alpha = max(alpha_all);
alpha_tol_safe = max(alpha_tol, eps);

% 对数比率 r = log10(max_alpha / alpha_tol)
r = log10(max_alpha / alpha_tol_safe);

% 使用有理映射 w(r) = 1 / (1 + a*r)，保证单调性与数值稳定性
a = 1;            % 控制 r 对权重的影响，越大越快偏向 max_alpha（可调）
w = 1 ./ (1 + a * max(r, 0));

% 限制权重，避免极端值
w = min(0.95, max(0.05, w));

% 在对数域作带权插值（等价于带权几何平均）
log_thr = (1 - w) * log10(max_alpha) + w * log10(alpha_tol_safe);
gradient_accuracy_threshold = 10 ^ log_thr;

% 最低保证：阈值至少为 alpha_tol 的若干倍，避免过小
min_mul = 10;
gradient_accuracy_threshold = max(gradient_accuracy_threshold, min_mul * alpha_tol_safe);

end