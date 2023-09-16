function [info, d_sum] = QPSK_hard_decision(points)
num = length(points);
info = zeros(num, 1);
cons = [1 j -1 -j];
d_sum = 0;
for idx = 1:num

    ds = abs(points(idx)-cons);
    [d, min_idx] = min(ds);
    info(idx) = min_idx-1;
    d_sum = d_sum+d;
end
d_sum = d_sum/num;
end

