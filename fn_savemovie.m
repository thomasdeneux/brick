function fn_savemovie(a,varargin)
% function fn_savemovie(a[,fname][,clip][,fps][,zoom][,map]
%                       [,'nopermute'][,'quality',value])
%---
% Input:
% - a       x-y-t or x-y-3-t for true colors
%           (be aware that this differs from Matlab y-x convention, use
%           'nopermute' option for using Matlab convention)
% - fname   file name (movie is saved in file only if specified), can have
%           .avi or .mp4 extension [if no extension, will be saved as .mp4]
% - clip    a 2-values vector, or clip flag (see fn_clip) [by default, no
%           clipping for true color movies or movies with uint8 or uint16
%           values, otherwise default = 'fit']
% - fps     frames per second [default = 30]
% - zoom    zooming value, according to which the movie is either
%           interpolated (zoom>0) or binned (0<zoom<1) or enlarged with
%           "big pixels" (zoom<-1) 
% - map     nx3 array for the colormap [default = grayscale movie]
% - 'nopermute'  use Matlab convention: a is organized as y-x-c-t
% - quality compression quality; by default, .avi files are uncompressed,
%           but setting a quality value (between 0 and 100) results in
%           compression using 'Motion JPEG AVI' and this quality value; by
%           default, .mp4 files are compressed with quality value 75
%
% Note that arguments can be passed in any order, except the first; if
% there is ambiguity, the function tries to guess which value was entered
% (for example a scalar value will be assigned to 'fps' if it is >=5, and to
% 'zoom' if it is <5); in order to de-ambiguate, it is possible to preced
% the value by a flag.
% e.g. fn_savemovie(rand(3,4,25),'fname','test.avi','zoom',10)
%
% See also fn_readmovie, fn_movie, VideoWriter

% Thomas Deneux
% Copyright 2004-2017

if nargin<1, help fn_savemovie, return, end

% Input movie
if (ndims(a)==4)
    truecolors = true;
    [ni nj nc nt] = size(a);
    if nc~=3
        if nc==1
            truecolors = false;
        elseif nt==3
            a = permute(a,[1 2 4 3]);
            [ni nj nc nt] = size(a);
        else            
            error('if data is 4D, third dimension should be 3 (true colors)')
        end
    end
else
    truecolors = false;
    [ni nj nt] = size(a);
    nc = 1;
    a = reshape(a,[ni nj nc nt]);
end

% Other inputs
i = 1;
fname = []; clip = []; fps = 30; zoom = 1; map = []; dopermute = [];
compression_quality = [];
while i<=length(varargin)
    x = varargin{i}; i=i+1;
    if ischar(x)
        if strcmp(x,'fit') || any(findstr(clip,'%iSD'))
            clip = x;
        else 
            switch x
                case 'fname'
                    fname = varargin{i}; i=i+1;
                case 'clip'
                    clip = varargin{i}; i=i+1;
                case 'fps'
                    fps = varargin{i}; i=i+1;
                case 'zoom'
                    zoom = varargin{i}; i=i+1;
                case {'map' 'cmap' 'colormap'}
                    map = varargin{i}; i=i+1;
                    if ischar(map), map = feval(map,256); end
                case 'nopermute'
                    dopermute = false;
                case 'quality'
                    compression_quality = varargin{i}; i=i+1;
                otherwise
                    if isempty(fname)
                        fname = x;
                    else
                        map = feval(x,256);
                    end
            end
        end
    elseif isscalar(x)
        if x>5
            fps = x;
        else
            zoom = x;
        end
    elseif isvector(x) && length(x)==2
        clip = x;
    elseif size(x,2)==3
        map = x;
    else
        error('argument error')
    end
end
if nargout==0 && isempty(fname)
    fname = fn_savefile('*.avi','Select file to save movie.');
    if ~fname, disp('canceled'), return, end
end

% zoom parameters
if zoom<0
    % special: change dimension, but without interpolation; zoom must be of
    % the form -N or -1/N
    disp 'make big pixels'
    if zoom<-1, N=-zoom; else N=-1/zoom; end
    if ~mod(N,1)==0, error('negative zoom factor must be of the form -N or -1/N'), end
    if zoom<-1
        a = reshape(a,1,ni,1,nj,nc,nt);
        a = repmat(a,[N 1 N 1 1]);
        a = reshape(a,ni*N,nj*N,nc,nt);
    else
        a = fn_bin(a,[N N 1 1]);
    end
    [ni nj nc nt] = size(a);
    zoom = 1;
elseif zoom~=1
    if truecolors
        error('zoom>0 not implemented yet for true colors')
    end
    if zoom<1
        % necessitate low-pass filtering before interpolation
        msg = 'low-pass and reduce images';
        sigma = 1/(2*zoom);
        h = fspecial('gaussian',5*ceil(sigma),sigma);
    elseif ~mod(zoom,1)
        disp '(use negative zoom value to enlarge without interpolation)'
        msg = 'enlarge images using interpolation';
    end
    [xx yy] = ndgrid(1:ni,1:nj); 
    [xx2 yy2] = ndgrid(1:1/zoom:ni,1:1/zoom:nj);
    b = zeros(size(xx2,1),size(xx2,2),nc,nt);
    fn_progress(msg,nt)
    for i=1:nt
        fn_progress(i)
        fr = a(:,:,:,i);
        if ~isa(fr,'uint8'), fr = double(fr); end
        if zoom~=1
            fn_progress(i);
            if zoom<1, fr = filter2(h,fr); end
            fr = interp2(xx,yy,fr,xx2,yy2,'*spline');
        end
        b(:,:,:,i) = im2frame(fr,map);
    end
    a = b; clear b
end

% permute
if dopermute
    a = permute(a,[2 1 3 4]);
end

% clipping
if isempty(clip) && ~truecolors && ~isinteger(a)
    clip = 'fit';
end
if ~isempty(clip)
    disp('rescale'), drawnow
    a = fn_clip(a,clip); % double values between 0 and 1
end

% check compression
ext = lower(fn_fileparts(fname,'ext'));
if isempty(ext) || ~ismember(ext,{'.avi' '.mp4'})
    ext = '.mp4'; 
end
switch ext
    case '.avi'
        if isempty(compression_quality)
            if truecolors
                profile = 'Uncompressed AVI';
            elseif isempty(map)
                profile = 'Grayscale AVI';
            else
                profile = 'Indexed AVI';
            end
        else
            profile = 'Motion JPEG AVI';
        end
    case '.mp4'
        profile = 'MPEG-4';
        if isempty(compression_quality)
            compression_quality = 75;
        end
end

% color map ?
if ~isempty(map)
    if truecolors
        warning 'color map is ignored for color movie'
        map = [];
    elseif isempty(compression_quality)
        % color map will be incorporated to the movie
        a = uint8(a*size(map,1));
    else
        disp 'apply color map before compression'
        a = 1 + floor(a*size(map,1)); % ok because 0 <= x < 1 for all x in a
        a = cat(3, ...
            reshape(map(a(:),1),[ni nj 1 nt]), ...
            reshape(map(a(:),2),[ni nj 1 nt]), ...
            reshape(map(a(:),3),[ni nj 1 nt]));
        map = [];
    end
end

% create movie object
if isempty(compression_quality)
    disp 'create uncompressed movie'
else
    disp 'create compressed movie'
end
writerobj = VideoWriter(fname,profile);
writerobj.FrameRate = fps;
if ~isempty(map), writerobj.Colormap = map; end
if ~isempty(compression_quality), writerobj.Quality = compression_quality; end
open(writerobj)
writeVideo(writerobj,a)
close(writerobj)
    
