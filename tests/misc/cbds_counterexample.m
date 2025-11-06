function [f, grad] = cbds_counterexample2(x)
% CBDS_COUNTEREXAMPLE2  互补齿带 + 正交抑制窗 的 C^∞ 反例候选
% 仅输入 x (2x1 或 1x2)，第二输出为解析梯度 grad (2x1)。
% 结构：F = F_base + F_supp + F_teeth
%  - F_base: 二次底座 + 线性偏置（强制性、保证下界与水平集有界）
%  - F_supp: 正交抑制窗（把被评估坐标方向的一阶项局部抵消到很小）
%  - F_teeth: 两块互补“齿带”（在与被评估坐标正交的方向注入非零梯度）
%
% 目标：在两块矩形邻域 R_A, R_B 上分别实现：
%   R_A: |∂_x f| 很小、|∂_y f| 较大； R_B: |∂_y f| 很小、|∂_x f| 较大
% 以制造“各坐标方向的方向导数沿不同点列趋小”的数值机制。

    % ===== 参数（可按需要微调，但先用这组合做 sanity check） =====
    mu   = 1.5;                      % 二次底座强度
    g0x  = 0.25; g0y = 0.25;         % 线性偏置（各向相同）

    % 抑制窗：|·-1| 的环带 + 正交方向的“管状”门控
    Slo  = 0.07;   Shi = 0.38;       % 触发环带 |x-1|,|y-1| ∈ (Slo,Shi)
    R    = 0.45;                     % 管宽：B(z;1,R)

    % 互补“齿带”：两组中心（互不重叠），两块“棋盘格”区域
    % x方向“齿”的门控在 y≈yA 或 y≈yB；y方向“齿”的门控在 x≈xA 或 x≈xB
    xA   = 0.8333;  xB   = 0.9167;   % 竖带中心
    yA   = 0.7200;  yB   = 0.9200;   % 横带中心
    h1   = 0.06;    h2   = 0.08;     % 带半宽（窄带提高导数峰值）

    % 抑制强度（横向抑制 ∂x，纵向抑制 ∂y）
    ax   = 0.38;    ay    = 0.22;

    % 齿强度（优先抬“正交”分量）
    beta_x1 = 0.25; beta_x2 = 0.25;  % x-齿（保守，避免破坏 x 的“不过充分下降”）
    beta_y1 = 0.55; beta_y2 = 0.45;  % y-齿（抬高 ∂y，以托住梯度地板）

    % 可选的极弱 y-底座（托底 ∂y；若不想要，设为 0）
    eps_y = 0.02;   y_c = 0.80;

    % ===== 输入检查 =====
    x = x(:);
    if numel(x) ~= 2
        error('cbds_counterexample2: input x must be length-2 vector.');
    end
    X = x(1); Y = x(2);

    % ===== F_base：二次 + 线性偏置 =====
    dx = X - 1; dy = Y - 1;
    f  = 0.5 * mu * (dx^2 + dy^2) + g0x * X + g0y * Y;
    if nargout > 1
        grad = [mu*dx + g0x; mu*dy + g0y];
    end

    % ===== F_supp：正交抑制窗 =====
    % 环带窗 I(|·-1|;Slo,Shi) 及导数（对 t=|·-1| 再乘 sgn）
    Ix     = interval_window(abs(X-1), Slo, Shi);
    Iy     = interval_window(abs(Y-1), Slo, Shi);
    dIx_dX = d_interval_window(abs(X-1), Slo, Shi) * sgn(X-1);
    dIy_dY = d_interval_window(abs(Y-1), Slo, Shi) * sgn(Y-1);

    % 管状窗 B(z;1,R) 及导数（注意导数的“负号”）
    Wy     = line_window(Y, 1, R);   dWy_dY = d_line_window(Y, 1, R);
    Wx     = line_window(X, 1, R);   dWx_dX = d_line_window(X, 1, R);

    % 横带抑制 ∂x
    Fx = - ax * Ix * Wy;     f = f + Fx;
    if nargout > 1
        grad(1) = grad(1) + (-ax) * dIx_dX * Wy;
        grad(2) = grad(2) + (-ax) * Ix * dWy_dY;
    end

    % 纵带抑制 ∂y
    Fy = - ay * Iy * Wx;     f = f + Fy;
    if nargout > 1
        grad(1) = grad(1) + (-ay) * Iy * dWx_dX;
        grad(2) = grad(2) + (-ay) * dIy_dY * Wx;
    end

    % ===== F_teeth：两组互补齿带 =====
    % x-齿（门控在 y≈yA 或 y≈yB）
    By1 = line_window(Y, yA, h1);  dBy1_dY = d_line_window(Y, yA, h1);
    By2 = line_window(Y, yB, h2);  dBy2_dY = d_line_window(Y, yB, h2);
    Sx1 = saturating_sigmoid(X - xA);  dSx1_dX = d_saturating_sigmoid(X - xA);
    Sx2 = saturating_sigmoid(X - xB);  dSx2_dX = d_saturating_sigmoid(X - xB);

    Tx1 = beta_x1 * Sx1 * By1;   f = f + Tx1;
    Tx2 = beta_x2 * Sx2 * By2;   f = f + Tx2;

    if nargout > 1
        grad(1) = grad(1) + beta_x1 * dSx1_dX * By1 + beta_x2 * dSx2_dX * By2;
        grad(2) = grad(2) + beta_x1 * Sx1     * dBy1_dY + beta_x2 * Sx2     * dBy2_dY;
    end

    % y-齿（门控在 x≈xA 或 x≈xB）
    Bx1 = line_window(X, xA, h1);  dBx1_dX = d_line_window(X, xA, h1);
    Bx2 = line_window(X, xB, h2);  dBx2_dX = d_line_window(X, xB, h2);
    Sy1 = saturating_sigmoid(Y - yA);  dSy1_dY = d_saturating_sigmoid(Y - yA);
    Sy2 = saturating_sigmoid(Y - yB);  dSy2_dY = d_saturating_sigmoid(Y - yB);

    Ty1 = beta_y1 * Sy1 * Bx1;   f = f + Ty1;
    Ty2 = beta_y2 * Sy2 * Bx2;   f = f + Ty2;

    if nargout > 1
        grad(1) = grad(1) + beta_y1 * Sy1 * dBx1_dX + beta_y2 * Sy2 * dBx2_dX;
        grad(2) = grad(2) + beta_y1 * dSy1_dY * Bx1 + beta_y2 * dSy2_dY * Bx2;
    end

    % ===== 极弱的 y-方向“全局坡度”托底（可置 eps_y=0 关闭）=====
    if eps_y ~= 0
        Fy_floor = eps_y * (Y - y_c) ./ sqrt(1 + (Y - y_c).^2);
        f = f + Fy_floor;
        if nargout > 1
            grad(2) = grad(2) + eps_y * 1./(1 + (Y - y_c).^2).^(3/2);
        end
    end
