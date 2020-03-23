function poly = fn_mask2poly(mask)
% function poly = fn_mask2poly(mask)
%---
% Wraps Matlab Central mask2poly by Nikolay S. for easier manipulation.
% But uses opposite coordinates conventions! I.e. x = first coordinate, 
% y = second coordinate.
%
% See also fn_poly2mask

% Empty mask?
if ~any(mask)
    poly = zeros(0,2);
    return
end

% Cut the mask to reduce computation time
xproj = any(mask,2);
xfirst = find(xproj,1,'first');
xlast = find(xproj,1,'last');
yproj = any(mask,1);
yfirst = find(yproj,1,'first');
ylast = find(yproj,1,'last');
mask = mask(max(xfirst-1,1):min(xlast+1,end), max(yfirst-1,1):min(ylast+1,end));
xoffset = max(xfirst-1,1)-1;
yoffset = max(yfirst-1,1)-1;

% Apply mask2poly
poly = mask2poly(mask','Exact','CW')';

% Put NaNs in the disconnections
sep = poly(1,:)<0; 
if sep(1) && ~any(sep(2:end))
    poly(:,sep) = [];
else
    poly(:,sep) = NaN;
end

% Further improve it by adding corner points
n = size(poly,2);
poly2 = zeros(2,2*n-1);
% (keep the previous points)
poly2(:,1:2:end) = poly; 
% (add intermediary points: if we move from a vertical edge to an
% horizontal edge, take x-value of the 1st point, y-value of the 2nd point)
x1y2 = (mod(poly(1,2:end),1)==0);
y1x2 = ~x1y2;
poly2(1,2:2:end) = poly(1,(1:n-1)+y1x2);
poly2(2,2:2:end) = poly(2,(1:n-1)+x1y2);
poly = poly2;
poly(:,any(isnan(poly),1)) = NaN;

% Remove unnecessary points inside straight lines
d0 = (diff(poly,1,2) == 0); % derivative in dimension 2 is zero
middlepoint = any(d0(:,1:end-1) & d0(:,2:end), 1);
poly(:,1+find(middlepoint)) = [];



% Add offset
poly = fn_add(poly,[xoffset; yoffset]);



