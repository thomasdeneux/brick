function varargout = fn_mouse(varargin)
% function poly = fn_mouse([axes handle],'point|cross|poly|free|ellipse'[,msg])
% function [x y] = fn_mouse([axes handle],'point|cross'[,msg])
% function rect = fn_mouse([axes handle],'rect'[,msg])
% function [center axis e] = fn_mouse([axes handle],'ellipse'[,msg])
% function [center axis e relradius] = fn_mouse([axes handle],'ring'[,msg])
%---
% multi-functions function using mouse events
% mode defines action:
% 'point'       [default] get coordinates on mouse click
% 'cross'       get coordinates on mouse click - use cross pointer
% 'rect'        get a rectangle selection (format [xstart ystart xsize ysize])
% 'rectax'      get a rectangle selection (format [xstart xend ystart yend], using bottom-left corner as start)
% 'rectaxp'     get a rectangle selection (format [xstart xend; ystart yend], using first point pressed as start)
% 'rectangle'   get a rectangle selection (format [x1 x2 x3 x4; y1 y2 y3 y4])
% 'poly'        polygone selection
% 'polypt'      polygone selection, or single point if mouse was
%               immediately released
% 'line' or 'segment'       single line segment
% 'xsegment', 'ysegment'    a segment in x or y (format [start end]) 
% 'free'        free-form drawing
% 'ellipse'     circle or ellipse
% 'ring'        circular or elliptic ring 
% options: (ex: 'rect+', 'poly-@:.25:')
% +     selection is drawn (all modes)
% -     use as first point the current point in axes (rect, poly, free, ellipse)
% @     closes polygon or line (poly, free, spline)
% ^     enable escape: cancel current selection if a second key is pressed
% *     when drawing circles, make them circular on screen instead of with
%       respect to coordinates
% :num: interpolates line with one point every 'num' pixel (poly, free, ellipse)
%       for 'ellipse' mode, if :num; is not specified, output is a cell
%       array {center axis e} event in the case of only one outpout argument
% 
% See also fn_maskselect, interactivePolygon

% Thomas Deneux
% Copyright 2005-2017

% Input
i=1;
ha=[];
mode='';
msg = '';
while i<=nargin
    arg = varargin{i};
    if ishandle(arg), ha=arg;
    elseif ischar(arg)
        if isempty(mode), mode=arg; else msg=arg; end
    else error('bad argument')
    end
    i=i+1;
end
if isempty(mode), mode='point'; end
if isempty(ha), ha=gca; end
hf = fn_parentfigure(ha);
figure(hf)

% Extract parameters from mode definition
type = regexp(mode,'^(\w)+','match'); type = type{1};
buttonalreadypressed = any(mode=='-');
showselection = any(mode=='+');
openline = ~any(mode=='@');
dointerp = any(mode==':');
doescape = any(mode=='^');
doscreencircle = any(mode=='*');

% Suspend callbacks
SuspendCallbacks(ha)
C = onCleanup(@()RestoreCallbacks(ha)); % RestoreCallbacks will execute at the end even if an error occurs

