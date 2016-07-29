function hl = fn_gridplot(varargin)
% function hl = fn_gridplot([t,]data[,flag][,steps][,'num']
%                   [,'callback',fun][,'colors',colors][,'offset',offset])
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
% - 'num'   indicate numbers
% - fun     function to execute when clicking a line
%           fun(idx) has one argument indicating the coordinates of the
%           line being clicked (starting from dimension 2)
% - colors  re-define the list of colors
% - offset  vector of time indices to average for offset computation, or
%           'all' (or 'avg') for using all indices
%           or a cell array {idx, dim} where dim is the set of additional
%           dimensions over which to average (i.e. will share the same mean
%           value)
%
% See also fn_eegplot

% Input
organize = {'row' 'col' '-'}; coloridx = 3; colors = [];
steps = '3STD'; donum = false; callback = [];
offset = struct('flag','','idx',[],'dim',[]);
tt = []; y = [];
i = 0;
while i<length(varargin)
    i = i+1;
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
    elseif strcmp(a,'callback')
        i = i+1;
        callback = varargin{i};
    elseif ismember(a,{'color' 'colors'})
        i = i+1;
        colors = varargin{i};
    elseif strcmp(a,'offset')
        i = i+1;
        b = varargin{i};
        if isnumeric(b) || islogical(b) || ischar(b)
            offset.flag = 'avg';
            offset.idx = b;
        elseif iscell(b)
            offset.flag = 'avg';
            offset.idx = b{1};
            offset.dim = b{2};
        else
            error argument
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

% Subtract offset
switch offset.flag
    case ''
        % no offset subtraction
    case 'avg'
        if isnumeric(offset.idx) 
            m = reshape(y(offset.idx,:),[length(offset.idx) s(2:end)]);
        elseif islogical(offset.idx)
            m = reshape(y(offset.idx,:),[sum(offset.idx) s(2:end)]);
        elseif ismember(offset.idx,{'all' 'avg'})
            m = y;
        else
            error argument
        end
        m = nmean(m,1);
        for d=offset.dim
            m = nmean(m,d);
        end
        y = fn_subtract(y,m);
        clear m
end

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
        if isempty(colors), colors = get(gca,'colorOrder'); end
        ncol = size(colors,1);
        color = cell([1 s(2:end)]);
        for i=1:s(1+d)
            si = s0;
            si.subs{1+d} = i;
            coli = colors(fn_mod(i,ncol),:);
            color = subsasgn(color,si,{coli});
        end
    end
end

hl = plot(x1(:,:),y1(:,:));
hl = reshape(hl,[s(2:1+nd) 1]);
if ~isempty(color), fn_set(hl,'color',color(:)), end
if ~isempty(callback)
    for i=1:prod(s(2:1+nd))
        idx = fn_indices(s(2:1+nd),i);
        set(hl(i),'buttondownfcn',@(u,e)callback(idx))
    end
end
    

if nargout==0, clear hl, end
    
    