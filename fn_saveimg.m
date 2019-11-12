function fn_saveimg(a,fname,varargin)
% function fn_saveimg(a,fname|'auto',[clip[,zoom[,cmap]]][,'delaytime',dt]
%                     [,'alpha',alpha])
%---
% a should be y-x-t 
% clip can be a 2-values vector, or 'fit' [default], or '?SD', or 'none'

% Thomas Deneux
% Copyright 2004-2017

if nargin<1, help fn_saveimg, return, end
if nargin<2 || isempty(fname), fname=fn_savefile; end
if isequal(fname,0), return, end

clip = 'auto'; zoom = 1; cmap = []; delaytime = .1; alpha = [];
k=0;
while k<length(varargin)
    k = k+1;
    x = varargin{k};
    if ischar(x) 
        switch x
            case 'delaytime'
                k = k+1;
                delaytime = varargin{k};
                continue
            case 'alpha'
                k = k+1;
                alpha = varargin{k};
                continue
        end
    end
    switch k
        case 1
            clip = x;
        case 2
            zoom = x;
        case 3
            cmap = x;
        otherwise
            argument error
    end
end

% image(s) size and number color/bw + make frames the last dimension
% (either 3rd or 4th depending on whether there are colors or not)
[ni nj nt nt2] = size(a);
if ismember(nt2, [3 4])
    a = permute(a,[1 2 4 3]);
    ncol = nt2;
elseif ismember(nt, [3 4])
    ncol = nt;
    nt = nt2;
elseif nt==1 && nt2>1
    a = permute(a,[1 2 4 3]);
    nt = nt2;
    ncol = 1;
else
    ncol = 1;
end
if ncol == 4
    if ~isempty(alpha)
        error 'transparency defined twice!'
    end
    alpha = a(:,:,4,:);
    a(:,:,4,:) = [];
    ncol = 3;
end

% file name
[fpath fbase fext] = fileparts(fname);
if isempty(fext)
    ext = 'png';
else
    ext = fext(2:end);
end
if nt>1 && ~fn_ismemberstr(ext,{'gif' 'tif' 'tiff'})
    if ~isempty(fpath), fpath = [fpath '/']; end
    fname = [fpath fbase '_'];
    lg = floor(log10(nt))+1;
    icode = ['%.' num2str(lg) 'i'];
end

% color image(s)
if ncol==3
    if zoom~=1
        error('no zoom allowed for color images')
    end
    a = permute(a,[2 1 3 4]); % (x,y) convention -> Matlab (y,x) convention
    alpha = permute(alpha,[2 1 3 4]);
    if ~isempty(alpha)
        if nt>1
            error 'saving multiple images with transparency not handled yet'
        end
        if ~strcmp(ext,'png')
            error('transparency not handled for image type %s', ext)
        end
        imwrite(a,fname,'png','Alpha',alpha)
    elseif nt==1
        imwrite(a,fname,ext);
    elseif strcmp(ext,'gif')
        error 'true color multi-frame gif are not supported'
        imwrite(a,fname,ext,'delaytime',delaytime)
    elseif fn_ismemberstr(ext,{'tif' 'tiff'})
        disp('case nt>1 and ncol==3 has problems with tiff images')
        fn_progress('saving image',nt)
        for i=1:nt
            fn_progress(i)
            if i==1, writemode = 'overwrite'; else writemode = 'append'; end
            try
                imwrite(a(:,:,:,i),fname,'WriteMode',writemode)
            catch
                pause(.5)
                imwrite(a(:,:,:,i),fname,'WriteMode',writemode)
            end
        end
    else
        fn_progress('saving image',nt)
        for i=1:nt
            fn_progress(i)
            name = [fname num2str(i,icode) '.' ext];
            imwrite(a(:,:,:,i),name)
        end
    end
    return
elseif ~isempty(alpha)
    if zoom~=1
        error('no zoom allowed for images with transparency')
    elseif nt>1
        error 'saving multiple images with transparency not handled yet'
    elseif ~strcmp(ext,'png')
        error('transparency not handled for image type %s', ext)
    end
    a = a'; % (x,y) convention -> Matlab (y,x) convention
    alpha = alpha';
    imwrite(a,fname,'png','Alpha',alpha)
end

% clipping
if isequal(clip,'auto')
    switch class(a)
        case {'single' 'double'}
            clip = 'fit';
        case 'uint8'
            clip = 'none';
        otherwise
            % what would be the most intuitive choice here? i am not sure
            if ismember(ext,{'tif' 'tiff'})
                clip = 'none';
            else
                clip = 'fit';
            end
    end
end
if ~isequal(clip,'none')
    a = double(a);
    a = fn_clip(a,clip);
end

% zoom parameters
if zoom~=1
    if zoom<1, disp('zoom<1 does not bin but only interpolates'), end
    if zoom>1 && mod(zoom,1)==0
        disp('integer zoom enlarges without interpolating')
        zf = true;
        ii = kron(1:ni,ones(1,zoom));
        jj = kron(1:nj,ones(1,zoom));
    else
        zf = false;
        [jj ii] = meshgrid(.5:nj-.5,.5:ni-.5);
        [jj2 ii2] = meshgrid((.5:nj*zoom-.5)/zoom,(.5:ni*zoom-.5)/zoom);
    end
