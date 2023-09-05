function [y] = my_resample(x, fs2, fs1)
% converts the vector x with sample rate fs1
% to the vector y with sample rate fs2

l = floor(fs2/fs1*length(x));
y = zeros(l, 1);
for m = 1:l
    y(m) = x.'*sinc((m-1)*fs1/fs2-[0:length(x)-1]');
end
end

