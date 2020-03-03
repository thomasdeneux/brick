function [a, alpha] = fn_readimg(fname,flag)
% function [a [,alpha]] = fn_readimg(fname[,'nopermute'])
%---
% read image using imread, and handles additional features:
% - converts to double
% - detects if color or gray-scale images (in the last case, use a 2D array per image)
% - can read a stack of images (returns 3D array)
%
% images are read according to x-y convention, use 'nopermute' flag to use
% Matlab y-x convention

% Thomas Deneux
% Copyright 2004-2017

% Input
if nargin<1
    fname = fn_getfile;
end
if nargin<2
    dopermute = true;
else
    if ~strcmp(flag,'nopermute'), error argument, end
    dopermute = false;
end
fname = cellstr(fname);
nimages = length(fname);

% first image
[a alpha] = readoneframe(fname{1}, dopermute, true, false);
firstchannelonly = (size(a,3) == 1);

% multi-gif?
if size(a,4) > 1 && nimages > 1
    error('cannot read multiple GIF files')
end

% multi-tiff?
if strfind(lower(fn_fileparts(fname{1},'ext')),'.tif')
    nframes = length(imfinfo(fname{1}));
    if nimages>1 && nframes>1, error 'cannot handle multiple tif that themselves have multiple frames', end
else
    nframes = 1;
end
        
% stack
if nimages*nframes>1
	fn_progress('reading frame',nimages*nframes)
    if firstchannelonly
        a(1,1,nimages*nframes) = 0;
    else
        a(1,1,1,nimages*nframes) = 0;
    end
    if ~isempty(alpha)
        alpha(1,1,1,nimages*nframes) = 0;
    end
    for i=2:nimages*nframes
        fn_progress(i)
        if nframes>1
            [b beta] = readoneframe(fname{1},dopermute,false,firstchannelonly,i);
        else
            [b beta] = readoneframe(fname{i},dopermute,false,firstchannelonly);
        end        
        if firstchannelonly
            a(:,:,i) = b(:,:,1);
        else
            a(:,:,:,i) = b;
        end
        if ~isempty(alpha)
            alpha(:,:,i) = beta;
        end
    end
    fn_progress end
end

% make float-encoded color image btw 0 and 1
if ~firstchannelonly
    switch class(a)
        case {'single' 'double'}
            nbyte = ceil(log2(max(a(:)))/8);
            switch nbyte
                case 0
                    % max(a(:)) is 1, this is fine
                case 1
                    a = a/255;
                case 2
                    a = a/65535;
                otherwise
                    if fn_dodebug, disp 'please help me', keyboard, end
            end
        otherwise
            %if fn_dodebug, disp 'please help me', keyboard, end
    end
end
    

%---
function [a alpha] = readoneframe(f, dopermute, docheckgrayscale, firstchannelonly, i)

if nargin<5
    [a cmap alpha] = imread(f); 
else
    [a cmap alpha] = imread(f, i);
end
if dopermute
    a = permute(a,[2 1 3 4]); % Matlab (y,x) convention -> convention (x,y)
    if ~isempty(alpha)
        alpha = permute(alpha, [2 1 3]);
    end
end

% we can have multiple images for gif files
multiimage = (size(a,4) > 1);

if size(a,3)==3
    firstchannelonly = firstchannelonly || (docheckgrayscale &&  ~any(any(any(diff(a,1,3)))));
    if firstchannelonly
        % detected grayscale image saved as a color image: keep only one
        % channel since the three of them are identical
        a = a(:,:,1,:);
    end
elseif ~isempty(cmap)
    % apply colormap
    firstchannelonly = firstchannelonly || (docheckgrayscale &&  ~any(any(diff(cmap,1,2))));
    if firstchannelonly
        % grayscale colormap!
        a = reshape(cmap(a(:)+1,1), size(a));
    else
        a = reshape(cmap(a(:)+1,:),[size(a) 3]);
        if multiimage
            % a is nx*ny*1*nfr*3 -> make it nx*ny*3*nfr
            a = permute(a,[1 2 5 4 3]);
        end
    end
end

