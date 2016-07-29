function fn_ticks(xticklabel,yticklabel)
% function fn_ticks(xticklabel,yticklabel)
%---
% Shortcut for
% set(gca,'xtick',1:length(xticklabel),'xticklabel',xticklabel, ...
%     'xtick',1:length(xticklabel),'xticklabel',xticklabel)

if ~isequal(xticklabel,[])
    set(gca,'xtick',1:length(xticklabel),'xticklabel',xticklabel)
end
if nargin>=2 && ~isequal(yticklabel,[])
    set(gca,'ytick',1:length(yticklabel),'yticklabel',yticklabel)
end