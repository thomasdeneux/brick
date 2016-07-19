function fn_controlpositions(hu,hp,posrel,pospix)
% function fn_controlpositions(hu,hp,posrel,pospix)
%---
% set the position of controls relatively to an axes, and set the
% appropriate listeners to automatically update those positions in case of
% change of figure position, etc...
%
% Input
% - hu      control handle
% - hp      axes or figure handle
% - posrel  position relative to axes/figure ([0 0] = bottom-left corner,
%           [1 1] = up-right corner)
% - pospix  position in pixels to add to 'posrel' and size of control

% Thomas Deneux
% Copyright 2008-2013

if nargin==0, help fn_controlpositions, return, end

% input
posrel = row(posrel); if length(posrel)==2, posrel(3:4)=0; end
pospix = row(pospix); if length(pospix)==2, pospix(3:4)=0; end

% pointer to listeners
hl = fn_pointer('ppos',[],'axlim',[],'axratio',[]);

% update position once
updatefcn = @(u,e)updatepositions(hu,hp,posrel,pospix,hl);
feval(updatefcn) 

% set listeners
if hp==get(hu,'parent')
    hl.ppos = fn_pixelsizelistener(hp,updatefcn);
elseif get(hp,'parent')==get(hu,'parent')
    hl.ppos = fn_pixelposlistener(hp,updatefcn);
    if strcmp(get(hp,'type'),'axes')
        axlistener(hp,hl,updatefcn) % sets info.axlim
        % watching xlim and ylim depends on the data aspect ratio mode
        hl.axratio = addlistener(hp,'DataAspectRatioMode','PostSet',@(m,evnt)axlistener(hp,hl,updatefcn));
    end
else
    error 'cannot first object must be either child or sibbling of second object'
end

% delete control upon parent deletion
fn_deletefcn(hp,@(u,e)delete(hu(ishandle(hu) || (isobject(hu) && isvalid(hu)))))

% delete listeners upon control deletion
fn_deletefcn(hu,@(u,e)deletelisteners(hl))

%---
function axlistener(hp,info,updatefcn)

feval(updatefcn)
if strcmp(get(hp,'DataAspectRatioMode'),'manual')
    info.axlim = addlistener(hp,{'XLim','YLim'},'PostSet',updatefcn);
end
    
%---
function deletelisteners(hl)

delete(hl.ppos(ishandle(hl.ppos)))
delete(hl.axlim(ishandle(hl.axlim)))
delete(hl.axratio(ishandle(hl.axratio)))


%---
function updatepositions(hu,hp,posrel,pospix,hl) 

if ~ishandle(hu) && ~(isobject(hu) && isvalid(hu) && isprop(hu,'units') && isprop(hu,'position'))
    % object not valid anymore: delete listeners and return
    deletelisteners(hl)
    return
end
if hp==get(hu,'parent')
    pos0 = [0 0];
    psiz = fn_pixelsize(hp);
elseif get(hp,'parent')==get(hu,'parent')
    ppos = fn_pixelpos(hp);
    pos0 = ppos(1:2);
    psiz = ppos(3:4);
    if strcmp(get(hp,'type'),'axes') && strcmp(get(hp,'dataaspectratiomode'),'manual')
        % if DataAspectRatioMode is manual, then only part of the axes might be
        % occupied!! let's see which dimension is not fully occupied
        availableratio = psiz(1)/psiz(2);
        dataratio = get(hp,'dataaspectratio'); % ratio(1) in x should be the same length as ratio(2) in y
        actualratio = (diff(get(hp,'xlim'))/dataratio(1)) / (diff(get(hp,'ylim'))/dataratio(2));
        change = actualratio/availableratio;
        if change>1
            % we want a larger x/y ratio than given by the full axes
            % -> shrink y dimension
            pos0(2) = pos0(2) + psiz(2)*(1-1/change)/2;
            psiz(2) = psiz(2)/change;
        else
            % the contrary
            pos0(1) = pos0(1) + psiz(1)*(1-change)/2;
            psiz(1) = psiz(1)*change;
        end
    end
else
    if fn_dodebug
        if isempty(get(hu,'parent'))
            disp 'cannot update position: object has currently no parent'
        elseif isempty(get(hp,'parent'))
            disp 'cannot update object position: reference has currently no parent'
        else
            disp 'cannot update object position: reference is neither parent, nor sibbling of object'
        end
    end
    return
end
pos = [pos0 0 0] + [psiz psiz].*posrel + pospix;
pos([3 4]) = max(pos([3 4]),2);
set(hu,'units','pixel','position',pos)


