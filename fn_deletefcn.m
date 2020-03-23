function fn_deletefcn(hu,deletefcn)
% function fn_deletefcn(hu,deletefcn)
%---
% Set the 'DeleteFcn' property of a graphic object in such a way that
% several functions can be executed upon its deletion.

% Thomas Deneux
% Copyright 2015-2017

warning 'function fn_deletecfn(hu,deletefcn) is deprecated, use addlistener(hu,'ObjectBeingDestroyed',deletefcn); instead'

% Multiple objects
if iscell(hu) || ~isscalar(hu)
    if ~iscell(hu), hu = num2cell(hu); end
    for i=1:numel(hu)
        fn_deletefcn(hu{i},deletefcn)
    end
    return
end

% Listen to object deletion
addlistener(hu,'ObjectBeingDestroyed',deletefcn);
    
