clear all; clc; close all;

%% parameters
addpath Tool_Functions/
setParam;

%% baseband transmit signal
[x, t] = getBasebandSig();

%% TX
% frames appended by zeros and using carrier/center frequency (F_c) as 0 for
% simulations
% x_transmit = [zeros(100000, 1); x_real.*cos(2*pi*F_c*t+angle(x)); zeros(100000, 1)];

%% doppler simulation
[f_d, elev, t_sat] = getDoppler('STARLINK-6089.tle', F_c, 100*t(end));

figure(2);
plot(t_sat, f_d/1e3);
title("Satellite Velocity Along the Line Between Sat and GS");
xlabel("Simulation Time (s)");
ylabel("Doppler Frequency Shift (kHz)");
grid on;

figure(3);
plot(t_sat, -elev);
title("Elevation of satellite during simulation");
xlabel("Simulation Time (s)");
ylabel("Elevation (degree)");
grid on;

%% channel
SNR = 12;
% y = x_transmit / 5;     % attenuation
y = x / 4;              % attenuation
% f_d = f_d(ceil(t/t(end)*length(f_d)));
% y = y.*exp(j*2*pi*f_d.*t);
y = awgn(y, SNR);
y = y / 10;
figure(1);
plot(t, mag2db(abs(y)));
title('time-domain received signal');

%% RX
% Receiver in the paper samples 62.5MHz of bandwidth => 240e6/62.5e6 ~ 4
% Our USRP samples 100MHz of bandwidth => 240e6/100e6 = 24:10
y_receive = resample(y, 10, 24);

%% pss + doppler test
pss = get_pss();
pss_dsamp = resample(pss, 10, 24);
corr_pss = xcorr(y_receive, pss_dsamp);
figure;
plot(mag2db(abs(corr_pss)));
xlim([length(y_receive), 2*length(y_receive)-1]);

t_dsamp = linspace(0, t(end), length(y_receive))';
f_d = 200e3;        % doppler shift in [-200, 200] kHz
y_dopp = y_receive.*exp(-1j*2*pi*f_d*t_dsamp);
corr_pss_dopp = xcorr(y_dopp, pss_dsamp);
figure;
plot(mag2db(abs(corr_pss_dopp)));
xlim([length(y_receive), 2*length(y_receive)-1]);

%% correlation test
% this will generate a figure similar to fig 3.
frame = 1;
y_slice = y_receive((frame-1)*(N_sf+1)*N_sym+1:frame*(N_sf+1)*N_sym);
corr = xcorr(y_slice) / length(y_slice);
figure(4);
plot(mag2dB(abs(corr)), LineWidth=1);
title('correlation: 1 frame');
corr_frames = xcorr(y_receive) / length(y_receive);
figure(5);
plot(mag2dB(abs(corr_frames)), LineWidth=1);
title('correlation: all frames');
xlim([length(corr_frames)/2 - N*2 length(corr_frames)/2 + N*2])
