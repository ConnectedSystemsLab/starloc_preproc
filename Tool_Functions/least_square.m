function [k, b] = least_square(x, y)
% y = kx+b

if length(x) ~= length(y)
    error('input size does not match');
end
if ~ iscolumn(x)
    x = x.';
end
if ~ iscolumn(y)
    y = y.';
end

l = length(x);
A = [x ones(l, 1)];
tmp = inv(A'*A)*A'*y;
k = tmp(1);
b = tmp(2);
end

