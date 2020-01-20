function mask = fn_poly2mask(xpoly,ypoly,m,n)
%FN_POLY2MASK Get the mask of a polygon interior
%---
% function mask = fn_poly2mask(xpoly,ypoly,m,n)
% function mask = fn_poly2mask(poly,sizes)
% function movie = fn_poly2mask('demo')
%---
% Do the same as Matlab poly2mask without needing the Image Toolbox
% Except use different convention!! I.e. x = first coordinate, y = second
% coordinate.
% Type fn_poly2mask('demo') to see an animation of how the algorithm works.
%
% See also fn_mask2poly

% Thomas Deneux
% Copyright 2015-2017

% input
domovie = false;
switch nargin
    case 0
        help fn_poly2mask
    case 1
        if ~strcmp(xpoly,'demo'), error argument, end
        m = 120;
        n = 90;
%         xpoly = [36 20 13 24 53 75 90 111 117 89 54 43 29 23 41 59 72 99 107 91 66 45];
%         ypoly = [73 63 36 18 19 46 68 68 27 9 26 49 58 36 26 41 58 62 40 22 32 68];
        xpoly = [35  14  12  37  82 107  96  75  44  32  57  83  80  60];
        ypoly = n-[78  60  30  13   9  30  69  82  70  48  28  35  64  83];
        domovie = true;
    case 4
        % the default input formatting, nothing to do
    case 2
        [poly sizes] = deal(xpoly,ypoly);
        xpoly = poly(1,:); ypoly = poly(2,:);
        m = sizes(1); n = sizes(2);
    case 3
        if isscalar(xpoly)
            error 'input is ambiguous'
        elseif isscalar(ypoly)
            [poly m n] = deal(xpoly,ypoly,m);
            xpoly = poly(1,:); ypoly = poly(2,:);
        else
            [xpoly ypoly sizes] = deal(xpoly,ypoly,m);
            m = sizes(1); n = sizes(2);
        end
    otherwise
        error 'wrong number of inputs'
end

% need to test only a sub-rectangle
if domovie
    [imin imax jmin jmax] = deal(1,m,1,n);
else
    imin = max(1,round(min(xpoly)));
    imax = min(m,round(max(xpoly)));
    jmin = max(1,round(min(ypoly)));
    jmax = min(n,round(max(ypoly)));
end

% apply function taken from Matplotlib
try
    submask = point_in_path_impl(xpoly-(imin-1),ypoly-(jmin-1),imax-imin+1,jmax-jmin+1,domovie);
catch
    if fn_dodebug
        disp 'please check what happened here!'
        keyboard
    end
end
if domovie
    mask = submask;
else
    mask = false(m,n);
    mask(imin:imax,jmin:jmax) = submask;
end

% % show it
% figure(fn_figure('test'))
% imagesc(mask'), axis image
% patch(xpoly,ypoly,'k','facecolor','none','edgecolor','k')

% no output?
if nargout==0, clear mask, end

% function from Matplotlib (https://github.com/matplotlib/matplotlib/blob/196f3446a3d5178c58144cee796fa8e8aa8d2917/src/_path.h, line 77+)
function mask = point_in_path_impl(xpoly,ypoly,ni,nj,domovie)

% pixel coordinates
ii = (1:ni)';
jj = 1:nj;
[iii jjj] = ndgrid(ii,jj);

% poly
nsegment = length(xpoly);

% output
mask = false(ni,nj);

% demo movie
if domovie
    msize = [2*ni 2*nj];
    hf = fn_figure('fn_poly2mask demo',msize);
    ha = axes('parent',hf,'pos',[0 0 1 1]);
    colormap(ha,[1 1 1; .5 .5 1])
    im = image(mask','parent',ha);
    line(xpoly([1:end 1]),ypoly([1:end 1]),'parent',ha,'color','k')
    seg = line([1],[1],'parent',ha,'color','k','linewidth',2);
    set(ha,'visible','off')
    movie = zeros([msize 3 nsegment+2], 'uint8');
    M = getframe(ha);
    movie(:,:,:,1) = permute(M.cdata, [2 1 3]);
end

% first vertex
[sx sy] = deal(xpoly(1),ypoly(1));

% loop on path segments
for isegment = 1:nsegment
    % 2 points of the segment
    ipt0 = isegment; ipt1 = 1+mod(isegment,nsegment);
    [x0 x1 y0 y1] = deal(xpoly(ipt0),xpoly(ipt1),ypoly(ipt0),ypoly(ipt1));
        
    % invert values of points below the segment
    icheck = xor(ii<=x0,ii<=x1); % points in grid with abscissae inside the x-span of the segment
    if ~any(icheck), continue, end
    maskcheck = mask(icheck,:);
    rightpath = bsxfun(@ge,(y1-jj)*(x0-x1),(x1-ii(icheck))*(y0-y1)); % points in grid on the right of path when going from point 0 to point 1
    if x0<x1, doinvert = rightpath; else doinvert = ~rightpath; end
    maskcheck(doinvert) = ~maskcheck(doinvert);
    mask(icheck,:) = maskcheck;
    
    % display
    if domovie
        set(im,'cdata',mask')
        set(seg,'xdata',[x0 x1],'ydata',[y0 y1])
        M = getframe(ha);
        movie(:,:,:,isegment+1) = permute(M.cdata,[2 1 3]);
        pause(.5)
    end
end

% output movie
if domovie
    delete(seg)
    M = getframe(ha);
    movie(:,:,:,isegment+2) = permute(M.cdata,[2 1 3]);
    mask = movie;
end
