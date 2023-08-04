%% experiment setup

clear all; clc;
addpath ../Tool_Functions/;

mon = 8; day = 4; hr = 14; minu = 37;
sample_rate = 1.024e6;
center_freq = 11.575e9;
bw = sample_rate;
IQ_Sample_file = get_file_name(mon,day,hr,minu,center_freq,bw);
f = fopen(IQ_Sample_file, 'rb');

%% frame by frame detection
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
    
    [sig_fft, freq] = fft_avg(signal, sample_rate, n_fft);
    sig_fft_abs = abs(sig_fft);
    % if mag2db(max(sig_fft)) > detect_threshold
    sig_fft_abs(abs(freq-27528)<=2e3) = mean(sig_fft_abs);
    a = max(a, max(sig_fft_abs));
    % if mag2db(max(sig_fft_abs)) > detect_threshold
    if 1
        plot(freq, mag2db(sig_fft_abs));
        pause(0.1);
    end
    % if idx_mod == agg_frames
    % 
    %     signal_reshape = reshape(signal, [num_samples agg_frames]);
    %     signal_reshape_fft = fftshift(fft(signal_reshape))/sqrt(num_samples);
    %     sig_fft = mean(signal_reshape_fft, 2);
    %     sig_fft_abs = abs(sig_fft);
    % 
    %     % eliminate hardware peak
    %     sig_fft_abs(abs(freq-25750)<=1e3) = mean(sig_fft_abs);
    % 
    %     central_fft_abs = sig_fft_abs(freq>-0.5e6 & freq<0.5e6);
    %     central_freq = freq(freq>-0.5e6 & freq<0.5e6);
    % 
    %         continue;
    %     end
    % end
end
