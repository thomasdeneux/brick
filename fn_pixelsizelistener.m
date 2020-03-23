function el = fn_pixelsizelistener(source,varargin)
% function el = fn_pixelsizelistener(source,[target,],callback)
%---
% Add a listener that will execute whenever the pixel size of an object
% is changed.
%
% See also fn_pixelsize, fn_pixelposlistener

% Thomas Deneux
% Copyright 2015-2020

% Input
switch nargin
    case 2
        callback = varargin{1};
        target = [];
    case 3
        [target, callback] = deal(varargin{:});
end

% Create listener
el = connectlistener(source,target,'SizeChanged',callback);

% Output?
if nargout==0, clear el, end
