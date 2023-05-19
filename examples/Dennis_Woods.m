options.maxfun = 1e4;
options.expand = 2;
options.shrink = 0.5;
options.sufficient_decrease_factor = 1e-3;
options.tol = eps;
options.ftarget = -inf;
options.polling_inner = "opportunistic";
options.polling_blocks = "Gauss-Seidel";
options.cycling_inner = 1;
options.memory = true;

addpath('/home/lhtian97/bds_new_framework/src');

%[x, fval, exitflag, output] = blockwise_direct_search(@rosenb, [-1; 2], options)
[x, fval, exitflag, output] = fminsearch(@rosenb, [-1; 2], options)

function f = rosenb(x)

c_1 = [1; -1];
c_2 = [-1; 1];
f = max(norm(x-c_1), norm(x-c_2));

end
