function enable_listener(hl,val)
%ENABLELISTENER    Enable/disable a listener
%---
% function enable_listener(hl)
%---
% Enable/disable a listener (or list thereof). Use rather disable_listener
% function for momentarily disabling a listener.
%
% See also disable_listener, delete_valid

% Thomas Deneux
% Copyright 2015-2020

warning 'function enable_listener(hl,val) is deprecated, use hl.Enabled = val; instead'
hl.Enabled = boolean(val);