end

% special: gif
if nt>1 && strcmp(ext,'gif')
    a = permute(a,[2 1 4 3]);
    % better convert to uint8 now, otherwise shit happens
    switch class(a)
        case {'double' 'single'}
            a = uint8(255*a);
        case 'uint8'
            % nothing to do
        case 'uint16'
            a = uint8(a/256);
        otherwise
            error('number type ''%s'' not handled for gif saving',class(a))
    end
    if zoom~=1
        if ~zf, error 'interpolated zooming not implemented for gif saving', end
        a = a(jj,ii,:,:);
    end
    if ~isempty(cmap)
        if ischar(cmap), cmap = feval(cmap,256); end
        imwrite(a,cmap,fname,ext,'delaytime',delaytime,'loopcount',inf)
    else
        imwrite(a,fname,ext,'delaytime',delaytime,'loopcount',inf)
    end
    return
end

% special: tiff
if ismember(ext,{'tif' 'tiff'})
    if ncol~=1, error 'programming: case ncol==3 should be handled above', end
    fn_progress('saving image',nt)
    for i=1:nt
        fn_progress(i)
        if i==1, writemode = 'overwrite'; else writemode = 'append'; end
        try
            imwrite(a(:,:,i),fname,'WriteMode',writemode)
        catch
            pause(.5)
            imwrite(a(:,:,i),fname,'WriteMode',writemode)
        end
    end
    %     do_big = numel(a)>2.5e6; % more than ten 500x500 images
    %     if do_big
    %         t = Tiff(fname,'w');
    %     else
    %         t = Tiff(fname,'w8');
    %     end
    %     switch ncol
    %         case 1
    %             t.setTag('Photometric',Tiff.Photometric.MinIsBlack);
    %         case 3
    %             t.setTag('Photometric',Tiff.Photometric.RGB);
    %     end
    %     switch class(a)
    %         case 'logical'
    %             t.setTag('SampleFormat',Tiff.SampleFormat.UInt)
    %             t.setTag('BitsPerSample',1);
    %         case 'uint8'
    %             t.setTag('SampleFormat',Tiff.SampleFormat.UInt)
    %             t.setTag('BitsPerSample',8);
    %         case 'uint16'
    %             t.setTag('SampleFormat',Tiff.SampleFormat.UInt)
    %             t.setTag('BitsPerSample',16);
    %         case 'uint32'
    %             t.setTag('SampleFormat',Tiff.SampleFormat.UInt)
    %             t.setTag('BitsPerSample',32);
    %         case 'int8'
    %             t.setTag('SampleFormat',Tiff.SampleFormat.Int)
    %             t.setTag('BitsPerSample',8);
    %         case 'int16'
    %             t.setTag('SampleFormat',Tiff.SampleFormat.Int)
    %             t.setTag('BitsPerSample',16);
    %         case 'int32'
    %             t.setTag('SampleFormat',Tiff.SampleFormat.Int)
    %             t.setTag('BitsPerSample',32);
    %         case 'single'
    %             t.setTag('SampleFormat',Tiff.SampleFormat.IEEEFP)
    %             t.setTag('BitsPerSample',32);
    %         case 'double'
    %             t.setTag('SampleFormat',Tiff.SampleFormat.IEEEFP)
    %             t.setTag('BitsPerSample',64);
    %         otherwise
    %             error('number type ''%s'' not handled for tiff saving',class(a))
    %     end
    %     t.setTag('Compression',Tiff.Compression.None);
    %     t.setTag('ImageLength',nj*zoom); % not sure whether needed
    %     t.setTag('ImageWidth',ni*zoom);
    %     % note that ncol==3 and nt>1 together cause an error, but this case is
    %     % handled above
    %     t.setTag('SamplesPerPixel',ncol*nt);
    %     a = permute(a,[2 1 4 3]);
    %     if zoom~=1
    %         if ~zf, error 'interpolated zooming not implemented for gif saving', end
    %         a = a(jj,ii,:,:);
    %     end
    %     t.setTag('PlanarConfiguration',Tiff.PlanarConfiguration.Chunky) % not sure what this does
    %     t.setTag('Software','MATLAB')
    %     t.write(a)
    return
end

% saving
if nt>1
    fn_progress('saving image',nt)
end
for i=1:nt
    if nt>1
        fn_progress(i)
        name = [fname num2str(i,icode) '.' ext];
    else
        name = fname;
    end
    fr = a(:,:,i)'; % (x,y) convention -> Matlab (y,x) convention
    if zoom~=1
        if zf
            fr = fr(jj,ii);
        else
            fr = interp2(jj,ii,fr,jj2,ii2,'*spline');
            fr = min(max(fr,0),.999);
        end
    end
    if ~isempty(cmap)
        if ischar(cmap), cmap = feval(cmap,256); end
        fr = floor(size(cmap,1)*fr)+1;
        fr = reshape(cat(3,cmap(fr,1),cmap(fr,2),cmap(fr,3)),nj*zoom,ni*zoom,3);
    else % gray image
        %fr = floor(length(map)*fr)+1;
    end
    imwrite(fr,name,fn_switch(ext,'eps','psc2',ext))
end

