function [y] = my_resample_2(x, fs2, fs1)
% converts the vector x with sample rate fs1
% to the vector y with sample rate fs2
% using frequency domain filter

f_tmp = lcm(fs1, fs2);
up_ratio = f_tmp/fs1;
down_ratio = f_tmp/fs2;

l = length(x);
l_up = l*up_ratio;


x_up = upsample(x, up_ratio);
x_up_fft = fft(x_up);
% Low Pass Filter with Gain = up_ratio
x_up_fft(round(l_up/up_ratio/2)+1:l_up-round(l_up/up_ratio/2)) = 0;
x_up_fft = up_ratio*x_up_fft;

x_tmp = ifft(x_up_fft);
y = downsample(x_tmp, down_ratio);
end

