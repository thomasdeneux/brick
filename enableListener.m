function enableListener(hl,val)
%ENABLELISTENER    Enable/disable a listener
%---
% function enableListener(hl)
%---
% Enable/disable a listener (or list thereof). Use rather disableListener
% function for momentarily disabling a listener.
%
% See also disableListener, deleteValid

% Thomas Deneux
% Copyright 2015-2020

warning 'function enableListener(hl,val) is deprecated, use hl.Enabled = val; instead'
hl.Enabled = boolean(val);
