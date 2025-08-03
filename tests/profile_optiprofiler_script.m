clear all
options.dim = 'big';
options.plibs = 'matcutest';
options.feature_name = 'linearly_transformed';

options.solver_names = {'cbds', 'ds'};

profile_optiprofiler(options);

options.solver_names = {'cbds', 'newuoa'};

profile_optiprofiler(options);

options.solver_names = {'cbds', 'fd-bfgs'};

profile_optiprofiler(options);