function y = fn_cast(i,varargin)
% function y = fn_cast(i,y1,y2,..,yn[,y0])
%---
% Returns value indexed by i. Indices 0 and NaN return the last value.
%
% See also fn_switch

% Thomas Deneux
% Copyright 2015-2017

if i==0 || isnan(i)
    y = varargin{end};
else
    y = varargin{i};
end
