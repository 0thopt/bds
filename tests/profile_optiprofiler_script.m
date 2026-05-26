clear all
options.mindim = 2;
options.maxdim = 50;
options.plibs = 's2mpj';
options.feature_name = 'plain';
% options.n_jobs = 1;

% options.solver_names = {'cbds', 'ds'};

% profile_optiprofiler(options);

% options.solver_names = {'cbds', 'newuoa'};

% profile_optiprofiler(options);

% options.solver_names = {'cbds', 'fd-bfgs'};

% profile_optiprofiler(options);

options.solver_names = {'bds', 'ds', 'nelder-mead', 'bfo', 'pds', 'nomad'};
profile_optiprofiler(options);