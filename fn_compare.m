function fn_compare(x,y)
% function fn_compare(x,y)
%---
% Display a message about how do x and y differ (e.g. tell any size
% difference, or the maximal difference max(abs(row(x-y))), or which fields
% differ if x andd y are structures, etc.)

if isequaln(x,y)
    disp 'x and y are identical'
    return
end

if ~strcmp(class(x),class(y))
    fprintf('x is a %s, y is a %s\n',class(x),class(y))
    if ~(islogical(x) || isnumeric(x)) || ~(islogical(y) || isnumeric(y)), return, end
end

if ~isequal(size(x),size(y))
    fprintf('size of x is [%s], size of y is [%s]\n',fn_strcat(size(x),' '),fn_strcat(size(y),' '))
    return
end

% now x and y are of compatible types, and of the same size
N = numel(x);
if isnumeric(x) || islogical(x)
    xnan = isnan(x); ynan = isnan(y);
    n = sum(xnan(:) & ~ynan(:));
    if n, fprintf('x has %i NaN values where y hasn''t\n',n), end
    n = sum(ynan(:) & ~xnan(:));
    if n, fprintf('y has %i NaN values where x hasn''t\n',n), end
    d = row(abs(x-y));
    n = sum(d>0);
    if n
        fprintf('x and y differ in %i out of %i values\n',n,N)
        fprintf('maximal difference is %g\n',max(d))
    else
        disp 'Non-NaN values in x and y do not differ'
    end
elseif iscell(x)
    n = 0;
    for i=1:N, n = n + ~isequaln(x{i},y{i}); end
    if n
        fprintf('x and y differ in %i out of %i values\n',n,N)
    else
    end
elseif isstruct(x) && isscalar(x)
    Fx = fieldnames(x);
    Fy = fieldnames(y);
    ok = true;
    F = setdiff(Fx,Fy);
    if ~isempty(F)
        disp(['Some fields are present in x but not y: ' fn_strcat(F,', ')])
        ok = false;
    end
    F = setdiff(Fy,Fx);
    if ~isempty(F)
        disp(['Some fields are present in y but not x: ' fn_strcat(F,', ')])
        ok = false;
    end
    if ok && ~isequal(Fx,Fy)
        disp('Fields in x and y are not in the same order')
        ok = false;
    end
    F = intersect(Fx,Fy); 
    b = fn_map(F,@(f)~isequaln(x.(f),y.(f)),'array');
    if any(b)
        disp(['x and y differ for field(s) ' fn_strcat(F(b),', ')])
    elseif ok
        error 'x and y seem to be equal, but isequaln(x,y) returned false!'
    end
else
    fprintf('No comparisons implemented for class ''%s''',class(x))
end
