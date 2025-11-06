function [f, grad] = cbds_counterexample_backup(x)
% CBDS_COUNTEREXAMPLE  强化硬核版：让 CBDS 在 StepTolerance 停机时的真实梯度更大
% 只接受 x (2x1 或 1x2)，第二输出为解析真梯度 grad (2x1)。
%
% 结构：二次底座 + 各向线性偏置 + 连续带状“抹平” + x/y 双齿（两段带各一齿）。
% 目标：步长缩到容差，但真实梯度保持明显非零（~1e-2~1e-1 甚至更高）。

    % ===== 参数（比上一版更硬） =====
    mu   = 1.5;     % 二次底座强度
    g0x  = 0.25;    % 线性偏置（x）
    g0y  = 0.25;    % 线性偏置（y）

    % 管状带宽（覆盖更广的 x≈1 与 y≈1 邻域）
    R    = 0.45;

    % 抹平触发区间：|x-1|、|y-1| ∈ [Slo, Shi]
    Slo  = 0.05;
    Shi  = 0.42;

    % 底座极小点（约 1 - g0/mu）
    x0_star = 1 - g0x/mu;   % ≈ 0.8333
    y0_star = 1 - g0y/mu;   % ≈ 0.8333

    % 双齿中心与带宽（两个相邻带，覆盖更宽）
    band_half1 = 0.08;
    band_half2 = 0.12;
    xband1 = x0_star;                 % 第一齿中心（约 0.8333）
    xband2 = 0.5*(x0_star+1);         % 第二齿中心偏向 1（约 0.9167）
    yband1 = y0_star;
    yband2 = 0.5*(y0_star+1);

    % 齿强度（显著抬高两个分量的偏导）
    tooth_amp_x1 = 0.30;  % x-齿1
    tooth_amp_x2 = 0.30;  % x-齿2
    tooth_amp_y1 = 0.30;  % y-齿1
    tooth_amp_y2 = 0.30;  % y-齿2

    % 抹平强度（横向抑制 ∂x，纵向抑制 ∂y）
    ax = 0.35;
    ay = 0.35;

    % ===== 输入 =====
    x = x(:);
    if numel(x) ~= 2
        error('cbds_counterexample: input x must be length-2 vector.');
    end
    X = x(1); Y = x(2);

    % ===== 底座：二次 + 线性偏置 =====
    dx = X - 1; dy = Y - 1;
    f  = 0.5 * mu * (dx^2 + dy^2) + g0x * X + g0y * Y;
    if nargout > 1
        grad = [mu*dx + g0x; mu*dy + g0y];
    end

    % ===== 连续带状抹平 =====
    % 区间窗（对 |·-1|）
    Ix     = interval_window(abs(X-1), Slo, Shi);
    Iy     = interval_window(abs(Y-1), Slo, Shi);
    dIx_dX = d_interval_window(abs(X-1), Slo, Shi) * sgn(X-1);
    dIy_dY = d_interval_window(abs(Y-1), Slo, Shi) * sgn(Y-1);

    % 线窗（沿另一坐标的“管状”）
    Wy     = line_window(Y, 1, R);   dWy_dY = d_line_window(Y, 1, R);
    Wx     = line_window(X, 1, R);   dWx_dX = d_line_window(X, 1, R);

    % 横向带：抑制 ∂x
    Fx = - ax * Ix * Wy;     f = f + Fx;
    if nargout > 1
        grad(1) = grad(1) + (-ax) * dIx_dX * Wy;
        grad(2) = grad(2) + (-ax) * Ix * dWy_dY;
    end

    % 纵向带：抑制 ∂y
    Fy = - ay * Iy * Wx;     f = f + Fy;
    if nargout > 1
        grad(1) = grad(1) + (-ay) * Iy * dWx_dX;
        grad(2) = grad(2) + (-ay) * dIy_dY * Wx;
    end

    % ===== 双齿：x 方向两齿（在 y 的两个带上给 ∂x 正偏置） =====
    % 齿1：以 yband1 为中心
    By1 = line_window(Y, yband1, band_half1);  dBy1_dY = d_line_window(Y, yband1, band_half1);
    Sx1 = saturating_sigmoid(X - xband1);      dSx1_dX = d_saturating_sigmoid(X - xband1);
    Tx1 = tooth_amp_x1 * Sx1 * By1;            f = f + Tx1;
    if nargout > 1
        grad(1) = grad(1) + tooth_amp_x1 * dSx1_dX * By1;
        grad(2) = grad(2) + tooth_amp_x1 * Sx1 * dBy1_dY;
    end

    % 齿2：以 yband2 为中心（更靠近 1）
    By2 = line_window(Y, yband2, band_half2);  dBy2_dY = d_line_window(Y, yband2, band_half2);
    Sx2 = saturating_sigmoid(X - xband2);      dSx2_dX = d_saturating_sigmoid(X - xband2);
    Tx2 = tooth_amp_x2 * Sx2 * By2;            f = f + Tx2;
    if nargout > 1
        grad(1) = grad(1) + tooth_amp_x2 * dSx2_dX * By2;
        grad(2) = grad(2) + tooth_amp_x2 * Sx2 * dBy2_dY;
    end

    % ===== 双齿：y 方向两齿（在 x 的两个带上给 ∂y 正偏置） =====
    % 齿1：以 xband1 为中心
    Bx1 = line_window(X, xband1, band_half1);  dBx1_dX = d_line_window(X, xband1, band_half1);
    Sy1 = saturating_sigmoid(Y - yband1);      dSy1_dY = d_saturating_sigmoid(Y - yband1);
    Ty1 = tooth_amp_y1 * Sy1 * Bx1;            f = f + Ty1;
    if nargout > 1
        grad(1) = grad(1) + tooth_amp_y1 * Sy1 * dBx1_dX;
        grad(2) = grad(2) + tooth_amp_y1 * dSy1_dY * Bx1;
    end

    % 齿2：以 xband2 为中心（更靠近 1）
    Bx2 = line_window(X, xband2, band_half2);  dBx2_dX = d_line_window(X, xband2, band_half2);
    Sy2 = saturating_sigmoid(Y - yband2);      dSy2_dY = d_saturating_sigmoid(Y - yband2);
    Ty2 = tooth_amp_y2 * Sy2 * Bx2;            f = f + Ty2;
    if nargout > 1
        grad(1) = grad(1) + tooth_amp_y2 * Sy2 * dBx2_dX;
        grad(2) = grad(2) + tooth_amp_y2 * dSy2_dY * Bx2;
    end
