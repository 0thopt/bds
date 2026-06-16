function seed = make_iseqiv_seed(pname, n, ir, ftarget, Algorithm, x0)
%MAKE_ISEQIV_SEED creates a valid random seed for iseqiv tests.

seed_max = 2^32 - 1;
algorithm_code = sum(double(char(Algorithm)));
pname_code = sum(double(char(pname)));
ftarget_code = make_seed_code(ftarget);
x0_code = make_seed_code(norm(x0));

seed_raw = pname_code + n + ir + algorithm_code + ftarget_code + x0_code;
seed = max(0, min(seed_max, seed_raw));

end

function code = make_seed_code(value)

seed_max = 2^32 - 1;
if isnan(value)
    code = 0;
elseif isinf(value)
    code = seed_max;
else
    code = round(1e6 * abs(value));
end
code = max(0, min(seed_max, code));

end
