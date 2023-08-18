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
    [pss_begin_idx] = frame_detect_pss(IQ_Sample_file, sample_rate);
end

%% get frames 

T_f = 1/750;
N_f = T_f*sample_rate;
frame_num = length(pss_begin_idx);
t_read = 1e-2;
num_samples = t_read*sample_rate;
% noise estimation (assumes data begins with noise)
f = fopen(IQ_Sample_file, 'rb');
[noise, is_end] = fread_complex(f, num_samples);
%%
SSS = get_sss(N);
scatter(real(SSS), imag(SSS));
xlim([-2, 2]);
ylim([-2, 2]);
sss = zeros(T_sym*F_s, 1);
sss(N_g+1:end) = sqrt(N)*ifft(SSS);
sss(1:N_g) = sss(end-N_g+1:end);

%% get sss index
figure;
plot(abs(sss));
sss_resamp = resample(sss, sample_rate, 240e6);
% filter_kernel = conj(sss_resamp(end:-1:1));
% z = zeros(length(filter_kernel)-1, 1);
% [res, z] = filter(filter_kernel, 1, signal, z);
% threshold = 15*mean(abs(filter(filter_kernel, 1, noise)));
figure;
sss_idx_arr = [];
for idx = 1:frame_num
    recv = read_complex_binary2(IQ_Sample_file, N_f, pss_begin_idx(idx));
    [c,lags] = xcorr(recv, sss_resamp);
    [max_xcorr, sss_idx] = max(abs(c));
%     scatter(lags(sss_idx), max_xcorr,'filled'); 
%     hold on;
%     plot(lags, abs(c));
    sss_idx_arr = [sss_idx_arr, pss_begin_idx(idx)+lags(sss_idx)];
    sss_noresample = sqrt(N)*ifft(SSS);
    sss_resample = resample(sss_noresample, sample_rate, 240e6);
    rx_sss = recv(lags(sss_idx)+1+14/2:lags(sss_idx)+1+14/2+427-1);
%     plot(abs(recv));
    i = lags(sss_idx)+1+14/2:lags(sss_idx)+1+14/2 + 427-1;
%     plot(i,abs(rx_sss));
%     figure;
    H = fft(rx_sss)./fft(sss_resample);
    subplot(2,1,1)
    plot(abs(H));
    ylim([0,2]);
    subplot(2,1,2)
    plot(unwrap(angle(H)));
    pause(0.2);
    clf;
end


