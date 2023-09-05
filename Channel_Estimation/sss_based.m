% Aim: To check if sss is also contained within the obtained signal

clear all; close all; clc;
addpath ../Tool_Functions/;
setParam;

%% load filename
mon = 8; day = 12; hr = 10; minu = 7;
sample_rate = 100e6;
center_freq = 11.575e9;
IQ_Sample_file = get_file_name(mon, day, hr, minu, center_freq, sample_rate);

%% get pss indexes to use in extracting frames - run only if pss_begin_idx has not been saved
load('pss_begin_idx.mat');

if isempty(pss_begin_idx)
    [pss_begin_idx] = frame_detect_pss(IQ_Sample_file, sample_rate, 0);
end

%% get num of frames 

T_f = 1/750;
N_f = T_f*sample_rate; % number of symbols in a frame
frame_num = length(pss_begin_idx);

%% get local sss and doppler parameters
SSS = get_sss(N);
scatter(real(SSS), imag(SSS));
xlim([-2, 2]);
ylim([-2, 2]);
sss = zeros(T_sym*F_s, 1);
sss(N_g+1:end) = sqrt(N)*ifft(SSS);
sss(1:N_g) = sss(end-N_g+1:end);
[tone_list, dopp_param, t] = central_tone_tracking(IQ_Sample_file, pss_begin_idx, sample_rate, 0);

%% get sss index and channel for each frame

figure;
plot(abs(sss));
sss_resamp = resample(sss, sample_rate, 240e6);
% sss_resamp = sss_resamp(10:10+426);
figure;
sss_idx_arr = [];
H_arr = [];
dopp_over_frames = [];
for idx = 2000:3000
    recv = read_complex_binary2(IQ_Sample_file, N_f, pss_begin_idx(idx));
    n = [pss_begin_idx(idx)-pss_begin_idx(1):pss_begin_idx(idx)-pss_begin_idx(1)+length(recv)-1]'./sample_rate;
    % correct signal for doppler shift 
    doppler_arr = dopp_param(1)*n+dopp_param(2);
    dopp_over_frames = [dopp_over_frames;doppler_arr];
    doppler_corrected_recv = recv.*exp(-1i*2*pi*doppler_arr.*n); % -1i or +1i? 
    [c,lags] = xcorr(doppler_corrected_recv, sss_resamp);
    [max_xcorr, sss_idx] = max(abs(c));
% plot selected sss_idx 
%     scatter(lags(sss_idx), max_xcorr,'filled'); 
%     hold on;
%     plot(lags, abs(c));
    sss_idx_arr = [sss_idx_arr, pss_begin_idx(idx)+lags(sss_idx)];
    sss_noresample = sqrt(N)*ifft(SSS);
    sss_resample = resample(sss_noresample, sample_rate, 240e6);

    rx_sss = doppler_corrected_recv(lags(sss_idx)+1:lags(sss_idx)+440);
    rx_sss = rx_sss(7:7+426); % jump into signal by 3/4th of cyclic prefix 
    sss_resamp_removecp = sss_resamp(14:14+426);
    H = fft(rx_sss)./fft(sss_resamp_removecp);
    H(1:2) = 0;
    H(end-1:end) = 0;
    H_arr = [H_arr H]; % array that stores channels for all frames

% uncomment to visualise channel:
%     subplot(2,1,1)
%     plot(abs(H));
%     ylim([0,2]);
%     subplot(2,1,2)
%     plot(unwrap(angle(H)));
%     pause(0.1);
%     clf;
end

