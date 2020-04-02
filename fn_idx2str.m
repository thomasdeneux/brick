function str = fn_idx2str(val,delimiters)
%FN_IDX2STR Convert indices to a compact string representation, e.g. '1:2 5:8' for [1 2 5 6 7 8] 
%---
% function str = fn_idx2str(val[,delimiters])
%---
% Converts a vector of indices into a string in a 'smart' way.
%
% Input:
% - val         vector of positive integers
% - delimiters  2 delimiting characters [default: ': ', a common
%               alternative would be '-,']
%
% Example:
% fn_idx2str([1 2 3 4 6 8 10 15]) returns '1:4 6:2:10 15'

% Thomas Deneux
% Copyright 2015-2017

if nargin<2, delimiters = ': '; end
cont = delimiters(1);
sep = delimiters(2);

d = diff(val);
if isempty(val)
    str = '';
elseif any(d==1)
    % first look for segments with successive integers
    k = find(d==1,1,'first');
    dk = d(k+1:end);
    n = find(dk~=1,1,'first'); if isempty(n), n = length(dk)+1; end
    if k>1, str = [fn_idx2str(val(1:k-1)) sep]; else str = ''; end
    str = [str num2str(val(k)) cont num2str(val(k+n))];
    if k+n<length(val), str = [str sep fn_idx2str(val(k+n+1:end))]; end
elseif any(diff(d)==0) && cont==':'
    k = find(diff(d)==0,1,'first');
    dk = d(k+1:end);
    n = find(dk~=d(k),1,'first'); if isempty(n), n = length(dk)+1; end
    if k>1, str = [fn_idx2str(val(1:k-1)) sep]; else str = ''; end
    str = [str num2str(val(k)) ':' num2str(d(k)) ':' num2str(val(k+n))];
    if k+n<length(val), str = [str sep fn_idx2str(val(k+n+1:end))]; end
else
    str = num2str(val);
    str = regexprep(str,' *',' ');
end

end
