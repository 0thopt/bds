clear all
options.dim = 'large';
options.plibs = 's2mpj';
options.feature_name = 'linearly_transformed';
options.n_jobs = 1;

options.solver_names = {'cbds', 'ds'};

profile_optiprofiler(options);

options.solver_names = {'cbds', 'newuoa'};

profile_optiprofiler(options);

options.solver_names = {'cbds', 'fd-bfgs'};

profile_optiprofiler(options);