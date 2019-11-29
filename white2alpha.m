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
         im = struct;
     end
     
     methods
         function X = white2alpha(a)
             
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
             
             % Input
             if nargin<1
                 a = fn_getfile('*','Select image');
             end
             if ischar(a)
                 X.filename = a;
                 a = fn_readimg(a);
             end
             switch class(a)
                 case 'double'
                     X.input = a;
                 case 'uint8'
                     % convert to double
                     X.input = double(a) / 255;
                 otherwise
                     error('type %s not handled yet, please edit code', class(a))
             end
             
             % Some precomputations
             [nx ny nc] = size(X.input);
             if nc == 3
                 [~, X.saturation, X.lumspecial] = rgb2hsv(X.input);
                 % replace luminance by darkest channel!
                 X.lumspecial = min(X.input,[],3);
             elseif nc == 1
                 X.saturation = 0;
                 X.lumspecial = X.input;
             else
                 error 'input image must have 1 or 3 color channels'
             end
             step = round(mean([nx ny])/15);
             xstripes = mod(floor((0:nx-1)'/step),2);
             ystripes = mod(floor((0:ny-1)/step),2);
             X.checker = bsxfun(@xor,xstripes,ystripes);
             X.checker = .4 + .2*X.checker;
             
             % Show images
             colormap(X.hf,gray(256))
             imagesc(permute(X.input,[2 1 3]),'parent',X.grob.input)
             axis(X.grob.input,'image')
             set(X.grob.input,'xtick',[],'ytick',[],'box','on')
             title(X.grob.input,'Input')
             X.im.masks = imagesc(permute(X.input,[2 1 3]),'parent',X.grob.masks);
             axis(X.grob.masks,'image')
             set(X.grob.masks,'xtick',[],'ytick',[],'box','on')
             title(X.grob.masks,'Outside & border masks')
             X.im.truecolor = imagesc(permute(X.input,[2 1 3]),'parent',X.grob.truecolor);
             axis(X.grob.truecolor,'image')
             set(X.grob.truecolor,'xtick',[],'ytick',[],'box','on')
             title(X.grob.truecolor,'True color')
             X.im.alpha = imagesc(permute(X.input,[2 1 3]),'parent',X.grob.alpha);
             axis(X.grob.alpha,'image')
             set(X.grob.alpha,'xtick',[],'ytick',[],'box','on')
             title(X.grob.alpha,'Alpha')
             X.im.result = imagesc(permute(X.input,[2 1 3]),'parent',X.grob.result);
             axis(X.grob.result,'image')
             set(X.grob.result,'xtick',[],'ytick',[],'box','on')
             title(X.grob.result,'Result')
             fn_imvalue image
             
             % Controls
             s = struct(...
                 'outside__max__luminance',  {.99    'slider .8 1 .01 %.2f'}, ...
                 'flat__colors',             {true   'logical'}, ...
                 'border__typical__width',   {5      'slider 1 20 1 < flat__colors'}, ...
                 'flat__color__tolerance',   {.01    'slider 0 .1 .005 %.2f < flat__colors'}, ...
                 'border__max__luminance',   {.5     'slider 0 1 .005 %.2f < ~flat__colors'}, ...
                 'border__max__saturation',  {.5     'slider 0 1 .005 %.2f < ~flat__colors'}, ...
                 'true__color__smoothing',   {0      'slider 0 1'}, ...
                 'SAVE',                {[]     {'push' 'save'}});
             X.controls = fn_control(s,@(s)X.action(s),X.grob.controls);
             X.performconversion()
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
             [nx ny nc] = size(X.input);
             
             % Inside and outside masks
             outside = (X.lumspecial > X.controls.outside__max__luminance);
             if X.controls.flat__colors
                 darkness = 1 - X.lumspecial;
                 spread = round(X.controls.border__typical__width);
                 local_max_darkness = imdilate(darkness,true(spread));
                 inside = (darkness > local_max_darkness * (1-X.controls.flat__color__tolerance));
                 inside = inside & ~outside;
             else
                 inside = (X.lumspecial < X.controls.border__max__luminance);
                 if nc == 3
                     inside = inside | (X.saturation > X.controls.border__max__saturation);
                 end
             end
             border = ~(inside | outside);
             a = fn_imvect(X.input,'vector');
             a(outside(:),1:2) = 1;
             a(outside(:),3) = 0;
             a(border,:) = 0;
             a = fn_imvect(a,[nx ny],'image');
             set(X.im.masks,'cdata',permute(a,[2 1 3]))
             
             % Stop here if slider is being moved
             if X.controls.sliderscrolling
                 return
             end
             
             % True color of semitransparent pixels obtained by smoothing
             % of inside
             sigma = 2 * X.controls.border__typical__width;
             negative_inside = fn_mult(1 - X.input, inside);
             negative_inside_smooth = fn_filt(negative_inside,sigma,'l',[1 2]);         
             inside_mask_smooth = fn_filt(inside,sigma,'l',[1 2]);         
             negative_inside_spread = fn_div(negative_inside_smooth, inside_mask_smooth);
             inside_spread = fn_clip(1 - negative_inside_spread, [0 1]);
             inside_spread = fn_imvect(inside_spread,'vector');
             X.truecolor = fn_imvect(X.input,'vector');
             X.truecolor(outside, :) = 1;
             truecolor_border = inside_spread(border, :);
             
             % Transparency of border pixels obtained as the ratio of input
             % image darkness as compared to true color darkness
             input_border = fn_imvect(X.input,border,'vector');
             darkness = 1 - mean(input_border,2);
             truecolor_border_darkness = 1 - mean(truecolor_border,2);
             alpha_border = fn_clip(darkness ./ truecolor_border_darkness, [0 1]);
             X.alpha = double(inside);
             X.alpha(border) = alpha_border;
             set(X.im.alpha,'cdata',permute(X.alpha,[2 1 3]))

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
             X.truecolor(border, :) = fn_mult(smooth,truecolor_border) + fn_mult(1-smooth,truecolor_border2);
             
             % Display truecolor and alpha
             X.truecolor = fn_imvect(X.truecolor,[nx ny],'image');
             set(X.im.truecolor,'cdata',permute(X.truecolor,[2 1 3]))
             
             % Display result on top of a checkerboard
             b = fn_add(fn_mult(X.truecolor,X.alpha), X.checker.*(1-X.alpha));
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
             a = cat(3,X.truecolor,X.alpha);
             fn_saveimg(a,fsave)
         end
     end

 end