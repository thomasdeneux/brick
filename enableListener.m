function c = enableListener(hl,val)
% function c = disableListener(hl)
%---
% Enable/disable a listener (or list thereof). Use rather disableListener
% function for momentarily disabling a listener.
%
% See also disableListener, deleteValid

if fn_matlabversion('newgraphics') || isa(hl,'event.listener')
    hl.Enabled = fn_switch(val,'logical');
else % property listener, previous to R2014b
    hl.Enabled = fn_switch(val,'on/off');
end