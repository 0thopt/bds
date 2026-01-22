function rosenbrock_example()
%This file is based on https://github.com/libprima/prima/blob/main/matlab/examples/rosenbrock_example.m, 
%which is written by Zaikun Zhang.
%ROSENBROCK_EXAMPLE illustrates how to use bds.
%
%   N.B.: Make sure that you have installed the package by running the
%   `setup.m` script in the root directory before trying the examples.
%   You only need to do the installation once.
%
%   ***********************************************************************
%   Authors:    Haitian LI (hai-tian.li@connect.polyu.hk)
%               and Zaikun ZHANG (zhangzaikun@mail.sysu.edu.cn)
%               Department of Applied Mathematics,
%               The Hong Kong Polytechnic University
%               School of Mathematics,
%               Sun Yat-sen University
%
%   ***********************************************************************

fprintf('\nMinimize the chained Rosenbrock function with three variables:\n');
x0 = [0; 0; 0];  % starting point

% The following syntax is identical to fmincon:
[x, fx, exitflag, output] = bds(@chrosen, x0)

return

function f = chrosen(x)  % the subroutine defining the objective function
f = sum((x(1:end-1)-1).^2 + 4*(x(2:end)-x(1:end-1).^2).^2);
return

