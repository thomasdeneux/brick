function c = enableListener(hl,val)
% function c = disableListener(hl)
%---
% Disable a listener (or list thereof) and returns an onCleanup object
% which will reanable it (or them) upon deletion.
%
% See also disableListener, deleteValid

if fn_matlabversion('newgraphics') || isa(hl,'event.listener')
    hl.Enabled = fn_switch(val,'logical');
else % property listener, previous to R2014b
    hl.Enabled = fn_switch(val,'on/off');
end