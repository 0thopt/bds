function [x,fval,exitflag,output,eval_x,eval_f] = fminsearch_with_eval(fun,x0,options,varargin)
% eval_x: n × #eval（列向量存点）；eval_f: #eval × 1
    if nargin < 3 || isempty(options), options = optimset(); end
    L = EvalLogger(fun);
    [x,fval,exitflag,output] = fminsearch(@L.fun, x0, options, varargin{:});
    eval_x = L.xs;   % n × #eval
    eval_f = L.fs;   % #eval × 1
end
