function b = boolean(x)
% function b = boolean(x)
%---
% overload of built-in logical conversion function. If x is 'on' or 'off',
% will return respectively true or false. In other cases behaves as the
% built-in function

if ischar(x) && strcmp(x,'on')
    b = true;
elseif ischar(x) && strcmp(x,'off')
    b = false;
else
    b = logical(x);
end