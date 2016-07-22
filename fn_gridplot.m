function hl = fn_gridplot(varargin)
% function hl = fn_gridplot([t,]data[,flag][,steps][,'num'])
% ---
% Input:
% - y       ND data
% - flag    string made of keywords '-', 'row', 'col', 'grid' and 'c'
%           describe how dimensions (starting from the 2d one, the 1st one
%           being time) will be treated
%           'c' stands for color
%           [e.g. default is 'rowcol-c': 2d dimension will be organized
%           according to rows, 3rd to columns, 4th will not be organized
%           (i.e. all traces superimposed, but will set the colors)]
% - steps   [xstep ystep], {xstep ystep}, or ystep (see fn_eegplot)
%
% See also fn_eegplot

% Input
organize = {'row' 'col' '-'}; coloridx = 3;
steps = '3STD'; donum = false;
tt = []; y = [];
for i=1:length(varargin)
    a = varargin{i};
    if isempty(y) && isvector(a) && isempty(tt)
        tt = a;
    elseif isempty(y)
        y = a;
    elseif ~ischar(a)
        steps = a;
    elseif strcmp(a,'num')
        donum = true;
    elseif ~isempty(regexpi(a,'^(-|row|col|grid|c)*$'))
        tokens = regexpi(a,'(-|row|col|grid|c)','tokens');
        organize = [tokens{:}];
        coloridx = fn_find('c',organize);
        if ~isempty(coloridx)
            if ~isscalar(coloridx), error 'only one dimension can be used for colors', end
            if coloridx==1, error 'color flag ''c'' cannot come first', end
            organize(coloridx) = [];
            coloridx = coloridx-1;
        end
    else
        steps = a;
    end
end

% Data size and number of dimensions
s = size(y);
nt = s(1);
nd = length(s)-1; % first dimension is not counted
[organize{end+1:nd}] = deal('-');

% Time (=x-ordinate)
if isempty(tt)
    tt = 1:nt;
end
x = repmat(column(tt),[1 s(2:end)]);

% Step sizes
if ~iscell(steps), 
    if isnumeric(steps), steps = num2cell(steps); else steps = {steps}; end
end
if length(steps)==2
    xstep = steps{1};
    ystep = steps{2};
else
    xstep = (tt(end)-tt(1))*1.2;
    ystep = steps{1};
end
if ischar(ystep)
    token = regexpi(ystep,'^([0-9\.]*)STD$','tokens');
    if ~isempty(token)
        if isempty(token{1}{1}), fact=1; else fact=str2double(token{1}); end
        ystep = fact*nstd(y(:));
    else
        token = regexp(ystep,'^([0-9\.]*)fit$','tokens');
        if ~isempty(token)
            if isempty(token{1}{1}), fact=1; else fact=str2double(token{1}); end
            ystep = fact*max(max(y(:))-min(y(:)));
        end
    end
end
if donum
    x = x/xstep + .5; xstep = 1;
    y = y/ystep + 1; ystep = 1;
end

% Set steps
x1 = x; 
y1 = y;
s0 = substruct('()',repmat({':'},1,1+nd));
color = [];
for d=1:nd
    
    switch organize{d}
        case '-'
            % nothing to do
        case 'col'
            % dispatch horizontally
            for i=1:s(1+d)
                si = s0;
                si.subs{1+d} = i;
                x1 = subsasgn(x1,si,subsref(x,si)+(i-1)*xstep);
            end
        case 'row'
            % dispatch vertically
            for i=1:s(1+d)
                si = s0;
                si.subs{1+d} = i;
                y1 = subsasgn(y1,si,subsref(y,si)+(i-1)*ystep);
            end
        case 'grid'
            % dispatch all along the grid
            nrow = ceil(sqrt(s(1+d)/2));
            ncol = ceil(s(1+d)/nrow);
            for i=1:s(1+d)
                [ix iy] = ind2sub([ncol nrow],i);
                si = s0;
                si.subs{1+d} = i;
                x1 = subsasgn(x1,si,subsref(x,si)+(ix-1)*xstep);
                y1 = subsasgn(y1,si,subsref(y,si)+(iy-1)*ystep);
            end
    end
    
    if d==coloridx
        % use this dimension to set colors
        cols = get(gca,'colorOrder'); ncol = size(cols,1);
        color = cell([1 s(2:end)]);
        for i=1:s(1+d)
            si = s0;
            si.subs{1+d} = i;
            coli = cols(fn_mod(i,ncol),:);
            color = subsasgn(color,si,{coli});
        end
    end
end

hl = plot(x1(:,:),y1(:,:));
if ~isempty(color), fn_set(hl,'color',color(:)), end

if nargout==0, clear hl, end
    
    