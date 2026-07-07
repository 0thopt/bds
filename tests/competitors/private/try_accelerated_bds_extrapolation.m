function [xbest, fbest, nf, fhist, xhist, invalid_points] = try_accelerated_bds_extrapolation( ...
    fun, xbase, fbase, direction, step, nf, MaxFunctionEvaluations, ...
    ftarget, fhist, xhist, invalid_points, output_xhist)
%TRY_ACCELERATED_BDS_EXTRAPOLATION Finite probing along an accepted direction.

xbest = xbase;
fbest = fbase;
for k = 1:2
    if nf >= MaxFunctionEvaluations
        break;
    end
    xcand = xbest + step * direction;
    [fcand, fcand_real, is_valid] = eval_fun(fun, xcand);
    nf = nf + 1;
    fhist(nf) = fcand_real;
    if output_xhist
        xhist(:, nf) = xcand;
        if ~is_valid
            invalid_points = [invalid_points, xcand];
        end
    end
    if fcand < fbest
        xbest = xcand;
        fbest = fcand;
        if fcand <= ftarget
            break;
        end
        step = step * 2.0;
    else
        break;
    end
end

end
