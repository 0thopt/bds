clear all
options.mindim = 2;
options.maxdim = 50;
options.plibs = 's2mpj';
options.feature_name = 'plain';

options.solver_names = {'bds', 'ds', 'nelder-mead', 'bfo', 'pds', 'nomad'};
options.solver_names = {'BDS-scaled', 'BDS-default'};
options.solver_names = {'bds-infinite', 'bds-finite'};
profile_optiprofiler(options);