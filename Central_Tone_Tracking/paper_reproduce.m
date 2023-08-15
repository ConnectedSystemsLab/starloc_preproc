%% experiment setup

clear all; clc;
addpath ../Tool_Functions/;

mon = 8; day = 12; hr = 11; minu = 1;
sample_rate = 1.024e6;
center_freq = 11.575e9;
bw = sample_rate;
% load doppler_track_signal.mat;
IQ_Sample_file = get_file_name(mon,day,hr,minu,center_freq,bw);
f = fopen(IQ_Sample_file, 'rb');

%% frame detection
% frame_idxs = frame_detect_pss(IQ_Sample_file, sample_rate);
is_end = false;
num_samples = sample_rate*1;
frame_idx = 0;
n_fft = 1024;
% sig_fft = zeros(n_fft, 1);
% freq = linspace(-bw/2, bw/2, n_fft);
detect_threshold = -55;     % dB
a = 0;
while ~is_end
    frame_idx = frame_idx+1;
    [signal, is_end] = fread_complex(f, num_samples);
    if length(signal) ~= num_samples
        % file ended
        is_end = true;
        break;
    end
    [sig_fft, freq] = fft_avg(signal, bw, n_fft);
    % spectrogram(signal, hanning(1024), 500, 1024, sample_rate, 'centered');
    plot(freq, sig_fft);
    pause(.1);
end
