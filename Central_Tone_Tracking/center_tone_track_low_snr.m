%%
clear all; close all; clc;
addpath ../Tool_Functions/;
setParam;

%% load filename
mon = 8; day = 12; hr = 10; minu = 7;
sample_rate = 100e6;
center_freq = 11.575e9;
IQ_Sample_file = get_file_name(mon, day, hr, minu, center_freq, sample_rate);
%%
f_hardware = 145642; % not needed
T_avg = 1;
central_bw = 1.024e6;
n_fft = 1024;
t_fft = n_fft/central_bw;
% num_read_samples = t_fft*sample_rate;
num_read_samples = T_avg*sample_rate;

idx = pss_begin_idx(1);
figure;
while idx <= pss_begin_idx(end)
    sig = read_complex_binary2(IQ_Sample_file, num_read_samples, idx);
    if length(sig) ~= num_read_samples
        display("breaking")
        break;
    end
    
    sig = resample(sig, central_bw, sample_rate);
    [sig_fft_abs, f] = fft_avg(sig, central_bw, n_fft, f_hardware);
    % sig_fft = fftshift(fft(sig, n_fft))/n_fft;
    % sig_fft_abs = abs(sig_fft);
    f = linspace(-central_bw/2, central_bw/2, n_fft)';
    plot(mag2db(sig_fft_abs));
    % xlim([6e4,7.5e4]);
    % ylim([0,100]);
    pause(0.1);
    idx = idx+num_read_samples;
end
