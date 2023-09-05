clear all; close all; clc;
addpath ../;
addpath ../Tool_Functions/;

setParam;
[x, t_1] = getBasebandSig();

%% doppler & channel
dopp_rate = -2e3;
dopp_init = -50e3;
SNR = 12;
y = x/4;              % attenuation
y = y.*exp(j*2*pi*(dopp_rate*t_1+dopp_init).*t_1);
% y = awgn(y, SNR);
y = y/10;

y = resample(y, 10, 24);
t = linspace(0, t_1(end), length(y))';
% figure(1);
% plot(t, mag2db(abs(y)));
% title('time-domain received signal');

%% pss detection
pss = get_pss();
pss_dsamp = resample(pss, 10, 24);
corr_pss = xcorr(y, pss_dsamp);
% figure;
% plot(mag2db(abs(corr_pss)));
% xlim([length(y), 2*length(y)-1]);
pss_threshold = 3;
pss_begin_idx = find(abs(corr_pss)>pss_threshold)-length(y)+1;

%% time domain channel estimation
% time of frames
frame_num = length(pss_begin_idx);
[t, amplitude, phase] = deal(zeros(frame_num, 1));
t_diff = diff(pss_begin_idx)/100e6;       % (s)
for idx = 2:frame_num
    t(idx) = t(idx-1)+t_diff(idx-1);
end

pss_len = length(pss_dsamp);
for idx = 1:frame_num

    recv = y(pss_begin_idx(idx):pss_begin_idx(idx)+pss_len-1);
    ratio = recv./pss_dsamp;      % 440*1 complex
    amplitude(idx) = mean(abs(ratio));
    phase(idx) = phase_avg(angle(ratio));
end

% Fig plot
figure(1);
plot(t, unwrap(phase));
title('phase change over time');
xlabel('time / s'); ylabel('phase(h)');
xlim([t(1) t(end)]);
figure(2);
plot(t, amplitude, LineWidth=1);
xlabel('time / s'); ylabel('abs(h)');
xlim([t(1) t(end)]);
title('amplitude change over time');