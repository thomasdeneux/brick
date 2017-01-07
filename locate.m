function locate(fun)
% function locate(fun)
%---
% Will open Windows explorer and select the file of function fun

% Thomas Deneux
% Copyright 2015-2017

f = which(fun);
cmd = ['!explorer /select,"' f '"'];
disp(cmd)
eval(cmd)
