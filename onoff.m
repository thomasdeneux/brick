function s = onoff(x,toggle_flag)
% function b = onoff(x,toggle_flag)
%---
% convert logical value to 'on' or 'off'

if nargin == 2
    if ~strcmp(toggle_flag, 'toggle')
        error 'second argument can only be the ''toggle'' flag'
    end
    switch x
        case 'on'
            s = 'off';
        case 'off'
            s = 'on';
        otherwise
            error 'when using function onoff with the ''toggle'' flag, first argument can be only ''on'' or ''off'''
    end
else
    if x
        s = 'on';
    else
        s = 'off';
    end
end