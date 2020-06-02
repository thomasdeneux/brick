function a = fn_readtext(filename)
% function a = fn_readtext([filename])
%---
% Input:
% - a           char array
% - filename    file name
%
% See also fn_savetext, fn_readasciimatrix

% Thomas Deneux
% Copyright 2005-2017

a = {};

if nargin<1, filename=fn_getfile; end
if filename==0, return, end 

fid=fopen(filename,'r');
if filename==-1, disp(['Could not open file ' filename]), return, end 

line = fgetl(fid);
while ~isequal(line,-1)
    a{end+1,1} = line; %#ok<AGROW>
    line = fgetl(fid);
end

fclose(fid);