end

% ===================== C^∞ 辅助函数 =====================

function val = interval_window(t, a, b)
% C^∞ 区间 bump：a<t<b 时为正，端点及外部为 0
    if t <= a || t >= b
        val = 0;
    else
        tau = (t - a) / (b - a);   % tau∈(0,1)
        s1  = smoothstep(tau);
        s2  = smoothstep(1 - tau);
        val = s1 .* s2;
    end
end

function dval = d_interval_window(t, a, b)
% 对 t 的导数（端点为 0）
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
% 线状 C^∞ bump：|z-z0|<h 时为正，外部为 0
    t = (z - z0) / h;
    if abs(t) >= 1
        val = 0;
    else
        val = exp(-1 / (1 - t*t));
    end
end

function dval = d_line_window(z, z0, h)
% 对 z 的导数（注意负号）
    t = (z - z0) / h;
    if abs(t) >= 1
        dval = 0;
    else
        b    = exp(-1 / (1 - t*t));
        dbdt = b * (-2*t) / (1 - t*t)^2;  % ← 正确符号
        dval = dbdt / h;
    end
end

function s = smoothstep(t)
% C^∞ 的 (0,1)->(0,1) 平滑 bump（端外为 0）
    if t <= 0 || t >= 1
        s = 0;
    else
        s = exp(-1 ./ (t .* (1 - t)));
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
% 平滑饱和单调函数（有界，避免爆）
    y = z ./ sqrt(1 + z.^2);
end

function dy = d_saturating_sigmoid(z)
    dy = 1 ./ (1 + z.^2).^(3/2);
end

function s = sgn(z)
% z 的符号（0→0）；连续性由其它平滑窗保障
    if z > 0, s = 1; elseif z < 0, s = -1; else, s = 0; end
end
