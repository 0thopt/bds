clear all
options.mindim = 1;
options.maxdim = 1;
options.plibs = 's2mpj';
options.feature_name = 'plain';

% options.max_eval_factor = 200;
% options.solver_names = {'bds', 'ds', 'nelder-mead', 'bfo', 'pds', 'nomad'};
% profile_optiprofiler(options);
% options.solver_names = {'BDS-scaled', 'BDS-default'};
options.solver_names = {'bds', 'bds-simplified'};
% options.feature_name = 'random_nan_1';
% profile_optiprofiler(options);
% options.feature_name = 'random_nan_5';
profile_optiprofiler(options);