function [out1 out2] = fn_objectsize(hobj,unit,varargin)
% function siz = fn_pixelsize(hobj,unit[,'strict'])
% function [w h] = fn_pixelsize(hobj,unit[,'strict'])
%---
% returns the width and height in pixels of any object without needing to
% change any units values
%
% See also fn_pixelsize

% Thomas Deneux
% Copyright 2019-2019 

% get size in pixels (possibly with the 'strict' flag for axes
siz_pix = fn_pixelsize(hobj, varargin{:});

% get conversion
prev_unit = get(hobj, 'units');
set(hobj, 'units', unit);
pos = get(hobj, 'position');
set(hobj, 'units', prev_unit)
pos_pix = getpixelposition(hobj);
conversion = pos(3) / pos_pix(3);

% apply conversion 
siz = siz_pix * conversion;

% output
if nargout==2
    out1 = siz(1);
    out2 = siz(2);
else
    out1 = siz;
end