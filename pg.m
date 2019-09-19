function pg(varargin)
%PG Type 'for i=1:100, pg i, svd(rand(1000)); end' and check a very simple progress indicator 
%---
% function pg([prompt,]i[,max])
% function pg([prompt,]'i'[,'max'])
%---
% this is a shortcut for using fn_progress: instead of initializing before
% a loop with fn_progress(prompt,max), and then updating at each loop with
% fn_progress(i), only write pg(promt,i,max) inside the loop (the proper
% initialization will be called at the appropriate time)

% Thomas Deneux
% Copyright 2015-2017


persistent ilast curprompt curmax ndigit format tlast

prompt = 'loop';
maxval = 0;
switch nargin
    case 0
        help pg
        return
    case 1
        i = varargin{1};
    case 2
        x = varargin{1}; % prompt or i !?
        if ischar(x)
            try
                evalin('caller', x);
                [i maxval] = deal(varargin{:});
            catch
                [prompt i] = deal(varargin{:});
            end
        else
            [i maxval] = deal(varargin{:});
        end
    case 3
        [prompt i maxval] = deal(varargin{:});
    otherwise
        error 'too many arguments'
end
if ischar(i), i = evalin('caller',i); end
if ischar(maxval), maxval = evalin('caller',maxval); end


if isempty(ilast) || i<=ilast || ~strcmp(prompt,curprompt) || curmax~=maxval
    [curprompt curmax] = deal(prompt,maxval);
    if maxval
        ndigit = max(1, floor(log10(maxval)+1));
    else
        ndigit = max(1, floor(log10(i)+1));
    end
    format = ['%' num2str(ndigit) 'i'];
    if maxval
        format = [format '/' num2str(maxval,format)];
    end
    fprintf([prompt ' ' num2str(i,format) '\n'])
else
    if now-tlast<1e-6, return, end
    nerase = ndigit + (maxval>0)*(1+ndigit) + 1;
    if maxval
        if i>maxval, error 'i>max', end
    else
        ndigitnew = floor(log10(i)+1);
        if ndigitnew>ndigit
            ndigit = ndigitnew;
            format = ['%' num2str(ndigit) 'i'];
        end
    end
    fprintf([repmat('\b',1,nerase) num2str(i,format) '\n'])
end
ilast = i;
tlast = now;
drawnow
