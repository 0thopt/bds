function [xopt,fopt,exitflag,output]=bds_simplified(fun,x0)
n=length(x0);
MaxFunctionEvaluations=500*n; maxit=MaxFunctionEvaluations;ftarget=-inf;
alpha_tol=1e-6;alpha_all=ones(1,n);
D=nan(n, 2*n);D(:, 1:2:2*n-1)=eye(n);D(:, 2:2:2*n)=-eye(n);
grouped_direction_indices=arrayfun(@(i) [2*i-1, 2*i], 1:10, 'UniformOutput', false);
expand=2; shrink=0.5;forcing_function=@(alpha) alpha^2;
fhist=nan(1,MaxFunctionEvaluations);exitflag=get_exitflag("MAXIT_REACHED");terminate=false;
fopt_all=nan(1,n);xopt_all=nan(n,n);
f0=fun(x0);nf=1;fhist(nf)=f0;xbase=x0;fbase=f0;xopt=x0;fopt=f0;
for iter=1:maxit
    for i=1:n
        direction_indices=grouped_direction_indices{i};
        inner_opt.FunctionEvaluations_exhausted=nf;
        inner_opt.MaxFunctionEvaluations=MaxFunctionEvaluations-nf;
        inner_opt.ftarget=ftarget; inner_opt.forcing_function=forcing_function;
        [sub_xopt,sub_fopt,sub_exitflag,sub_output]=inner_direct_search( ...
            fun,xbase,fbase,D(:,direction_indices),direction_indices,alpha_all(i),inner_opt);
        fhist((nf+1):(nf+sub_output.nf))=sub_output.fhist; nf=nf+sub_output.nf;
        fopt_all(i)=sub_fopt; xopt_all(:,i)=sub_xopt;
        grouped_direction_indices{i}=sub_output.direction_indices;
        update_base=(sub_fopt < fbase);
        if sub_fopt + eps*forcing_function(alpha_all(i)) < fbase
            alpha_all(i)=expand*alpha_all(i);
        elseif sub_fopt + eps*forcing_function(alpha_all(i)) >= fbase
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

function [xopt, fopt, exitflag, output]=inner_direct_search(fun, ...
    xbase, fbase, D, direction_indices, alpha, options)
MaxFunctionEvaluations=options.MaxFunctionEvaluations;
forcing_function=options.forcing_function;
reduction_factor=options.reduction_factor;
ftarget=options.ftarget;exitflag=nan;

n=length(xbase);num_directions=length(direction_indices);
fhist=nan(1, num_directions);xhist=nan(n, num_directions);nf=0; 
fopt=fbase;xopt=xbase;
for j=1 : num_directions
    xnew=xbase+alpha*D(:, j);fnew=fun(xnew);nf=nf+1;
    fhist(nf)=fnew;xhist(:, nf)=xnew;
    if fnew < fopt, xopt=xnew;fopt=fnew;end    
    if fnew <= ftarget || nf >= MaxFunctionEvaluations, break;end
    sufficient_decrease=(fnew + reduction_factor(3) * forcing_function(alpha)/2 < fbase);
    if sufficient_decrease
        direction_indices=direction_indices([j, 1:j-1, j+1:end]);    
        break;
    end
end
terminate=(fnew <= ftarget || nf >= MaxFunctionEvaluations);
if fnew <= ftarget
    exitflag=get_exitflag( "FTARGET_REACHED");
elseif nf >= MaxFunctionEvaluations
    exitflag=get_exitflag("MAXFUN_REACHED");
end
output.fhist=fhist(1:nf);output.xhist=xhist(:, 1:nf);
output.nf=nf;output.direction_indices=direction_indices;
output.terminate=terminate;
end

function [exitflag] = get_exitflag(information)

switch information
    case "FTARGET_REACHED"
        exitflag = 0;
    case "MAXFUN_REACHED"
        exitflag = 1;
    case "MAXIT_REACHED"
        exitflag = 2;
    case "SMALL_ALPHA"
        exitflag = 3;
    otherwise
        exitflag = nan;
end

end
