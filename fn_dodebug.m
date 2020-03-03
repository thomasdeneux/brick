function b = fn_dodebug(varargin)
%FN_DODEBUG     commodity to distinguish developpers from simple users
%---
% function b = fn_dodebug
% function fn_dodebug(msg)
%---
% In the first form, returns a boolean stating whether the user is a
% registered developer. In the second form, display a message only if the
% user is a registered developer.

hostlist = {'PCWIN-PCT_HP8570P_EQB', 'PCWIN-DESKTOP-CR6ES64', ...
    'GLNXA64-textorm-2-st'};
b = fn_ismemberstr(fn_hostname,hostlist);

if nargin>0
    if b
        msg = sprintf(varargin{:});
        disp(msg)
    end
    clear b
end
