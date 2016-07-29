function y = fn_switch(varargin)
% function y = fn_switch(x,y_true,[x2,y_true2,[...]]y_false)
% function y = fn_switch(x,case1,y1,case2,y2,..,casen,yn[,ydefault])
% function y = fn_switch(true|false)
% function y = fn_switch('on|off'[',toggle'])
% function y = fn_switch(y,y_defaultifempty)
%---
% the 2 first cases are general prototypes: the functions recognize which
% to use according to whether x is logical and scalar
% MAKE SURE THAT X IS SCALAR AND LOGICAL IF YOU WANT TO USE THE FIRST FORM!
% the 2 other cases are specialized shortcuts to convert logical values
% true or false in the string 'on' or 'off'
% 'case1', 'case2', etc.. can be any Matlab variable to which x is compared
% but if they are cell arrays, x is compared to each of their elements
%
% See also fn_cast

% Thomas Deneux
% Copyright 2005-2012


x = varargin{1};

if nargin==1
        
    % specialized function: logical <-> on/off conversions
    if ischar(x)
        % on/off -> true/false
        switch x
            case 'on'
                y = true;
            case 'off'
                y = false;
            otherwise
                error('fn_switch with a single string argument: argument should be ''on'' or ''off''')
        end
    else
        % true/false -> on/off
        if x
            y = 'on';
        else
            y = 'off';
        end
    end
        
elseif nargin==2 && strcmp(varargin{2},'toggle')

    % specialized function: on/off switch
    switch x
        case 'on'
            y = 'off';
        case 'off'
            y = 'on';
        otherwise
            error('fn_switch with a two arguments: first argument should be ''on'' or ''off''')
    end
            return

elseif nargin==2
    
    % return first value, or second if first is empty
    if ~isempty(x)
        y = x;
    else
        y = varargin{2};
    end

elseif (isscalar(x) && islogical(x)) || (nargin==3)     
    
    % "IF"
    karg = 2;
    while true
        if x
            y = varargin{karg};
            return
        elseif nargin<=karg+2
            y = varargin{karg+1};
            return
        else
            % new test
            x = varargin{karg+1};
            karg = karg+2;
        end
    end
    
else
    
    % "SWITCH"
    ncase = floor((length(varargin)-1)/2);
    for k=1:ncase
        casek = varargin{2*k};
        if iscell(casek) || (~ischar(casek) && ~isscalar(casek) && isscalar(x))
            b = ismember(x,casek); 
        else
            b = isequal(x,casek); 
        
        end
        if b
            y = varargin{2*k+1};
            return
        end
    end
    if length(varargin)==2*ncase+2
        y = varargin{2*ncase+2};
    else
        error('value does not match any case')
    end
    
end
        