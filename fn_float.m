function x = fn_float(x)
%FN_FLOAT Convert integer to single, keep single or double as such 
%---
% function x = fn_float(x)
%---
% convert integer x to single-precision floating number, but do not change
% the class of floating number (in particular double-precision floating
% number remain the same)

% Thomas Deneux
% Copyright 2012-2017

if nargin==0, help fn_float, return, end

if ~(isnumeric(x) || islogical(x))
    error 'input must be integer'
end
switch class(x)
    case {'single' 'double' 'ndSparse'}
    case {'int64' 'uint64'}
        x = double(x);
    otherwise
        x = single(x);
end
