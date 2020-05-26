function c = disable_listener(hl)
%DISABLELISTENER Momentarily disable a listener (returns an onCleanup oject that reenable it when being garbage collected)
%---
% function c = disable_listener(hl)
%---
% Disable listener(s) and return an onCleanup object that will re-enable it
% (them) upon deletion. This is particularly useful for temporarily
% disabling a listener during the time a specific function will execute,
% without worrying of error potentially hapening in this function, as the
% listener will be re-enabled in any case.
%
% See also delete_valid (and Matlab onCleanup documentation)

% Thomas Deneux
% Copyright 2015-2017

if nargout==0
    error 'function disable_listener should be used with an output argument (onCleanup object), use hl.Enabled = false; to simply disable a listener'
end
if isempty(hl)
    c = [];
else
    disable(hl)
    c = onCleanup(@()enable(hl));
end

function disable(hl)

if ~isvalid(hl), return, end
[hl.Enabled] = deal(false);

function enable(hl)

if ~isvalid(hl), return, end
[hl.Enabled] = deal(true);
