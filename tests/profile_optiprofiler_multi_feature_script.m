clear all
solver_names = {'cbds-orig', 'fd-bfgs'};
mindim = 51;
maxdim = 200;
profile_optiprofiler_multi_feature(solver_names, mindim, maxdim)

solver_names = {'cbds-orig', 'newuoa'};
profile_optiprofiler_multi_feature(solver_names, mindim, maxdim)

solver_names = {'cbds-orig', 'direct-search-orig'};
profile_optiprofiler_multi_feature(solver_names, mindim, maxdim)

solver_names = {'cbds-orig', 'nelder-mead'};
profile_optiprofiler_multi_feature(solver_names, mindim, maxdim)