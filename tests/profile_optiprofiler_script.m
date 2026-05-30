clear all
options.mindim = 2;
options.maxdim = 50;
options.plibs = 's2mpj';
options.feature_name = 'plain';

options.solver_names = {'bds', 'ds', 'nelder-mead', 'bfo', 'pds', 'nomad'};
options.solver_names = {'BDS-scaled', 'BDS-default'};
options.solver_names = {'bds', 'bds-simplified'};
options.feature_name = 'random_nan_1';
profile_optiprofiler(options);
options.feature_name = 'random_nan_5';
profile_optiprofiler(options);