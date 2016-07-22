function locate(fun)
% function locate(fun)
%---
% Will open Windows explorer and select the file of function fun

f = which(fun);
cmd = ['!explorer /select,"' f '"'];
disp(cmd)
eval(cmd)