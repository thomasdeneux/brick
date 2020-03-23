classdef white2alpha < interface
    % function white2alpha(image)
    % function white2alpha([filename])
    %---
    % Convert image white background to transparency

    properties (SetAccess='private')
        controls
        filename
        input
        lumspecial
        saturation
        checker
        truecolor
        alpha
        image_subpart
        nx
        ny
        nc
    end
    properties (SetObservable)
        dosubimage = false;
    end
    properties (Access='private')
        menu_def_subpart
        im = struct;
        image_subpart_mark
    end

    methods
        function X = white2alpha(varargin)

            X = X@interface(917,'WHITE2ALPHA');

            % Graphic objects
            X.grob = struct;
            X.grob.controls = uipanel;
            X.grob.input = axes;
            X.grob.masks = axes;
            X.grob.truecolor = axes;
            X.grob.alpha = axes;
            X.grob.result = axes;
            X.interface_end()

            % Controls
            s = struct(...
                'outside__max__luminance',  {.99    'slider .8 1 .01 %.2f'}, ...
                'holes',                    {false  'logical'}, ...
                'flat__colors',             {true   'logical'}, ...
                'border__typical__width',   {5      'slider 1 20 1'}, ...
                'flat__color__tolerance',   {.01    'slider 0 .1 .005 %.2f < flat__colors'}, ...
                'border__max__luminance',   {.5     'slider 0 1 .005 %.2f < ~flat__colors'}, ...
                'border__max__saturation',  {.5     'slider 0 1 .005 %.2f < ~flat__colors'}, ...
                'final__alpha__smooth',            {false  'logical'}, ...
                'true__color__smoothing',   {0      'slider 0 1 < ~final__alpha__smooth'}, ...
                'SAVE',                {[]     {'push' 'save'}});
            X.controls = fn_control(s,@(s)X.action(s),X.grob.controls);

            % Load image and perform conversion
            X.load_image(varargin{:})
        end
        function load_image(X, a)
            % Input
            if nargin<2
                a = fn_getfile('*','Select image');
            end
            while ischar(a)
                X.filename = a;
                [a, alph] = fn_readimg(a);
                switch class(a)
                    case 'double'
                        ok = all(alph(:)==1);
                    case 'uint8'
                        % convert to double
                        a = double(a) / 255;
                        ok = all(alph(:)==uint8(255));
                        alph = double(alph) / 255;
                    otherwise
                        error('type %s not handled yet, please edit code', class(a))
                end
                if ~ok
                    answer = questdlg('Image already has an alpha channel, what do you want to do?', ...
                        'white2alpha','Use image','Use image weighted by alpha','Other image','Use image weighted by alpha');
                    if isempty(answer)
                        % interrupt, close window
                        close(X.hf)
                        return
                    end
                    switch answer
                        case 'Use image'
                            % use a as is
                        case 'Use image weighted by alpha'
                            a = fn_mult(a, alph)  + (1-alph);
                        case 'Other image'
                            a = fn_getfile('*','Select image');
                    end
                end
            end
            X.input = a;

            % Some precomputations
            [X.nx, X.ny, X.nc] = size(X.input);
            if X.nc == 3
                [~, X.saturation, X.lumspecial] = rgb2hsv(X.input);
                % replace luminance by darkest channel!
                X.lumspecial = min(X.input,[],3);
            elseif X.nc == 1
                X.saturation = 0;
                X.lumspecial = X.input;
            else
                error 'input image must have 1 or 3 color channels'
            end
            step = round(mean([X.nx X.ny])/15);
            xstripes = mod(floor((0:X.nx-1)'/step),2);
            ystripes = mod(floor((0:X.ny-1)/step),2);
            X.checker = bsxfun(@xor,xstripes,ystripes);
            X.checker = .4 + .2*X.checker;

            % Show images
            colormap(X.hf,gray(256))
            imagesc(permute(X.input,[2 1 3]),'parent',X.grob.input,[0 1])
            axis(X.grob.input,'image')
            set(X.grob.input,'xtick',[],'ytick',[],'box','on')
            title(X.grob.input,'Input')
            X.im.masks = imagesc(permute(X.input,[2 1 3]),'parent',X.grob.masks);
            axis(X.grob.masks,'image')
            set(X.grob.masks,'xtick',[],'ytick',[],'box','on')
            title(X.grob.masks,'Outside & border masks')
            X.im.truecolor = imagesc(permute(X.input,[2 1 3]),'parent',X.grob.truecolor,[0 1]);
            axis(X.grob.truecolor,'image')
            set(X.grob.truecolor,'xtick',[],'ytick',[],'box','on')
            title(X.grob.truecolor,'True color')
            X.im.alpha = imagesc(permute(X.input,[2 1 3]),'parent',X.grob.alpha,[0 1]);
            axis(X.grob.alpha,'image')
            set(X.grob.alpha,'xtick',[],'ytick',[],'box','on')
            title(X.grob.alpha,'Alpha')
            X.im.result = imagesc(permute(X.input,[2 1 3]),'parent',X.grob.result,[0 1]);
            axis(X.grob.result,'image')
            set(X.grob.result,'xtick',[],'ytick',[],'box','on')
            title(X.grob.result,'Result')
            fn_imvalue image

            % Perform conversion
            X.performconversion()
        end
        function init_menus(X)
            init_menus@interface(X)

            % Load image
            m = X.menus.interface;
            uimenu(m,'label','Load image...','separator','on', ...
                'callback',@(u,e)load_image(X))

            % Image sub-part
            m = uimenu(X.hf,'label','Sub-Image');
            X.menus.image_sub_part = m;
            fn_propcontrol(X,'dosubimage','menu', ...
                'parent',m,'label','Apply to image sub-part');
            X.menu_def_subpart = uimenu(m, ...
                'label','Define new image sub-part', ...
                'enable', onoff(X.dosubimage), ...
                'callback',@(u,e)set_image_subpart(X));
        end
        function set.dosubimage(X,b)
            X.dosubimage = b;
            set(X.menu_def_subpart,'enable',fn_switch(b))
            if X.dosubimage && isempty(X.image_subpart)
                set_image_subpart(X)
            end
            set(X.image_subpart_mark,'visible',b)
        end
        function set_image_subpart(X)
            deleteValid(X.image_subpart_mark)
            poly = fn_mouse(X.grob.result,'poly','select image sub-part');
            poly = poly(:,[1:end 1]);
            X.image_subpart_mark = fn_drawpoly(poly,'parent',X.grob.result,'color','w');
            X.image_subpart = fn_poly2mask(poly(1,:),poly(2,:),X.nx,X.ny);
        end
        function action(X, s)
            if ischar(s)
                % special action
                switch s
                    case 'save'
                        X.save()
                    otherwise
                        error 'argument'
                end
            else
                % parameter change
                X.performconversion()
            end
        end
        function performconversion(X)
            c = fn_watch(X.hf);

            % Inside and outside masks
            outside = (X.lumspecial > X.controls.outside__max__luminance);
            if ~X.controls.holes
                % consider only connected components of "outside" that
                % contain some border of the image
                labels = bwlabel(outside);
                ok_labels = unique([row(labels([1 end],:)) row(labels(:,[1 end]))]);
                outside = outside & ismember(labels,ok_labels);
            end
            if X.controls.flat__colors
                darkness = 1 - X.lumspecial;
                spread = round(X.controls.border__typical__width);
                local_max_darkness = imdilate(darkness,true(spread));
                inside = (darkness > local_max_darkness * (1-X.controls.flat__color__tolerance));
                inside = inside & ~outside;
            else
                inside = (X.lumspecial < X.controls.border__max__luminance);
                if X.nc == 3
                    inside = inside | (X.saturation > X.controls.border__max__saturation);
                end
            end
            border = ~(inside | outside);

            % border must touch outside
            labels = bwlabel(border);
            ok_labels = unique(labels(bwmorph(outside,'dilate')));
            border = border & ismember(labels,ok_labels);

            % border must not be further than a given distance to outside
            border = border & bwmorph(outside,'dilate',round(X.controls.border__typical__width));
            inside = ~(border | outside);

            a = fn_imvect(X.input,'vector');
            a(outside(:),1:2) = 1;
            a(outside(:),3) = 0;
            a(border,:) = 0;
            a = fn_imvect(a,[X.nx X.ny],'image');
            set(X.im.masks,'cdata',permute(a,[2 1 3]))

            % Stop here if slider is being moved
            if X.controls.sliderscrolling
                return
            end

            % True color of semitransparent pixels obtained by smoothing
            % of inside
            sigma = 4 * X.controls.border__typical__width;
            negative_inside = fn_mult(1 - X.input, inside);
            negative_inside_smooth = fn_filt(negative_inside,sigma,'l',[1 2]);
            inside_mask_smooth = fn_filt(inside,sigma,'l',[1 2]);
            negative_inside_spread = fn_div(negative_inside_smooth, inside_mask_smooth);
            inside_spread = fn_clip(1 - negative_inside_spread, [0 1]);
            inside_spread = fn_imvect(inside_spread,'vector');
            xtruecolor = fn_imvect(X.input,'vector');
            truecolor_border = inside_spread(border, :);

            % Transparency of border pixels obtained as the ratio of input
            % image darkness as compared to true color darkness
            input_border = fn_imvect(X.input,border,'vector');
            darkness = 1 - mean(input_border,2);
            truecolor_border_darkness = 1 - mean(truecolor_border,2);
            alpha_border = fn_clip(darkness ./ truecolor_border_darkness, [0 1]);
            xalpha = double(inside);
            xalpha(border) = alpha_border;

            % final smoothing of alpha
            if X.controls.final__alpha__smooth
                xalpha = fn_filt(xalpha,3,'l',[1 2]);
                e = 1e-2;
                xalpha(xalpha<e) = 0;
                xalpha(xalpha>1-e) = 1;
                % -> this extends 'border'
                inside = (xalpha == 1);
                outside = (xalpha == 0);
                border = ~inside & ~outside;
                % repeat previous computation
                input_border = fn_imvect(X.input,border,'vector');
                darkness = 1 - mean(input_border,2);
                truecolor_border = inside_spread(border, :);
                truecolor_border_darkness = 1 - mean(truecolor_border,2);
                alpha_border = fn_clip(darkness ./ truecolor_border_darkness, [0 1]);
            end
            xtruecolor(outside, :) = 1;

            % True color can be improved where alpha is large enough so we
            % can trust the pixel color
            %  we have:    input = alpha * truecolor + (1-alpha)
            %  hence:      truecolor = 1 - (1 - input)/alpha
            truecolor_border2 = fn_clip(1 - fn_div(1-input_border,alpha_border), [0 1]);
            truecolor_border2(alpha_border==0, :) = 1;
            smooth = X.controls.true__color__smoothing;
            if ~ismember(smooth, [0 1])
                smooth = alpha_border .^ atanh(1-smooth);
            end
            xtruecolor(border, :) = fn_mult(smooth,truecolor_border) + fn_mult(1-smooth,truecolor_border2);

            % true color
            xtruecolor = fn_imvect(xtruecolor,[X.nx X.ny],'image');

            % Display result on top of a checkerboard
            if X.dosubimage
                X.truecolor = fn_imvect(X.truecolor);
                xtruecolor = fn_imvect(xtruecolor);
                X.truecolor(X.image_subpart(:),:) = xtruecolor(X.image_subpart(:),:);
                X.truecolor = fn_imvect(X.truecolor,[X.nx X.ny]);
                X.alpha(X.image_subpart) = xalpha(X.image_subpart);
            else
                X.truecolor = xtruecolor;
                X.alpha = xalpha;
            end
            b = fn_add(fn_mult(X.truecolor,X.alpha), X.checker.*(1-X.alpha));
            set(X.im.truecolor,'cdata',permute(X.truecolor,[2 1 3]))
            set(X.im.alpha,'cdata',permute(X.alpha,[2 1 3]))
            set(X.im.result,'cdata',permute(b,[2 1 3]))
        end
        function save(X)
            % file name
            if isempty(X.filename)
                fsave = '*.png';
            else
                fsave = [fn_fileparts(X.filename,'base') ' - transparency.png'];
            end
            fsave = fn_savefile(fsave,'Save image with transparency as');

            % save image
            xtruecolor = X.truecolor;
            if size(xtruecolor,3)==1
                xtruecolor = repmat(xtruecolor,[1 1 3]);
            end
            a = cat(3,xtruecolor,X.alpha);
            fn_saveimg(a,fsave)
        end
    end

end