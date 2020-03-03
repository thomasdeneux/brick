function output = fn_geometry(operationName,varargin)
%FN_GEOMETRY    geometry operations not implemented in matlab or implemented in
%               toolboxes
%---
% function output = fn_geometry(operationName,varargin)
%	operationName:  - doBoundingBoxesIntersect
%                   - doSegmentsIntersect
%                   - getBoundingBox
%                   - getIntersectionOfTwoSegments
%                   - isPointOnLine
%                   - isPointRightOfLine
%                   - lineSegmentTouchesOrCrossesLine
%---
% 
% Input:
% - operationName   name of the geometric operation 
%                   
% - varargin        see the specific operation below to know the input arguments
%                   to provide
%
% Output:
% - output          see the specific operation below to know the output
%                   types

switch operationName
	case "doBoundingBoxesIntersect"
        % return true if rectangle a and b cross each other
        % rectangles must be defined by a diagonal
        % 
        % @param a, b: 2x2 double, with points in columns and x,y
        % coordinates in lines
        % @return output: boolean
        a = varargin{1};
        b = varargin{2};
        
        output = a(1,1) <= b(1,2) ...
            && a(1,2) >= b(1,1) ...
            && a(2,1) <= b(2,2) ...
            && a(2,2) >= b(2,1) ...
        ;
        %disp("doBoundingBoxesIntersect: "+output)
	case "doSegmentsIntersect"
        % return true if lines a and b intersect
        %
        % @param a: 2x2 double, with points in columns and x,y
        % coordinates in lines
        % @param b: 2x2 double 
        % @return output: boolean
        a = varargin{1};
        b = varargin{2};
        
        boxA = fn_geometry('getBoundingBox',a);
        boxB = fn_geometry('getBoundingBox',b);
        
        output = fn_geometry('doBoundingBoxesIntersect',boxA,boxB) ...
            && fn_geometry('lineSegmentTouchesOrCrossesLine',a,b) ...
            && fn_geometry('lineSegmentTouchesOrCrossesLine',b,a) ...
        ;
        %disp("doLinesIntersect: "+output)
    case "getBoundingBox"
        % return bottom-left corner and top right corner of the bounding
        % box of a line
        %
        % @param a : 2x2 double with points in columns and with x, y coordinates in lines 
        % @return output: 2x2 double
        a = varargin{1};
        
        output = [
            min(a(1,1),a(1,2)), ...
            max(a(1,1),a(1,2)); ...
            min(a(2,1),a(2,2)), ...
            max(a(2,1),a(2,2)), ...
            ] ...
        ;
    case "getIntersectionOfTwoSegments"
        % return coordinates of intersection between two segments
        % the output is 2x2 because the intersection of two lines can be a
        % line
        % It will return something even is the two segments doesnt't touch
        % each other. It's recommended to use:
        % fn_geometry("doSegmentsIntersect",a,b) first.
        %
        % @param a: 2x2 double, with points in columns and x,y
        % coordinates in lines
        % @param b: 2x2 double
        % @return output: 2x2 double
        a = varargin{1};
        b = varargin{2};
        
        if a(1,1) == a(1,2)
            % Case (A)
            x1 = a(1,1);
            x2 = x1;
            if b(1,1) == b(1,2)
                % Case (AA): all x are the same!
                % Normalize
                if a(2,1) > a(2,2)
                   tmp = a;
                   a(:,1) = tmp(:,2);
                   a(:,2) = tmp(:,1);
                end
                if b(2,1) > b(2,1)
                   tmp = b;
                   b(:,1) = tmp(:,2);
                   b(:,2) = tmp(:,1);
                end
                if a(2,1) > b(2,1)
                  tmp = a;
                  a = b;
                  b = tmp;
                end
                % Now we know that the y-value of a["first"] is the 
                % lowest of all 4 y values
                % this means, we are either in case (AAA):
                % a: x--------------x
                % b:    x---------------x
                % or in case (AAB)
                % a: x--------------x
            	% b:    x-------x
            	% in both cases:
            	% get the relavant y intervall
                y1 = b(2,1);
                y2 = min(a(2,2), b(2,2));
            else
                % Case (AB)
                % we can mathematically represent line b as
                % y = m*x + t <=> t = y - m*x
                % m = (y1-y2)/(x1-x2)
                m = (b(2,1) - b(2,2)) / ...
                    (b(1,1) - b(1,2));
                t = b(2,1) - m*b(1,1);
                y1 = m*x1 + t;
                y2 = y1;
            end
           
        elseif b(1,1) == b(1,2)
            % Case (B)
        	% essentially the same as Case (AB), but with
            % a and b switched
            x1 = b(1,1);
            x2 = x1;

            tmp = a;
            a = b;
            b = tmp;

            m = (b(2,1) - b(2,2)) / ...
                (b(1,1) - b(1,2));
            t = b(2,1) - m*b(1,1);
            y1 = m*x1 + t;
            y2 = y1;
        else
            % Case (C)
            ma = (a(2,1) - a(2,2)) / ...
                (a(1,1) - a(1,2));
            mb = (b(2,1) - b(2,2)) / ...
                (b(1,1) - b(1,2));
            ta = a(2,1) - ma*a(1,1);
            tb = b(2,1) - mb*b(1,1);
            
            
            if ma == mb
            	% Case (CA)
            	% both lines are in parallel. As we know that they 
            	% intersect, the intersection could be a line
            	% when we rotated this, it would be the same situation 
            	% as in case (AA)

            	% Normalize
                if a(1,1) > a(2,1)
                    tmp = a;
                    a(:,1) = tmp(:,2);
                    a(:,2) = tmp(:,1);
                end
                if b(1,1) > b(1,2)
                    tmp = b;
                    b(:,1) = tmp(:,2);
                    b(:,2) = tmp(:,1);
                end
                if a(1,1) > b(1,1)
                    tmp = a;
                    a = b;
                    b = tmp;
                end

                % get the relavant x intervall
                x1 = b(1,1);
                x2 = min(a(1,2), b(1,2));
                y1 = ma*x1+ta;
                y2 = ma*x2+ta;
            else
                % Case (CB): only a point as intersection:
                % y = ma*x+ta
                % y = mb*x+tb
                % ma*x + ta = mb*x + tb
                % (ma-mb)*x = tb - ta
                % x = (tb - ta)/(ma-mb)
                x1 = (tb-ta)/(ma-mb);
                y1 = ma*x1+ta;
                x2 = x1;
                y2 = y1;
            end
   
        end
        
        output = [x1,x2;y1,y2];
    case "isPointOnLine"
        % return true if the point b is on the line a
        %
        % @param a: 1x2 double
        % @param b: 1x1 double
        % @return output: boolean
        a = varargin{1};
        b = varargin{2};
        
        aTmp = [a(1,2) - a(1,1); a(2,2)-a(2,1); 0];
        bTmp = [b(1,1) - a(1,1); b(2,1)- a(2,1); 0];
        r = cross(aTmp, bTmp);
        if abs(r) < 0.000001
            output = true;
        else
            output = false;
        end
        %disp("isPointOnLine: "+output)
    case "isPointRightOfLine"
        % return true if the point b is on the right of line a
        %
        % @param a: 1x2 double
        % @param b: 1x1 double 
        % @return output: boolean
        a = varargin{1};
        b = varargin{2};
        
        aTmp = [a(1,2) - a(1,1); a(2,2)-a(2,1); 0];
        bTmp = [b(1,1) - a(1,1); b(2,1)- a(2,1); 0];
        r = cross(aTmp, bTmp);
        if any(r<0)
            output = true;
        else
            output = false;
        end
        %disp("isPointRightOfLine: "+output)
    case "lineSegmentTouchesOrCrossesLine"
        % return if segment touches or crosses line
        %
        % @param a: 2x2 double, with points in columns and x,y
        % coordinates in lines
        % @param b: 2x2 double 
        % @return output: boolean
        a = varargin{1};
        b = varargin{2};
        
        output = fn_geometry('isPointOnLine',a,b(:,1)) ...
            || fn_geometry('isPointOnLine',a,b(:,2)) ...
            || xor(fn_geometry('isPointRightOfLine',a,b(:,1)) ...
            ,fn_geometry('isPointRightOfLine',a,b(:,2))) ...
        ;
        %disp("lineSegmentTouchesOrCrossesLine: "+output)
    otherwise
        % case not found
        error("fn_geometry used with an unknowned operation: "+operationName)
end

end


