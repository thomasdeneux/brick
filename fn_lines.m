function out = fn_lines(varargin)
%FN_LINES Draw a series of vertical and/or horizontal lines
%---
% function hl = fn_lines([xcoordinates,ycoordinates[,zcoordinates]][,ha][,'close'][,'bottom'][,'compact'][,line options])
% function hl = fn_lines('x|y'[,xorycoordinates][,ha][,'bottom'][,'compact'][,line options])
%---
% draw a series of vertical and/or horizontal lines
% 
% Input:
% - 'x|y'           indicate whether to draw only vertical or horizontal
%                   lines
% - coordinates     x, y, z coordinates of points through which lines
%                   should pass
% - ha              axes handle
% - 'bottom'        stack all created lines below other graphic elements
% - 'compact'       lines extend only to x/y/z limits of other lines rather
%                   than to axes limits 

% Thomas Deneux
% Copyright 2004-2017

% Input
% (x or y only?)
[dox doy] = deal(true);
if nargin>=1 && ischar(varargin{1})
    switch varargin{1}
        case 'x'
            [dox doy] = deal(true,false);
            varargin(1)=[];
        case 'y'
            [dox doy] = deal(false,true);
            varargin(1)=[];
    end
end
% (auto coordinates?)
if ~isempty(varargin)
    a = varargin{1};
    carg = (isnumeric(a) && ~(isscalar(a) && ishandle(a) && strcmp(get(a,'type'),'axes')));
else
    carg = false;
end
% (coordinates)
[x y z] = deal([]);
if carg
    if dox, x = varargin{1}; varargin(1) = []; end
    if doy, y = varargin{1}; varargin(1) = []; end
    if ~isempty(varargin)
        a = varargin{1};
        doz = (isnumeric(a) && ~(isscalar(a) && ishandle(a) && strcmp(get(a,'type'),'axes')));
    else
        doz = false;
    end
    if doz, z = varargin{1}; varargin(1) = []; end
else
    doz = (length(axis)==6);
end
if doz && ~(dox && doy), error 'argument', end
x = fn_float(x); y = fn_float(y); z = fn_float(z);
% (other options)
ha = []; [doclose, dostackbottom, docompact] = deal(false); lineopt = {'color' 'k'};
for i=1:length(varargin)
    a = varargin{i};
    if isscalar(a) && ishandle(a) && strcmp(get(a,'type'),'axes')
        ha = a;
    elseif ischar(a)
        switch a
            case 'close'
                doclose = true;
            case 'bottom'
                dostackbottom = true;
            case 'compact'
                docompact = true;
            otherwise
                lineopt = [lineopt varargin(i:end)];
                break
        end
    end
end
if isempty(ha), ha = gca; end

% Auto-coordinates
if ~carg
    [x y z] = fn_get(ha,'xtick','ytick','ztick');
end

% Go
if docompact
    if doz
        ax = [min(x(:)) max(x(:)) min(y(:)) max(y(:)) min(z(:)) max(z(:))];
    else
        ax = [min(x(:)) max(x(:)) min(y(:)) max(y(:))];
    end
else
    ax = axis(ha);
end
if ~doz
    % 2D
    if dox
        nx = length(x);
        hlx = zeros(1,nx);
        for k=1:nx
            hlx(k)=line([1 1]*x(k),ax([3 4]),lineopt{:},'parent',ha);
        end
    end
    if doy
        ny = length(y);
        hly = zeros(1,ny);
        for k=1:ny
            hly(k)=line(ax([1 2]),[1 1]*y(k),lineopt{:},'parent',ha);
        end
    end
    axis(ha,ax) % under some conditions, it can happen that drawing the lines changed the range! re-establish it
else
    % 3D
    [nx, ny, nz] = deal(length(x),length(y),length(z));
    [xx, yy, zz] = deal(ax([1 2]),ax([3 4]),ax([5 6]));
    hlxy = zeros(nx,ny);
    for i=1:nx
        for j=1:ny
            hlxy(i,j)=line([1 1]*x(i),[1 1]*y(j),zz,lineopt{:},'parent',ha);
        end
    end
    hlxz = zeros(nx,nz);
    for i=1:nx
        for k=1:nz
            hlxz(i,k)=line([1 1]*x(i),yy,[1 1]*z(k),lineopt{:},'parent',ha);
        end
    end
    hlyz = zeros(ny,nz);
    for j=1:ny
        for k=1:nz
            hlyz(j,k)=line(xx,[1 1]*y(j),[1 1]*z(k),lineopt{:},'parent',ha);
        end
    end
end

% output
if doz
    hl = {hlxy hlxz hlyz};
elseif dox && doy
    hl = {hlx hly};
elseif dox
    hl = hlx;
elseif doy
    hl = hly;
end
if nargout==1
    out = hl;
end
    
% stack to bottom
if dostackbottom
    if iscell(hl), hl = fn_map(hl,@row,'array'); end
    uistack(hl,'bottom')
end


