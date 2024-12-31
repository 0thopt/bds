clear all
% options.dim = 'big';
options.mindim = 2;
options.maxdim = 2;
options.feature_name = 'permuted_noisy_1e-1';
options.solver_names = {'cbds', 'ds'};
profile_optiprofiler(options);

% options.solver_names = {'cbds', 'nomad'};
% profile_optiprofiler(options);

% options.feature_name = 'linearly_transformed';
% profile_optiprofiler(options);

% options.feature_name = 'noisy_1e-1';
% profile_optiprofiler(options);

% options.feature_name = 'noisy_1e-2';
% profile_optiprofiler(options);

% options.feature_name = 'noisy_1e-3';
% profile_optiprofiler(options);

% options.feature_name = 'noisy_1e-4';
% profile_optiprofiler(options);

% options.feature_name = 'rotation_noisy_1e-1';
% profile_optiprofiler(options);

% options.feature_name = 'rotation_noisy_1e-2';
% profile_optiprofiler(options);

% options.feature_name = 'rotation_noisy_1e-3';
% profile_optiprofiler(options);

% options.feature_name = 'rotation_noisy_1e-4';
% profile_optiprofiler(options);



