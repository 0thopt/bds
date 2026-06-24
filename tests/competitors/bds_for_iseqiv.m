function [xopt, fopt, exitflag, output] = bds_for_iseqiv(fun, x0, options)
%BDS_FOR_ISEQIV Path-stable wrapper for comparing against bds.m.

if nargin < 3
    options = struct();
end

ensure_bds_on_path();
[xopt, fopt, exitflag, output] = bds(fun, x0, options);

end

function ensure_bds_on_path()
if exist('bds', 'file') == 2
    return;
end

competitors_dir = fileparts(mfilename('fullpath'));
tests_dir = fileparts(competitors_dir);
repo_dir = fileparts(tests_dir);
src_dir = fullfile(repo_dir, 'src');
if exist(fullfile(src_dir, 'bds.m'), 'file') == 2
    addpath(src_dir);
end
end
