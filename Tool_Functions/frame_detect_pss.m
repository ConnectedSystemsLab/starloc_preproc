function [is_frame_exist] = frame_detect_pss(file_path, sample_rate)
% frame detection algorithm based on correlation with pss sequence

fprintf("Decting frames in %s\n", file_path);
addpath ../Tool_Functions/

t_read = 1e-2;
num_samples = t_read*sample_rate;
d_samp = 10;
is_frame_exist = false;
f = fopen(file_path, 'rb');

% noise estimation
[noise, is_end] = fread_complex(f, num_samples);
noise_mean = mean(noise);
noise_var = var(noise);

window_size = 5e3/d_samp;
filter_kernal = ones(window_size, 1)/window_size;
z = zeros(window_size-1, 1);

read_idx = 0;           % # of read times
pw_threshold = 2*noise_var;
while ~is_end
    read_idx = read_idx+1;
    
    [signal, is_end] = fread_complex(f, num_samples);
    signal = signal(1:d_samp:end);
    sig_pw = abs(signal).^2;
    
    [pw_avg, z] = filter(filter_kernal, 1, sig_pw, z);
    idx_above_thresh = pw_avg > pw_threshold;
    idx_above_thresh = find(idx_above_thresh);

    if ~isempty(idx_above_thresh)
        is_frame_exist = true;
        subplot(2, 1, 1);
        plot(mag2db(abs(signal)));
        subplot(2, 1, 2);
        plot(mag2dB(pw_avg));
        yline(mag2dB(pw_threshold))
        pause(.1);
    end
end
end