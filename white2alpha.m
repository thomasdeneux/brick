 classdef white2alpha < interface
     % function white2alpha(image)
     % function white2alpha([filename])
     %---
     % Convert image white background to transparency

     properties (SetAccess='private')
         controls
         input
         luminance
         saturation
         checker
         truecolor
         alpha
         im = struct;
     end
     
     methods
         function X = white2alpha(a)
             
             X = X@interface(917,'WHITE2ALPHA');
             
             % Input
             if nargin<1
                 X.input = fn_getfile('Select image');
             end
             if ischar(a)
                 X.input = fn_readimg(a);
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
                 [~, X.saturation, X.luminance] = rgb2hsv(X.input);
             elseif nc == 1
                 X.saturation = 0;
                 X.luminance = X.input;
             else
                 error 'input image must have 1 or 3 color channels'
             end
             step = round(mean([nx ny])/15);
             xstripes = mod(floor((0:nx-1)'/step),2);
             ystripes = mod(floor((0:ny-1)/step),2);
             X.checker = bsxfun(@xor,xstripes,ystripes);
             X.checker = .4 + .2*X.checker;
             
             % Graphic objects
             X.grob = struct;
             X.grob.controls = uipanel;
             X.grob.input = axes;
             X.grob.masks = axes;
             X.grob.truecolor = axes;
             X.grob.alpha = axes;
             X.grob.result = axes;
             X.interface_end()
             
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
                 'flat__colors',             {false  'logical'}, ...
                 'border__typical__width',   {5      'slider 1 100'}, ...
                 'border__max__luminance',   {.5     'slider 0 1 .01 %.2f'}, ...
                 'border__max__saturation',  {.5     'slider 0 1 .01 %.2f'}, ...
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
             outside = (X.luminance > X.controls.outside__max__luminance);
             if X.controls.flat__colors
                 spread = 2 * X.controls.border__typical__width;
                 local_min_luminance = imerode(X.luminance,true(spread));
                 inside = (X.luminance < local_min_luminance * 1.01);
             else
                 inside = (X.luminance < X.controls.border__max__luminance);
                 if nc == 3
                     inside = inside | (X.saturation > X.controls.border__max__saturation);
                 end
             end
             border = ~(inside(:) | outside(:));
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
             sigma = 5;
             negative_inside = fn_mult(1 - X.input, inside);
             negative_inside_smooth = fn_filt(negative_inside,sigma,'l',[1 2]);         
             inside_mask_smooth = fn_filt(inside,sigma,'l',[1 2]);         
             negative_inside_spread = fn_div(negative_inside_smooth, inside_mask_smooth);
             inside_spread = fn_clip(1 - negative_inside_spread, [0 1]);
             inside_spread = fn_imvect(inside_spread,'vector');
             X.truecolor = fn_imvect(X.input,'vector');
             X.truecolor(outside, :) = 1;
             X.truecolor(border, :) = inside_spread(border, :);
             
             % Transparency of border pixels
             X.alpha = double(inside);
             X.alpha(border) = (1 - X.luminance(border)) ./ (1 - mean(X.truecolor(border,:),2));
             X.alpha = fn_clip(X.alpha,[0 1]);
             X.truecolor = fn_imvect(X.truecolor,[nx ny],'image');
             set(X.im.truecolor,'cdata',permute(X.truecolor,[2 1 3]))
             X.alpha = fn_imvect(X.alpha,[nx ny],'image');
             set(X.im.alpha,'cdata',permute(X.alpha,[2 1 3]))
             
             % Display result on top of a checkerboard
             b = fn_add(fn_mult(X.truecolor,X.alpha), X.checker.*(1-X.alpha));
             set(X.im.result,'cdata',permute(b,[2 1 3]))
         end
     end

 end