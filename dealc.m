function varargout = dealc(x)
%DEALC Assign elements of an array to multiple outputs
%---
% function [y1 y2 ...] = dealc(x)
%---
% shortcut for [y1 y2 ...] = deal(x1,x2,...)

% Thomas Deneux
% Copyright 2015-2017

if ~iscell(x), x = num2cell(x); end
varargout = cell(1,nargout);
[varargout{:}] = deal(x{:});
