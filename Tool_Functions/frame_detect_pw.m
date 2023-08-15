function [idxs, num_f] = frame_detect_pw(file_path, sample_rate, num_samples)
% frame detection algorithm based on sliding window & power detection
tic;
fprintf("Decting frames in %s\n", file_path);
addpath ../Tool_Functions/

bw = sample_rate;
T_f = 1.33e-3;
N_f = T_f*sample_rate;
d_samp = 10;
% agg_frames = 10;
% t = 1e-2;
% n_fft = num_samples / 100;
% num_samples = agg_frames*n_fft;

idxs = [];
f = fopen(file_path, 'rb');
window_size = 5e3/d_samp;
filter_kernal = ones(window_size, 1)/window_size;
z = zeros(window_size-1, 1);

is_end = false;
read_idx = 1;           % # of read times
% detect_count = 0;       % # of detected frame
[noise, is_end] = fread_complex(f, num_samples);
noise_pw = abs(noise).^2;
[n_sig, z] = filter(filter_kernal, 1, noise_pw, z);
pw_threshold = 5*mean(n_sig);
while ~is_end
    read_idx = read_idx+1;
    
    [signal, is_end] = fread_complex(f, num_samples);
    if read_idx < 300
        continue;
    end
    signal = signal(1:d_samp:end);
    sig_pw = abs(signal).^2;
    
    [pw_avg, z] = filter(filter_kernal, 1, sig_pw, z);
    idx_above_thresh = pw_avg > pw_threshold;
    idx_above_thresh = find(idx_above_thresh);
    % idx_above_thresh = diff(idx_above_thresh);
    % 
    % ones_idx = find(idx_above_thresh, 1);
    if ~isempty(idx_above_thresh)
        idxs = [idxs; (read_idx-1)*num_samples+1];
        subplot(3, 1, 1);
        plot(mag2db(abs(signal)));
        % xline(mod(ones_idx, num_samples));
        subplot(3, 1, 2);
        plot(mag2dB(pw_avg));
        pause(.1);
        % if ~isempty(ones_idx)
        %     idxs = [idxs; ones_idx+(read_idx-1)*num_samples];
        %     subplot(3, 1, 1);
        %     plot(mag2db(abs(signal)));
        %     % xline(mod(ones_idx, num_samples));
        %     subplot(3, 1, 2);
        %     plot(mag2dB(pw_avg));
        %     subplot(3, 1, 3);
        %     freq = linspace(-bw/2, bw/2, n_fft);
        %     signal_reshape = reshape(signal, [n_fft agg_frames]);
        %     signal_reshape_fft = fftshift(fft(signal_reshape))/n_fft;
        %     plot(freq, mag2db(abs(mean(signal_reshape_fft, 2))));
        %     xlim([-1e6 1e6]);
        %     pause(.1);
        % end
    end
end

    % & only leave lengths that are multiple of N_f
% idxs_tmp = idxs_tmp(diff(idxs_tmp)>1e3);
% % dicard non-integer of frame length
% num_frames = diff(idxs_tmp)/N_f;
% is_integer = abs(num_frames-round(num_frames))<=4e-2;
% is_int_shift = circshift(is_integer, 1);
% is_int_shift(1) = 0;
% idxs = idxs_tmp(is_integer | is_int_shift);
% idxs = idxs_tmp;

num_f = length(idxs);
fprintf("%d frames found, %d s used\n", num_f, round(toc));
end