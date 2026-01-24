function [xopt,fopt,exitflag,output] = bds_simplified(fun,x0)
n=length(x0);
MaxFunctionEvaluations=500*n; maxit=MaxFunctionEvaluations;
alpha_tol=1e-6;alpha_all=ones(1,n);
D = nan(n, 2*n);D(:, 1:2:2*n-1) = eye(n);D(:, 2:2:2*n) = -eye(n);
grouped_direction_indices=arrayfun(@(i) [2*i-1, 2*i], 1:10, 'UniformOutput', false);
expand=2; shrink=0.5;forcing_function=@(alpha) alpha^2;
reduction_factor=[0, eps, eps];polling_inner="opportunistic";cycling_inner=1;
fhist=nan(1,MaxFunctionEvaluations);exitflag=get_exitflag("MAXIT_REACHED");terminate=false;
fopt_all=nan(1,n);xopt_all=nan(n,n);
f0=fun(x0);nf=1;fhist(nf)=f0;xbase=x0;fbase=f0;
for iter=1:maxit
    for i=1:n
        direction_indices=grouped_direction_indices{i};
        inner_opt.FunctionEvaluations_exhausted=nf;
        inner_opt.MaxFunctionEvaluations=MaxFunctionEvaluations-nf;
        inner_opt.ftarget=ftarget; inner_opt.forcing_function=forcing_function;
        inner_opt.reduction_factor=reduction_factor; inner_opt.polling_inner=polling_inner;
        inner_opt.cycling_inner=cycling_inner; inner_opt.iprint=options.iprint; 
        [sub_xopt,sub_fopt,sub_exitflag,sub_output] = inner_direct_search( ...
            fun,xbase,fbase,D(:,direction_indices),direction_indices,alpha_all(i),inner_opt);
        fhist((nf+1):(nf+sub_output.nf))=sub_output.fhist; nf=nf+sub_output.nf;
        fopt_all(i)=sub_fopt; xopt_all(:,i)=sub_xopt;
        grouped_direction_indices{i}=sub_output.direction_indices;
        update_base = (reduction_factor(1)<=0 && sub_fopt<fbase) || ...
            (sub_fopt + reduction_factor(1)*forcing_function(alpha_all(i)) < fbase);
        if sub_fopt + reduction_factor(3)*forcing_function(alpha_all(i)) < fbase
            alpha_all(i)=expand*alpha_all(i);
        elseif sub_fopt + reduction_factor(2)*forcing_function(alpha_all(i)) >= fbase
            alpha_all(i)=shrink*alpha_all(i);
        end
        if sub_output.terminate, terminate=true; exitflag=sub_exitflag; break; end
        if all(alpha_all<alpha_tol), terminate=true; exitflag=get_exitflag("SMALL_ALPHA"); break; end
        if update_base, xbase=sub_xopt; fbase=sub_fopt; end
        if nf>=MaxFunctionEvaluations, terminate=true; exitflag=get_exitflag("MAXFUN_REACHED"); break; end
    end

    [~,index]=min(fopt_all,[],"omitnan");
    if ~isempty(index) && fopt_all(index)<fopt, fopt=fopt_all(index); xopt=xopt_all(:,index); end
    if terminate, break; end
end

output.funcCount=nf; output.fhist=fhist(1:nf);

end
