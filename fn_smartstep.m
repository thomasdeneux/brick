function step = fn_smartstep(maxstep)
% function step = fn_smartstep(maxstep)
% ---
% find the largest value that is <= maxstep and equal to 1, 2 or 5 times a
% power of 10

pow10 = floor(log10(maxstep));
maxstep = maxstep / 10^pow10; % we have 1 <= maxstep < 10

if maxstep < 2
    step = 10^pow10;
elseif maxstep < 5
    step = 2 * 10^pow10;
elseif maxstep < 10
    step = 5 * 10^pow10;
end