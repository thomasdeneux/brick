function el = connect_listener(source,target,varargin)
%CONNECTLISTENER Create a listener that will auto-delete when a target object will be deleted
%---
% function [el = ] connect_listener(source,target,[propname,]eventname,callback)
%---
% Add a listener to source acting on target, until target gets deleted:
% This function is a wrapper of Matlab function 
%  addlistener(source,[propname,]eventname,callback)
% Yet, the listener is automatically deleted upon deleteion of the
% target(s).

% Create listener of the source
el = addlistener(source,varargin{:});

% Listen also to the target(s) deletion (to trigger listener deletion)
if ~iscell(target), target = num2cell(target); end
for i=1:numel(target)
    addlistener(target{i},'ObjectBeingDestroyed',@(u,e)delete(el));
end

% Output?
if ~nargout, clear el, end
