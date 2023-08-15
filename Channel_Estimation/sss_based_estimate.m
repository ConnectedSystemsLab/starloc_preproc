clear all; close all; clc;
addpath ../Tool_Functions/;

% load file
mon = 8; day = 12; hr = 10; minu = 7;
sample_rate = 100e6;
center_freq = 11.575e9;
IQ_Sample_file = get_file_name(mon, day, hr, minu, center_freq, sample_rate);

%% pss detect
[pss_begin_idx] = frame_detect_pss(IQ_Sample_file, sample_rate);
T_f = 1/750;
N_f = T_f*sample_rate;
frame_num = length(pss_begin_idx);
[t, amplitude, phase] = deal(zeros(frame_num, 1));

%% sss extract
N = 1024; N_g = 32; N_sym = N+N_g;
sss_begin_idx = pss_begin_idx+N_sym*sample_rate/240e6;
idx = sss_begin_idx(3000);
sig = read_complex_binary2(IQ_Sample_file, 10e6, idx);
[sig_fft, freq] = fft_avg(sig, 100e6, 1e6);