switch type
    case {'point' 'cross'}
        if doescape, error 'escape option is not valid for type ''point'' or ''cross''', end
        curpointer = get(hf,'pointer');
        if strcmp(type,'cross'), set(hf,'pointer','fullcrosshair'), end
        waitforbuttonpressmsg(ha,msg)
        point = get(ha,'CurrentPoint');    % button down detected
        if strcmp(type,'cross'), set(hf,'pointer',curpointer), end
        if showselection
            oldnextplot=get(ha,'NextPlot'); set(ha,'NextPlot','add')
            plot(point(1,1),point(1,2),'+','parent',ha),
            set(ha,'NextPlot',oldnextplot)
        end
        switch nargout
            case {0 1}
                varargout={point(1,:)'};
            case 2
                varargout=num2cell(point(1,1:2));
            case 3
                varargout=num2cell(point(1,1:3));
            otherwise
                error 'too many output arguments'
        end
    case {'line' 'segment'}
        if doescape, warning 'escape option is not valid for type ''line''', end
        if ~buttonalreadypressed, waitforbuttonpressmsg(ha,msg), end
        p1 = get(ha,'CurrentPoint'); p1 = p1(1,1:2);
        hl(1) = line('xdata',p1([1 1]),'ydata',p1([2 2]),'parent',ha,'color','k');
        hl(2) = line('xdata',p1([1 1]),'ydata',p1([2 2]),'parent',ha,'color','b','linestyle','--');
        data = fn_buttonmotion({@drawline,ha,hl,p1},hf,'doup');
        delete(hl(2))
        if showselection
            set(hl(1),'color','y')
        else
            delete(hl(1))
        end
        switch nargout
            case {0 1}
                varargout = {data};
            case 2
                varargout = {data(:,1) data(:,2)};
            otherwise
                error 'too many output arguments'
        end
    case {'1D'}
        % one dimension selection
        % draw vertical or horizontal lines
        % return data with one dimension coordinates of first and second
        % points
        if doescape, warning 'escape option is not valid for type ''line''', end
        
        if strcmp(mode,'1D vertical')
            %if ~buttonalreadypressed, waitforbuttonpressmsg(ha,msg), end
            p1 = get(ha,'CurrentPoint'); p1 = p1(1,1:2);
            hl(1) = line('xdata',p1([1 1]),'ydata',[.5 -.5],'parent',ha,'color','k','linestyle','--');
            hl(2) = line('xdata',p1([1 1]),'ydata',[.5 -.5],'parent',ha,'color','b','linestyle','--');
            data = fn_buttonmotion({@draw1Dvertical,ha,hl,p1},hf,'doup');
            lineOneCoodinates = get(hl(1),'xdata');
            lineTwoCoodinates = get(hl(2),'xdata');
        else
            %if ~buttonalreadypressed, waitforbuttonpressmsg(ha,msg), end
            p1 = get(ha,'CurrentPoint'); p1 = p1(1,1:2);
            hl(1) = line('xdata',[.5 -.5],'ydata',p1([2 2]),'parent',ha,'color','k','linestyle','--');
            hl(2) = line('xdata',[.5 -.5],'ydata',p1([2 2]),'parent',ha,'color','b','linestyle','--');
            data = fn_buttonmotion({@draw1Dhorizontal,ha,hl,p1},hf,'doup');
            lineOneCoodinates = get(hl(1),'ydata');
            lineTwoCoodinates = get(hl(2),'ydata');
        end
            data = [lineOneCoodinates(1), lineTwoCoodinates(1)];
            delete(hl(2))
        
            if showselection
                %set(hl(1),'color','y')
            else
                delete(hl(1))
            end
            switch nargout
                case {0 1}
                    varargout = {data};
                case 2
                    varargout = {data(:,1) data(:,2)};
                otherwise
                    error 'too many output arguments'
            end
    case {'rect' 'rectax' 'rectaxp' 'rectangle' 'xsegment' 'ysegment'}
        % if button has already been pressed, no more button will be
        % pressed, so it is not necessary to suspend callbacks
        if ~buttonalreadypressed, waitforbuttonpressmsg(ha,msg), end
        selectiontype = get(hf,'selectionType');
        p0 = get(ha,'currentpoint'); p0 = p0(1,1:2);
        hl(1) = line(p0(1),p0(2),'color','k','linestyle','-','parent',ha);
        hl(2) = line(p0(1),p0(2),'color','w','linestyle',':','parent',ha);
        mode = fn_switch(type,'xsegment','x','ysegment','y','');
        rect = fn_buttonmotion({@drawrectangle,ha,hl,p0,mode},hf,'doup');
        delete(hl)
        if doescape && ~strcmp(get(hf,'selectionType'),selectiontype)
            % another key was pressed -> escape
            waitforbuttonup(hf)
            varargout = {[]};
            return
        end
        if showselection
            line(rect(1,[1:4 1]),rect(2,[1:4 1]),'color','k','parent',ha)
            line(rect(1,[1:4 1]),rect(2,[1:4 1]),'color','w','linestyle',':','parent',ha),
        end
        if strcmp(type,'rectangle')
            varargout={rect};
        else % type is 'rect'
            cornera = [min(rect(1,:)); min(rect(2,:))];
            cornerb = [max(rect(1,:)); max(rect(2,:))];
            switch type
                case 'rect'
                    rect = [cornera' cornerb'-cornera'];
                case 'rectax'
                    rect = [cornera(1) cornerb(1) cornera(2) cornerb(2)];
                case 'rectaxp'
                    rect = rect(:,[1 3]);
                case 'rectangle'
                    % already correct format
                case 'xsegment'
                    rect = [cornera(1) cornerb(1)];
                case 'ysegment'
                    rect = [cornera(2) cornerb(2)];
            end
            varargout = {rect};
        end
    case {'poly', 'polypt'}
        if ~buttonalreadypressed, waitforbuttonpressmsg(ha,msg), end
        selectiontype = get(hf,'selectionType');
        
        p = get(ha,'currentpoint'); p = p(1,1:2)';
        pp = fn_pointer(p);
        hl(1) = line(pp.x(1,:),pp.x(2,:),'parent',ha,'hittest','off', ...
            'color','k');
        hl(2) = line(pp.x(1,:),pp.x(2,:),'parent',ha,'hittest','off', ...
            'color','w','linestyle',':');
        % check whether mouse was released before any mouse motion
        if strcmp(type,'polypt')
            pmv = pointer();
            set(hf,'WindowButtonUpFcn',@(u,e)set(pmv,'x','up'))
            set(hf,'WindowButtonMotionFcn',@(u,e)set(pmv,'x','move'))
            waitfor(pmv,'x')
            if strcmp(pmv.x,'up')
                set(hf,'WindowButtonMotionFcn','')
                delete(hl)
                varargout = {p};
                return
            else
                updateLine(ha,hl,pp)
            end
        end
        set(hf,'WindowButtonMotionFcn',@(u,e)updateLine(ha,hl,pp))
        while true
            pp.x = pp.x(:,[1:end end]); % add a new point
            getPoint(hf,ha)
            if strcmp(get(hf,'SelectionType'),'open')
                pp.x = pp.x(:,1:end-1); % last added point is not valid
                break
            elseif doescape && ~strcmp(get(hf,'selectionType'),selectiontype)
                % another key was pressed -> escape
                set(hf,'WindowButtonMotionFcn','')
                delete(hl)
                varargout = {[]};
                return
            end
        end
        set(hf,'WindowButtonMotionFcn','')        
        x = pp.x;
        if showselection
            if ~openline
                set(hl,'xdata',x(1,[1:end 1]),'ydata',x(2,[1:end 1]))
            end
        else
            delete(hl)
        end
        if dointerp
            x = interpPoly(x,mode);
        end
        
        varargout={x};
    case 'free'
        if ~buttonalreadypressed, waitforbuttonpressmsg(ha,msg), end
        selectiontype = get(hf,'selectionType');
        p = get(ha,'currentpoint');
        hl(1) = line(p(1,1),p(1,2),'color','k','linestyle','-','parent',ha);
        hl(2) = line(p(1,1),p(1,2),'color','w','linestyle',':','parent',ha);
        fn_buttonmotion({@freeform,ha,hl},hf)
        x = [get(hl(1),'xdata'); get(hl(2),'ydata')];
        delete(hl)
        if doescape && ~strcmp(get(hf,'selectionType'),selectiontype)
            % another key was pressed -> escape
            waitforbuttonup(hf)
            varargout = {[]};
            return
        end
        if showselection
            if openline, back=[]; else back=1; end
            oldnextplot=get(ha,'NextPlot'); set(ha,'NextPlot','add')
            plot(x(1,[1:end back]),x(2,[1:end back]),'k-','parent',ha),
            plot(x(1,[1:end back]),x(2,[1:end back]),'w:','parent',ha),
            set(ha,'NextPlot',oldnextplot)
        end
        if dointerp
            x = interpPoly(x,mode);
        end
        varargout={x};
    case {'ellipse' 'ring'}
        if doescape, warning 'escape option is not valid for types ''ellipse'' and ''ring''', end
        if ~buttonalreadypressed, waitforbuttonpressmsg(ha,msg), end
        p = get(ha,'currentpoint');
        hl(1) = line(p(1,1),p(1,2),'color','k','linestyle','-','parent',ha);
        hl(2) = line(p(1,1),p(1,2),'color','w','linestyle',':','parent',ha);
        info = fn_pointer('flag','init');
        % circle
        if doscreencircle
            sz = fn_pixelsize(ha);
            ax = axis(ha); 
            screenratio = sz(2)/sz(1); % height / width
            axratio = (ax(4)-ax(3))/(ax(2)-ax(1)); % same, in axes coordinates
            yadjust = screenratio / axratio;
        else
            yadjust = 1;
        end
        fn_buttonmotion({@drawellipse,ha,hl,info,yadjust},hf,'doup')
        % make it an ellipse
        if strcmp(info.flag,'width')
            % change eccentricity -> ellipse
            fn_buttonmotion({@drawellipse,ha,hl,info,yadjust},hf)
        end
        % ring -> set the diameter of the internal circle
        if strcmp(type,'ring')
            info.flag = 'ring';
            fn_buttonmotion({@drawellipse,ha,hl,info,yadjust},hf)
        end
        x = [get(hl(1),'xdata'); get(hl(1),'ydata')];
        ax = info.axis;
        u = (ax(:,2)-ax(:,1))/2;
        center = mean(ax,2);
        ecc = info.eccentricity;
        if doscreencircle && ~all(u==0)
            % ellipse is defined for the moment in a referential where
            % y-axis has been scaled by yadjust, so we need to convert back
            % to the original referential
            % we use index 1/2 for respectively original/adjusted
            % referentials
            
            % vector conversion from ref1 to ref2
            M = diag([1 yadjust]);
            
            % first convert to symmatrix representation
            u2 = M*u;
            e2 = ecc;
            A2 = EllipseVector2Sym(u2,e2);
            
            % second apply affinity M^-1 (conversion from ref2 back to ref1)
            [u1, e1, ~] = EllipseAffinity(u2,e2,A2,M^-1);
            [u, ecc] = deal(u1, e1); % that's it
        end
        value = {center u ecc};
        if strcmp(type,'ring'), value{4} = info.relradius; end
        
        delete(hl)
        
        if showselection
            oldnextplot=get(ha,'NextPlot'); set(ha,'NextPlot','add')
            plot(x(1,1:end),x(2,1:end),'k-','parent',ha),
            plot(x(1,1:end),x(2,1:end),'w:','parent',ha),
            set(ha,'NextPlot',oldnextplot)
        end
        if dointerp
            x = interpPoly(x,mode);
        end
        switch nargout
            case {0 1}
                if dointerp
                    varargout = {x};
                else
                    varargout = {value};
                end
            case {3 4}
                varargout = value;
        end
    otherwise
        error('unknown type ''%s''',type)
end


%-------------------------------------------------
function SuspendCallbacks(ha)
% se pr�munir des callbacks divers et vari�s

setappdata(ha,'uistate',guisuspend(ha))
setappdata(ha,'oldtag',get(ha,'Tag'))
set(ha,'Tag','fn_mouse') % pour bloquer fn_imvalue !

%-------------------------------------------------
function RestoreCallbacks(ha)
% r�tablissement des callbacks avant les affichages

set(ha,'Tag',getappdata(ha,'oldtag'))
rmappdata(ha,'oldtag')
guirestore(ha,getappdata(ha,'uistate'))

%-------------------------------------------------
function state = guisuspend(ha)

hf = fn_parentfigure(ha);
state.hf        = hf;
state.obj       = findobj(hf);
state.hittest   = fn_get(state.obj,'hittest');
state.buttonmotionfcn   = get(hf,'windowbuttonmotionfcn');
state.buttondownfcn     = get(hf,'windowbuttondownfcn');
state.buttonupfcn       = get(hf,'windowbuttonupfcn');
state.keydownfcn        = get(hf,'keypressfcn');
state.keyupfcn = get(hf,'keyreleasefcn');
% state.handlevis = get(ha,'handlevisibility'); % seems not necessary

fn_set(state.obj,'hittest','off')
set(hf,'hittest','on','windowbuttonmotionfcn','', ...
    'windowbuttondownfcn','','windowbuttonupfcn','', ...
    'keypressfcn','','keyreleasefcn','')
% set(ha,'handlevisibility','on')

%-------------------------------------------------
function guirestore(ha,state)

fn_set(state.obj,'hittest',state.hittest);
hf = state.hf;
set(hf,'windowbuttonmotionfcn',state.buttonmotionfcn, ...
    'windowbuttondownfcn',state.buttondownfcn, ...
    'windowbuttonupfcn',state.buttonupfcn, ...
    'keypressfcn',state.keydownfcn, ...
    'keyreleasefcn',state.keyupfcn)
% set(ha,'handlevisibility',state.handlevis)

%-------------------------------------------------
function data=drawline(ha,hl,p1)

p2 = get(ha,'currentpoint');
data = [p1(:) p2(1,1:2)'];
set(hl,'xdata',data(1,:),'ydata',data(2,:))
drawnow update

function data=draw1Dvertical(ha,hl,p1)
% update vertical line using xdata coordinate of hl
% return x coordinates of p1 and of current point
p2 = get(ha,'currentpoint');
data = [p1(1,1) p2(1,1)];
%hl(2) = line('xdata',p2([1 1]),'ydata',[.5, -.5],'parent',ha,'color','k');
set(hl(2),'xdata',p2([1 1]),'ydata',[.5, -.5])
drawnow update

function data=draw1Dhorizontal(ha,hl,p1)
% update horizontal line using ydata coordinate of hl
% return y coordinates of p1 and of current point
p2 = get(ha,'currentpoint');
data = [p1(1,2) p2(1,2)];
%hl(2) = line('xdata',p2([1 1]),'ydata',[.5, -.5],'parent',ha,'color','k');
set(hl(2),'xdata',[.5, -.5],'ydata',p2([3, 3]))
drawnow update

%-------------------------------------------------
function p = getPoint(hf,ha)

set(hf,'windowbuttondownfcn',@(u,e)set(hf,'windowbuttondownfcn',''))
waitfor(hf,'windowbuttondownfcn')
p = get(ha,'currentpoint');
p = p(1,1:2)';
if nargout==0, clear p, end

%-------------------------------------------------
function updateLine(ha,hl,pp)

p = get(ha,'currentpoint');
p = p(1,1:2)';
pp.x(:,end) = p;
set(hl,'xdata',pp.x(1,:),'ydata',pp.x(2,:))            
drawnow update

%-------------------------------------------------
function freeform(ha,hl)

p = get(ha,'currentpoint');
xdata = get(hl(1),'xdata'); xdata(end+1) = p(1,1);
ydata = get(hl(1),'ydata'); ydata(end+1) = p(1,2);
set(hl,'xdata',xdata,'ydata',ydata)
drawnow update

%-------------------------------------------------
function rect = drawrectangle(ha,hl,p0,mode)

p = get(ha,'currentpoint'); 
pp = [p0(:) p(1,1:2)'];
if strcmp(mode,'x')
    pp(2,:) = get(ha,'ylim');
elseif strcmp(mode,'y')
    pp(1,:) = get(ha,'xlim');
end
xdata = pp(1,[1 1 2 2 1]);
ydata = pp(2,[1 2 2 1 1]);
rect = [xdata(1:4); ydata(1:4)];
set(hl,'xdata',xdata,'ydata',ydata)
drawnow update

%-------------------------------------------------
function drawellipse(ha,hl,info,yadjust)
% @param ha: Axes 
% @param hl: Line
% @param info: fn_pointer
% @param doscreencircle: logical

p = get(ha,'currentpoint');
p = p(1,1:2)';

% special cases: initialization
flag = info.flag;
switch flag
    case 'init'
        xdata = get(hl(1),'xdata');
        ydata = get(hl(1),'ydata');
        info.start = [xdata; ydata];
        info.axis = [xdata xdata; ydata ydata];
        info.eccentricity = 0.999;
        info.relradius = [];
        info.flag = 'axis';
        set(fn_parentfigure(ha),'windowbuttondownfcn',@(hf,evnt)set(info,'flag','click'))
        drawellipse(ha,hl,info,yadjust)
        return
    case 'click'
        ax = info.axis;
        u = (ax(:,2)-ax(:,1))/2;
        v = [u(2)*yadjust; -u(1)/yadjust]; % vector that is orthogonal to u and of same norm as u in the 'yadjust' changed referential
        p = ax(:,1) + u + v;
        p0 = fn_coordinates(ha,'a2s',p,'position');
        set(0,'pointerlocation',p0);
        info.flag = 'width';
        return
end

% main axis
switch flag
    case 'axis'
        ax = [info.start p];
        info.axis = ax;
    otherwise
        ax = info.axis;
end

% center
o = mean(ax,2);

% main axis vector
u = (ax(:,2)-ax(:,1))/2;

% change to a referential that has the requested aspect ratio
u2 = u;
u2(2) = u2(2) * yadjust;

% orthogonal vector
v2 = [u2(2); -u2(1)];

% eccentricity
switch flag
    case 'width'
        % project point on u2 and v2
        center = mean(ax,2);
        x2 = (p-center);
        x2(2) = x2(2) * yadjust; % change of referential
        uc = sum(x2.*u2)/sum(u2.^2);
        vc = sum(x2.*v2)/sum(u2.^2);
        e = abs(vc / (sin(acos(uc)))); % don't remember why this formula...
        info.eccentricity = e;
    otherwise
        e  = info.eccentricity;
end

% second radius for ring
switch flag
    case 'ring'
        center = mean(ax,2);
        x2 = (p-center);
        x2(2) = x2(2) * yadjust; % change of referential
        relradius = sqrt((x2'*u2)^2 + (x2'*v2/e)^2) / norm(u2)^2;
        info.relradius = relradius;
    otherwise
        relradius = info.relradius;
end

% update display
t = 0:.02:1;
udata = cos(2*pi*t);
vdata = e*sin(2*pi*t);
if ~isempty(relradius)
        udata = [udata NaN relradius*udata];
        vdata = [vdata NaN relradius*vdata];
end

% ellipse contour: go back to the axes referential
xdata = o(1) + u2(1)*udata + v2(1)*vdata;
ydata = o(2) + (u2(2)*udata + v2(2)*vdata) / yadjust;

% display
set(hl,'xdata',xdata,'ydata',ydata)
drawnow update

%-------------------------------------------------
function waitforbuttonpressmsg(ha,msg)

hf = fn_parentfigure(ha);

%if isempty(msg), waitfor(hf,'windowbuttondownfcn',''), return, end

p = get(ha,'currentpoint'); p=p(1,1:2);
dd = fn_coordinates(ha,'b2a',[9 9; 3 -12],'vector');
if isempty(msg)
    t = [];
else
    for i=1:2
        t(i) = text('parent',ha,'string',msg, ...
            'fontsize',8,'position',p(1:2)'+dd(:,i), ...
            'color',fn_switch(i,1,'k',2,'w')); %#ok<AGROW>
    end
end
set(hf,'windowbuttonmotionfcn',@(f,evnt)movesub(ha,t,dd), ...
    'windowbuttondownfcn', ...
    @(f,evnt)set(hf,'windowbuttonmotionfcn','','windowbuttondownfcn',''))
waitfor(hf,'windowbuttondownfcn','')
if ishandle(t), delete(t), end

%-------------------------------------------------
function waitforbuttonup(hf)

set(hf,'windowbuttonupfcn',@(h,e)set(hf,'windowbuttonupfcn',''))
waitfor(hf,'windowbuttonupfcn','')

%-------------------------------------------------
function movesub(ha,t,dd)

p = get(ha,'currentpoint'); p=p(1,1:2);
for i=1:length(t), set(t(i),'position',p(1:2)'+dd(:,i)), end
drawnow update

%-------------------------------------------------
function x = interpPoly(x,mode)

f = find(mode==':');
ds = str2double(mode(f(1)+1:end));
if ~openline, x(:,end+1)=x(:,1); end
np = size(x,2);
L = zeros(1,np);
for i=2:np, L(i) = L(i-1)+norm(x(i,:)-x(i-1,:)); end
if ~isempty(L), x = interp1(L,x,0:ds:L(end)); end

%------------
% ELLIPSE
%------------

% Ellipse defined either by center, main radius vector and eccentricity, or
% by its bilinear equation (x-c)'A(x-c) = 1,

function [u, e, A] = EllipseAffinity(u,e,A,M)

% ellipse equation becomes, for y=Mx: (y-Mc)'(M^-1' A M^-1)(y-Mc) = 1
M1 = M^-1;
A = M1'*A*M1;
[u, e] = EllipseSym2Vector(A);

%---
function A = EllipseVector2Sym(u,e)

% (U,c) is the referential of the ellipse, x->y=U'(x-c) returns coordinates
% in this referential, in which the ellipse equation is
% y(1)^2 + y(2)^2/e^2 = r^2
r = norm(u);
u = u/r;
U = [[-u(2); u(1)] u];
A = U*(diag([1/e^2 1])/r^2)*U';

%---
function [u e] = EllipseSym2Vector(A)

% eigenvalue decomposition returns U, r and e as above
[U D] = svd(A); % better use svd than eig because output is real even if A is not exactly symmetric
r = D(2,2)^-(1/2);
e = D(1,1)^-(1/2) / r;
u = r*U(:,2);


