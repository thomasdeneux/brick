function locate(f)
%LOCATE Reveal file in Explorer (Windows only)
%---
% function locate(f)
%---
% Reveal file or folder in Windows Explorer. f can also be the name of a
% Maltlab function on the path.

% Thomas Deneux
% Copyright 2015-2017

g = which(f);
if ~isempty(g)
    f = g;
end

if exist(f,'dir')
    % folder
    cmd = ['!explorer "' f '"'];
else
    % file
    cmd = ['!explorer /select,"' f '"'];
end
disp(cmd)
eval(cmd)
