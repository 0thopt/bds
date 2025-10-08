function [xopt, fopt, exitflag, output] = fminsearch_with_history(fun, x0, options)
% fminsearch_with_history(fun, x0, options)
% Returns:
%   xopt, fopt, exitflag, output
%   output.funcCount : number of function evaluations
%   output.xhist     : n × #eval, each column is an evaluation point (column vector)
%   output.fhist     : #eval × 1, corresponding f(x) values
%
% Notes:
% - Regardless of whether x0 is a row or column vector, this function records it as 
% column vectors in output.xhist.

    if nargin < 3 || isempty(options), options = optimset(); end
    validateattributes(fun, {'function_handle'}, {'scalar'}, mfilename, 'fun', 1);
    validateattributes(x0,  {'numeric'}, {'vector','finite','real'}, mfilename, 'x0', 2);

    xhist = [];   % n × #eval
    fhist = [];   % #eval × 1

    % Record function evaluations
    function f = logged_fun(x)
        f = fun(x);         
        xhist(:, end+1) = x(:);
        fhist(end+1, 1)  = f;
    end

    % Call fminsearch normally, but use the logger as the objective function
    [xopt, fopt, exitflag, output] = fminsearch(@logged_fun, x0, options);

    output.xhist = xhist;   % n × #eval
    output.fhist = fhist;   % #eval × 1
end
