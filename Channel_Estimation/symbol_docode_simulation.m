clear all; close all; clc;
addpath ../;
addpath ../Tool_Functions/;

setParam;
[x, t_1] = getBasebandSig();

%% doppler & channel
dopp_rate = -1e3;
dopp_init = -50e3;
SNR = 123;
y = x/4;              % attenuation
y = y.*exp(j*2*pi*(dopp_rate*t_1+dopp_init).*t_1);
y = awgn(y, SNR);
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
frame_num = length(pss_begin_idx);

%% frame extraction
SSS = get_sss(1024);
sss = ifft(SSS);
SSS_resamp = SSS;
SSS_resamp(215:811) = 0;
for idx = 1:frame_num
    frame_len = round(T_f*100e6);
    recv = y(pss_begin_idx(idx):pss_begin_idx(idx)+frame_len-1);

    sss_recv = recv(441:880);
    sss_upsamp = my_resample(sss_recv, 240e6, 100e6);
    sss_upsamp = sss_upsamp(33:end);    % remove cp
    H = fft(sss_upsamp)./SSS;
    for idx_f = 3:302
        recv_frame = recv(1+440*(idx_f-1):440*idx_f);
        frame_upsamp = my_resample(recv_frame, 240e6, 100e6);
        frame_upsamp = frame_upsamp(33:end);
        symbols = fft(frame_upsamp)./H;
        % scatterplot([symbols(1:214);symbols(812:end)]);
        scatter(real([symbols(1:214);symbols(812:end)]), imag([symbols(1:214);symbols(812:end)]));
    end
end