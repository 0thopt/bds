function gn = plot_grad_norm_cbds(X, varargin)
% 分段拉伸纵轴：y<=y0 放大，y>y0 线性。完整曲线可视 + 低端高分辨 + 低端刻度不密集
% 依赖：cbds_counterexample(x) 第二输出为真梯度
%
% 用法示例：
%   gn = plot_grad_norm_cbds(X);  % 默认 y0=0.1, stretch=6, 低端主刻度 0.02，次网格 0.01
%   gn = plot_grad_norm_cbds(X,'y0',0.08,'stretch',8,'lowerMajor',0.02,'lowerMinor',0.005);

    % ---- 参数 ----
    p = inputParser;
    addParameter(p,'Title','Gradient Norm (piecewise-stretched y-axis)');
    addParameter(p,'y0',0.1);            % 分段阈值
    addParameter(p,'stretch',6);         % 低段放大倍数(>=1)
    addParameter(p,'lowerMajor',0.02);   % 低端 主刻度步长（文字标签）
    addParameter(p,'lowerMinor',0.01);   % 低端 次网格步长（不打标签，仅细网格）
    addParameter(p,'upperStep',1.0);     % 高端 主刻度步长
    parse(p,varargin{:});
    ttl       = p.Results.Title;
    y0        = p.Results.y0;
    s         = max(1,p.Results.stretch);
    lowMaj    = p.Results.lowerMajor;
    lowMin    = p.Results.lowerMinor;
    upStep    = p.Results.upperStep;

    % ---- 形状 ----
    if size(X,1)~=2 && size(X,2)~=2, error('X must be 2xN or Nx2.'); end
    if size(X,1)~=2, X = X.'; end
    N = size(X,2);

    % ---- 梯度范数 ----
    gn = zeros(1,N);
    for k=1:N
        [~, gk] = cbds_counterexample(X(:,k));
        gn(k) = norm(gk);
    end
    gmin = min(gn); gmax = max(gn);

    % ---- 分段轴变换 ----
    ymap = @(y) (y<=y0).*(s*y) + (y>y0).*(s*y0 + (y-y0));
    gnt  = arrayfun(ymap, gn);
    ymaxT = ymap(gmax)*1.02;

    % ---- 主刻度（文字标签） ----
    lowTicks  = 0:lowMaj:y0;                 % 低端稀疏主刻度
    if gmax>y0
        upStart = y0 + upStep;
        upTicks = upStart:upStep:ceil(gmax/upStep)*upStep;
    else
        upTicks = [];
    end
    majorOrig = unique([lowTicks, y0, upTicks]);
    majorPlot = arrayfun(ymap, majorOrig);

    % ---- 次网格（不打标签，只画细线） ----
    minorOrig = [];
    if ~isempty(lowMin) && lowMin>0 && lowMin<lowMaj
        minorOrig = setdiff(0:lowMin:y0, majorOrig);  % 排除已做主刻度的点
    end
    minorPlot = arrayfun(ymap, minorOrig);

    % ---- 绘图 ----
    figure;
    plot(1:N, gnt, 'LineWidth', 1.5);
    xlabel('Iteration index');
    ylabel('||\nabla f(x)|| (original values)');
    title(ttl);
    grid on;
    ylim([0, ymaxT]);

    % 设置主刻度位置与标签（显示原始数值）
    set(gca,'YTick',majorPlot, ...
            'YTickLabel', arrayfun(@(v)sprintf('%.3g',v), majorOrig,'UniformOutput',false));

    % 画低端细网格（次刻度）：不加文字，只作为参考线
    hold on;
    for yv = minorPlot
        yline(yv, 'Color',[0.85 0.85 0.85], 'LineStyle','-', 'LineWidth',0.5); % very light
    end

    % 画出分段阈值位置
    yline(ymap(y0), ':', sprintf(' y = %.3g (kink)', y0), ...
          'LabelHorizontalAlignment','left','LabelVerticalAlignment','bottom');

    % 最小/最大值标注
    [~,kmin]=min(gn); 
    % [~,kmax]=max(gn);
    text(kmin, ymap(gmin), sprintf('\\leftarrow min = %.4g', gmin), 'VerticalAlignment','bottom');
    % text(kmax, ymap(gmax), sprintf('max = %.4g \\rightarrow', gmax), 'HorizontalAlignment','right','VerticalAlignment','bottom');

    % 提示说明
    annotation('textbox',[.15 .86 .7 .1], 'String', ...
      sprintf('Piecewise y-axis: [0,%.3g] x%g (major %.3g, minor %.3g), above linear (step %.3g)', ...
      y0, s, lowMaj, lowMin, upStep), ...
      'EdgeColor','none','HorizontalAlignment','center','Color',[0.25 0.25 0.25]);
end
