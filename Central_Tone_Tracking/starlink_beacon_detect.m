%% experiment setup

clear all; clc;
addpath ../Tool_Functions/;

mon = 8; day = 1; hr = 15; minu = 2;
sample_rate = 100e6;
center_freq = 11.575e9;
bw = sample_rate;
IQ_Sample_file = get_file_name(mon,day,hr,minu,center_freq,bw);
f = fopen(IQ_Sample_file, 'rb');

%% frame by frame detection
is_end = false;
num_samples = 1e6;
frame_idx = 0;
agg_frames = 20;
n_fft = num_samples;
signal = zeros(agg_frames*num_samples, 1);
sig_fft = zeros(n_fft, 1);
freq = linspace(-bw/2, bw/2, n_fft);

while ~is_end
    frame_idx = frame_idx+1;
    idx_mod = mod(frame_idx, agg_frames);
    if idx_mod ~= 0
        [signal((idx_mod-1)*num_samples+1:idx_mod*num_samples), is_end] ...
            = fread_complex(f, num_samples);
    else
        signal((agg_frames-1)*num_samples+1:end) ...
            = fread_complex(f, num_samples);
    end
    % if frame_idx < 3000
    %     continue;   % total: 4570
    % end

    if idx_mod == 0
        
        signal_reshape = reshape(signal, [num_samples agg_frames]);
        signal_reshape_fft = fftshift(fft(signal_reshape))/sqrt(num_samples);
        sig_fft = mean(signal_reshape_fft, 2);
        sig_fft_abs = abs(sig_fft);

        % eliminate hardware peak
        sig_fft_abs(abs(freq-25750)<=1e3) = mean(sig_fft_abs);

        central_fft_abs = sig_fft_abs(freq>-0.5e6 & freq<0.5e6);
        central_freq = freq(freq>-0.5e6 & freq<0.5e6);
        if mag2dB(max(central_fft_abs)) > -6
            plot(central_freq, mag2dB(central_fft_abs));
            pause(0.5);
        else
            continue;
        end
    end

end