f = 1;
l = 1e4;
t = linspace(0, 10, l)';
sig = exp(j*2*pi*f*t);

noise = randn(l, 1)/2+j*randn(l, 1)/2;
recv = sig+noise;


figure(10);
plot(real(recv));