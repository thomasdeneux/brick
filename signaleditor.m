classdef signaleditor < hgsetget
    % function x = signaleditor.edit([ik,xk][,ha])
    % function E = signaleditor([ik,xk][,ha][,callback][,do_callback_when_move] ...
    %       [,'monotonous'][,'min',min][,'max',max])
    %---
    % Edit a signal defined by values xk at indices ik by creating / moving
    % / deleting interpolation points and return the interpolated signal x.
    %
    % Input:
    % - ik  Indices of interpolation points. Values in ik must be
    %       increasing, ik(1) must be equal to 1 and ik(end) must be an
    %       integer.
    % - xk  Interpolation values (vector of the same length as ik). Default
    %       values for ik and xk are ik = [1 256] and xk = [0 1].
    % - ha  Handle of axes where to perform the interpolation (default
    %       behavior is to create a new axes inside a new figure).
    % - callback    Callback to execute whenever the function is edited.
    
    properties (Access = 'private')
        hf
        hf_created
        ha
        ii
        ok_button
        callback
        hp
        hl
    end
    properties
        do_callback_when_move = true;
        monotonous = false;
        min = -Inf;
        max = +Inf;
    end
    properties (SetAccess='private')
        ik
        xk
        done = false;
    end
    properties (Dependent, SetAccess='private')
        npoint
        x
    end

    % Constructor, destructor
    methods
        function E = signaleditor(varargin)
            % input
            i = 0;
            while i < length(varargin)
                i = i+1;
                a = varargin{i};
                if isnumeric(a) && ~isscalar(a)
                    [E.ik, E.xk] = deal(a, varargin{i+1});
                    i = i+1;
                elseif ishandle(a)
                    E.ha = a;
                elseif isa(a,'function_handle')
                    E.callback = a;
                elseif isnumeric(a) && isscalar(a)
                    E.do_callback_when_move = a;
                elseif ischar(a) 
                    switch a
                        case 'monotonous'
                            E.monotonous = true;
                        case 'min'
                            E.min = varargin{i+1};
                            i = i+1;
                        case 'max'
                            E.max = varargin{i+1};
                            i = i+1;
                        otherwise
                            error('unknown flag ''%s''', a)
                    end
                else
                    error argument
                end
            end
            
            % check input points
            if isempty(E.ik)
                [E.ik, E.xk] = deal([1 256], [0 1]);
            end
            if ~isvector(E.ik) || length(E.ik)<2 || length(E.xk)~=length(E.ik) ...
                    || E.ik(1)~=1 || mod(E.ik(end),1) || any(diff(E.ik)<=0)
                error 'Input indices must be increasing, start at 1 and finish on an integer value. Input values must be a vector of same length as input indices.'
            end
            E.ii = E.ik(1):E.ik(end);
            
            % axes
            if isempty(E.ha)
                E.hf_created = fn_figure('Signal Editor');
                E.ha = axes('parent',E.hf_created);
            end
            addlistener(E.ha,'ObjectBeingDestroyed',@(u,e)delete(E))
            E.hf = fn_parentfigure(E.ha);
            
            % init edition
            E.init_edition()
            
            % ok button if local figure and no callback
            if isempty(E.callback) && ~isempty(E.hf_created)
                E.ok_button = uicontrol('String','Ok','parent',E.hf_created, ...
                    'callback',@(u,e)set(E,'done',true));
                fn_controlpositions(E.ok_button, E.hf_created, [1 0], [-40 10 30 20])
            end
        end
        function delete(E)
            deleteValid(E.hf_created)
        end
    end
    
    % Interpolation
    methods
        function n = get.npoint(E)
            n = length(E.ik);
        end
        function x_out = interp(E,x_in)
            % cut set of interpolation points in subsets without repetition
            % of the same point
            repeats = (diff(E.ik) == 0);
            bounds = [0 find(repeats) E.npoint];
            x_out = NaN(size(x_in));
            for k = 1:length(bounds)-1
                idxk = bounds(k)+1:bounds(k+1);
                if isscalar(idxk), continue, end % interpolation point alone: either a doubled extremity, or a tripled point!
                ix = (x_in>=E.ik(bounds(k)+1) & x_in<=E.ik(bounds(k+1)));
                x_out(ix) = interp1(E.ik(idxk),E.xk(idxk),x_in(ix),'pchip');
            end
            % note that the code above might assign non-extremal values to
            % extremal points, correct this
            if repeats(1)
                x_out(x_in==E.ik(1)) = E.xk(1);
            end
            if repeats(end)
                x_out(x_in==E.ik(end)) = E.xk(end);
            end
        end
        function x = get.x(E)
            x = E.interp(E.ii);
        end
    end
    
    % User interface for manual edition
    methods (Access = 'private')
        function init_edition(E)
            E.hl = plot(E.ii,E.x,'parent',E.ha, ...
                'buttondownfcn',@(u,e)edit_points(E,'line'));
            E.hp = line(E.ik,E.xk,'parent',E.ha, ...
                'linestyle','none','marker','s','markerfacecolor','b', ...
                'buttondownfcn',@(u,e)edit_points(E,'point'));
            set(E.ha,'xlim',[E.ik(1) E.ik(end)])
            E.update_display()
        end
        function update_display(E)
            set(E.hp,'xdata',E.ik,'ydata',E.xk)
            signal = E.x;
            set(E.hl,'ydata',signal)
            range = [min(signal) max(signal)];
            set(E.ha,'ylim',mean(range) + [-1 1]*diff(range)*.6)
        end
        function edit_points(E,flag)
            % index of closer point
            p = get(E.ha,'CurrentPoint'); p = p(1, 1:2);
            [~, idx] = min(abs(E.ik - p(1)));
            
            % different actions
            selection_type = get(E.hf,'SelectionType');
            switch flag
                case 'point'
                    if strcmp(selection_type,'normal')
                        % move point
                        E.move_point(idx)
                    else
                        % remove point
                        % warning: we cannot remove extremal points, remove
                        % the closest one instead
                        if idx == 1
                            if E.npoint == 2, return, else idx = 2; end
                        elseif idx == E.npoint
                            if E.npoint == 2, return, else idx = E.npoint-1; end
                        end
                        E.ik(idx) = [];
                        E.xk(idx) = [];
                        E.update_display()
                        if ~isempty(E.callback), E.callback(E.x), end
                    end
                case 'line'
                    % insert point and move it
                    
                    % insertion index: depend on whether we are on the left
                    % of right of the closer point
                    insertion_idx = idx + (p(1) > E.ik(idx));
                    insertion_idx = max(2, min(length(E.ik), insertion_idx));
                    
                    % insert point
                    E.ik = [E.ik(1:insertion_idx-1) p(1) E.ik(insertion_idx:end)];
                    E.xk = [E.xk(1:insertion_idx-1) p(2) E.xk(insertion_idx:end)];
                    E.update_display()
                    if ~isempty(E.callback) && E.do_callback_when_move
                        E.callback(E.x)
                    end
                    
                    % move it
                    E.move_point(insertion_idx)
            end
        end
        function move_point(E,idx)
            
            % constraints
            if idx > 1 && idx < E.npoint
                [i_min, i_max] = deal(E.ik(idx-1), E.ik(idx+1));
            end
            [x_min, x_max] = deal(E.min, E.max);
            if E.monotonous
                if idx > 1, x_min = E.xk(idx-1); end
                if idx < E.npoint, x_max = E.xk(idx+1); end
            end
            
            function update()
                p = get(E.ha,'CurrentPoint'); p = p(1,1:2);
                if idx > 1 && idx < E.npoint
                    E.ik(idx) = fn_coerce(p(1),i_min,i_max);
                end
                E.xk(idx) = fn_coerce(p(2), x_min, x_max);
                %disp([E.ik; E.xk])
                E.update_display()
                if ~isempty(E.callback) && E.do_callback_when_move
                    E.callback(E.x)
                end
            end
            
            fn_buttonmotion(@update)
            if ~isempty(E.callback) && ~E.do_callback_when_move
                E.callback(E.x)
            end
            
        end
    end
    
    % Static method
    methods (Static)
        function x = edit(varargin)
            % launch signal editor
            E = signaleditor(varargin{:});
                    
            % wait for done
            waitfor(E,'done',true)
            
            % get interpolated signal
            x = E.x;
            
            % delete editor
            delete(E)
        end
    end

end
