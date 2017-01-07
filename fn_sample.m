function idx = fn_sample(p,nsample)
% function idx = fn_sample(p,nsample|size)
%---
% Draw samples, i.e. indices from 1 to length(p), from distribution p

if nargin<2, nsample=1; end

if isscalar(nsample)
    siz = [1 nsample];
else
    siz = nsample;
    nsample = prod(siz);
end

p = p/sum(p);
idx = 1 + sum(bsxfun(@gt,rand(1,nsample),cumsum(p(:))));
idx = reshape(idx,siz);

