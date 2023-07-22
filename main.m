clear all; clc;

%% parameters
setParam;

%% baseband transmit signal
[x, t] = getBasebandSig();
x_real = abs(x);
figure(1);
plot(t, x_real);
title('time-domain transmit signal');

%% TX
% frames appended by zeros and using carrier/center frequency (F_c) as 0 for
% simulations
% x_transmit = [zeros(100000, 1); x_real.*cos(2*pi*F_c*t+angle(x)); zeros(100000, 1)];

%% channel
SNR = 10;
% y = x_transmit / 5;     % attenuation
y = x / 4;              % attenuation
f_d = getDoppler('STARLINK-6089.tle', F_c, t(end));
f_d = f_d(ceil(t/t(end)*length(f_d)));
y = y.*exp(j*2*pi*f_d.*t);
y = awgn(y, SNR);

%% RX
% Receiver in the paper samples 62.5MHz of bandwidth => 240e6/62.5e6 ~ 4
y_receive = downsample(y, 4); 

%% test
% this will generate a figure similar to fig 3.
frame = 1;
y_slice = y((frame-1)*(N_sf+1)*N_sym+1:frame*(N_sf+1)*N_sym);
corr = xcorr(y_slice) / length(y_slice);
% figure(2);
% plot(mag2dB(abs(corr)), LineWidth=1);
% title('correlation: 1 frame');
corr_frames = xcorr(y_receive) / length(y_receive);
figure(3);
plot(mag2dB(abs(corr_frames)), LineWidth=1);
title('correlation: all frames');
xlim([length(corr_frames)/2 - N*2 length(corr_frames)/2 + N*2])
