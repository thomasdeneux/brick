function varargout = dealc(x)
% function [y1 y2 ...] = dealc(x)
%---
% shortcut for [y1 y2 ...] = deal(x1,x2,...)

if ~iscell(x), x = num2cell(x); end
varargout = cell(1,nargout);
[varargout{:}] = deal(x{:});