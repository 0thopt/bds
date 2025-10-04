classdef EvalLogger < handle
    properties
        xs = [];   % n × #eval，每列是一次评估的 x
        fs = [];   % #eval × 1，对应的 f(x)
        nEval = 0; % 评估次数
        userfun    % 用户目标函数句柄
    end
    methods
        function obj = EvalLogger(userfun)
            obj.userfun = userfun;
        end
        function f = fun(obj, x, varargin)
            f = obj.userfun(x, varargin{:});
            obj.nEval = obj.nEval + 1;
            obj.xs(:, end+1) = x(:);   %#ok<AGROW>  % 列追加：n×1
            obj.fs(end+1, 1)  = f;     %#ok<AGROW>
        end
        function reset(obj)
            obj.xs = []; obj.fs = []; obj.nEval = 0;
        end
    end
end
