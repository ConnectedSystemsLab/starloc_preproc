clear all; close all; clc;
addpath ../Tool_Functions/;

% load file
mon = 8; day = 12; hr = 10; minu = 1;
sample_rate = 100e6;
center_freq = 11.575e9;
IQ_Sample_file = get_file_name(mon, day, hr, minu, center_freq, sample_rate);

%% pss detect
[pss_begin_idx] = frame_detect_pss(IQ_Sample_file, sample_rate, 0);
T_f = 1/750;
N_f = T_f*sample_rate;
frame_num = length(pss_begin_idx);

%% coarse doppler compensation
[dopp_list, dopp_param, t_dopp] = central_tone_tracking(...
    IQ_Sample_file, pss_begin_idx, sample_rate, 1, 9);

%% SSS channel estimation
SSS = get_sss(1024);
sss = ifft(SSS);
% sss_dsamp = resample(sss, 10, 24);
% sss_usamp = resample(sss_dsamp, 24, 10);
% SSS_resamp = fft(sss_usamp);
SSS_resamp = SSS;
% 1:214 & 812:1024
SSS_resamp(215:811) = 0;
for idx = 1:frame_num
    if idx < 800
        continue;
    end
    recv = read_complex_binary2(IQ_Sample_file, N_f, pss_begin_idx(idx));
    t_f = (pss_begin_idx(idx)-pss_begin_idx(1))/sample_rate;
    f_d = dopp_param(1)*t_f+dopp_param(2);
    dopp = exp(j*2*pi*f_d*[0:N_f-1]'/sample_rate);
    recv = recv.*conj(dopp);
    
    sss_recv = recv(441:880);
    sss_upsamp = my_resample(sss_recv, 240e6, sample_rate);
    sss_upsamp = sss_upsamp(33:end);    % remove cp
    H = fft(sss_upsamp)./SSS;
    for idx_f = 3:302
        recv_frame = recv(1+440*(idx_f-1):440*idx_f);
        frame_upsamp = my_resample(recv_frame, 240e6, sample_rate);
        frame_upsamp = frame_upsamp(33:end);
        symbols = fft(frame_upsamp)./H;
        % scatterplot([symbols(1:214);symbols(812:end)]);
        scatter(real([symbols(1:214);symbols(812:end)]), imag([symbols(1:214);symbols(812:end)]));
        % hold on;
        xlim([-5 5]); ylim([-5 5]);
    end
    % H = fft(a2(10:436))./SSS_resamp;
end