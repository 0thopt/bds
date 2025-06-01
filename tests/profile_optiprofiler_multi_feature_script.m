clear all
solver_names = {'cbds-orig', 'fd-bfgs'};
options.mindim = 51;
options.maxdim = 200;
profile_optiprofiler_multi_feature(solver_names, mindim, maxdim)

solver_names = {'cbds-orig', 'newuoa'};
options.mindim = 51;
options.maxdim = 200;
profile_optiprofiler_multi_feature(solver_names, mindim, maxdim)


