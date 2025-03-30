clear all

parameters.window_size = [18 1e8];
parameters.dist_tol = [1e-8 1e-30];
options = struct();
options.dim = 'small';
options.feature_name = 'plain';
options.draw_plots = true;
tuning_optiprofiler(parameters, options);

