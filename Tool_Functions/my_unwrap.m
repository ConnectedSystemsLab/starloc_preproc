function [y] = my_unwrap(x)
% x: angle vector
% y: the non-increasing version of x

y = x;
for idx = 1:length(x)-1
    while y(idx) <= y(idx+1)
        y(idx+1) = y(idx+1)-2*pi;
    end
end
end

