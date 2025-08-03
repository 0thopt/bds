clear all
options.dim = 'big';
options.plibs = 'matcutest';
options.solver_names = {'our-method', 'ds'};

options.feature_name = 'plain';
profile_optiprofiler(options);

options.solver_names = {'cbds', 'ds'};

options.feature_name = 'plain';
profile_optiprofiler(options);

options.feature_name = 'noisy_1e-3';
profile_optiprofiler(options);

options.feature_name = 'rotation_noisy_1e-3';
profile_optiprofiler(options);

options.solver_names = {'cbds', 'newuoa'};

options.feature_name = 'plain';
profile_optiprofiler(options);

options.feature_name = 'noisy_1e-3';
profile_optiprofiler(options);

options.feature_name = 'rotation_noisy_1e-3';
profile_optiprofiler(options);

options.solver_names = {'cbds', 'fd-bfgs'};

options.feature_name = 'plain';
profile_optiprofiler(options);

options.feature_name = 'noisy_1e-3';
profile_optiprofiler(options);

options.feature_name = 'rotation_noisy_1e-3';
profile_optiprofiler(options);



