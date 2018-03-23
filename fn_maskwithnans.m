function y = fn_maskwithnans(x,mask)
% function y = fn_maskwithnans(x,mask)
%---
% Apply logical mask: replace values in x by NaNs wherever mask is false.

switch class(x)
    case {'single' 'double'}
        m = ones(size(mask),'like',x);
        m(~mask) = NaN;
    otherwise
        disp 'Cannot replace values with NaNs: array is not ''single'' or ''double'''
        m = mask;
end
y = fn_mult(x,m);