end

% ===================== 辅助函数（全部 C^∞ 且有界） =====================

function val = interval_window(t, a, b)
% C^∞ 区间窗：|·-1| 落在 [a,b] 内时非零；端点用平滑 bump 连接
    if t <= a || t >= b
        val = 0;
    else
        tau = (t - a) / (b - a);   % tau ∈ (0,1)
        s1  = smoothstep(tau);
        s2  = smoothstep(1 - tau);
        val = s1 .* s2;
    end
end

function dval = d_interval_window(t, a, b)
% 对 t 的导数
    if t <= a || t >= b
        dval = 0;
    else
        tau = (t - a) / (b - a);
        s1  = smoothstep(tau);
        s2  = smoothstep(1 - tau);
        ds1 = dsmoothstep(tau)     / (b - a);
        ds2 = -dsmoothstep(1-tau)  / (b - a);
        dval = ds1 .* s2 + s1 .* ds2;
    end
end

function val = line_window(z, z0, h)
% 以 z0 为中心、半宽 h 的 C^∞ bump：|z-z0|<h 时非零
    t = (z - z0) / h;
    if abs(t) >= 1
        val = 0;
    else
        val = exp(-1 / (1 - t*t));
    end
end

% function dval = d_line_window(z, z0, h)
% % 对 z 的导数
%     t = (z - z0) / h;
%     if abs(t) >= 1
%         dval = 0;
%     else
%         b    = exp(-1 / (1 - t*t));
%         dbdt = b * (2*t) / (1 - t*t)^2;
%         dval = dbdt / h;
%     end
% end

function dval = d_line_window(z, z0, h)
    t = (z - z0) / h;
    if abs(t) >= 1
        dval = 0;
    else
        b    = exp(-1 / (1 - t*t));
        dbdt = b * (-2*t) / (1 - t*t)^2;  % ← 加负号
        dval = dbdt / h;
    end
end


function s = smoothstep(t)
% C^∞ 的 (0,1)->(0,1) 平滑窗（端外为 0）
    if t <= 0 || t >= 1
        s = 0;
    else
        s = exp(-1 ./ (t .* (1 - t)));  % bump 积分型，值域 (0,1)
    end
end

function ds = dsmoothstep(t)
    if t <= 0 || t >= 1
        ds = 0;
    else
        s  = exp(-1 ./ (t .* (1 - t)));
        ds = s .* (1 ./ t.^2 + 1 ./ (1 - t).^2);
    end
end

function y = saturating_sigmoid(z)
% 平滑饱和的单调函数（|y|<1，避免爆）
    y = z ./ sqrt(1 + z.^2);
end

function dy = d_saturating_sigmoid(z)
    dy = 1 ./ (1 + z.^2).^(3/2);
end

function s = sgn(z)
% 仅返回符号（z=0 时 0）；平滑性由其它窗函数保证
    if z > 0, s = 1; elseif z < 0, s = -1; else, s = 0; end
end
