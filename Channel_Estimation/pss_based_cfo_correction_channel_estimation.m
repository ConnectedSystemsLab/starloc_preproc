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

%%
frame_num = length(pss_begin_idx);
T_f = 1/750;
N_f = ceil(T_f*sample_rate); % number of symbols in a frame
% local_pss = resample(get_pss(), sample_rate, 240e6);
local_pss_noresample = get_pss();
pss_single = local_pss_noresample(N_g+N/8+1:N_g+N/8+N/8);
pss_single_resample = resample(pss_single, sample_rate, 240e6);
%%
for idx = 1:frame_num
    recv = read_complex_binary2(IQ_Sample_file, N_f, pss_begin_idx(idx)-N_g);
    [c,lags] = xcorr(recv, pss_single_resample);
%     [max_xcorr, sss_idx] = max(abs(c));
%     scatter(lags(sss_idx), max_xcorr,'filled'); 
%     hold on;
    plot(lags, abs(c));
%     pause(0.2)
end