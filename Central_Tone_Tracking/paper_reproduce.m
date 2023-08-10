%% experiment setup

clear all; clc;
addpath ../Tool_Functions/;

mon = 8; day = 10; hr = 16; minu = 8;
sample_rate = 1.024e6;
center_freq = 11.575e9;
bw = sample_rate;
% load doppler_track_signal.mat;
IQ_Sample_file = get_file_name(mon,day,hr,minu,center_freq,bw);
f = fopen(IQ_Sample_file, 'rb');

%% frame detection
% frame_idxs = frame_detect_pss(IQ_Sample_file, sample_rate);
is_end = false;
num_samples = 1024*1e3;
frame_idx = 0;
n_fft = 1024;
% sig_fft = zeros(n_fft, 1);
freq = linspace(-bw/2, bw/2, n_fft);
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
    spectrogram(signal, hanning(1024), 500, 1024, sample_rate, 'centered');
    pause(.1);
end
% for idx = 1:floor(length(sig_dsamp)/num_samples)
%     signal = sig_dsamp((idx-1)*num_samples+1:idx*num_samples);
%     spectrogram(signal, hanning(1024), 500, 1024, sample_rate, 'centered');
%     pause(.1);
% end
