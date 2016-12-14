function s = fn_structdefault(model,n)
% function s = fn_structdefault(model[,n])
%---
% Create a scalar structure with the same fields as model, but all values empty

C = row(fieldnames(model)); [C{2,:}] = deal([]);
s = struct(C{:});
if nargin>=2
    if isscalar(n)
        s = repmat(s,[1 n]);
    else
        s = repmat(s,n);
    end
end