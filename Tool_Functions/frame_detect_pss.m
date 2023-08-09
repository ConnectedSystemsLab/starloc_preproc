function [frame_begin_idx] = frame_detect_pss(file_path, sample_rate)
% frame detection algorithm based on pss sequence & matched filter
% input: the path of .dat file; sample_rate
% output: the index of frames
% note: only high sample rate will work (e.g., 100 MHz)

fprintf("Decting frames in %s\n", file_path);
addpath ../Tool_Functions/

N = 1024;
Fs = 240e6;
t_read = 1e-2;
num_samples = t_read*sample_rate;
frame_begin_idx = [];
f = fopen(file_path, 'rb');
[pss, ~] = get_pss();
pss_resamp = resample(pss, sample_rate, 240e6);

% noise estimation (assumes data begins with noise)
[noise, is_end] = fread_complex(f, num_samples);
% matched filter based detection
filter_kernal = conj(pss_resamp(end:-1:1));
z = zeros(length(filter_kernal)-1, 1);

read_idx = 1;           % # of read times
% need to be adjusted
threshold = 10*mean(abs(filter(filter_kernal, 1, noise)));

while ~is_end
    read_idx = read_idx+1;
    
    [signal, is_end] = fread_complex(f, num_samples);
    
    [res, z] = filter(filter_kernal, 1, signal, z);
    idx_above_thresh = abs(res) > threshold;
    idx_above_thresh = find(idx_above_thresh);
    tmp = idx_above_thresh;

    if ~isempty(idx_above_thresh)
        % eliminate adjacent results
        for idx = 1:length(idx_above_thresh)-1
            idx_1 = idx_above_thresh(idx);
            idx_2 = idx_above_thresh(idx+1);
            if idx_2-idx_1 < ceil(sample_rate/Fs*N/8+3)*2
                if abs(res(idx_1)) >= abs(res(idx_2))
                    tmp(idx+1) = 0;
                else
                    tmp(idx) = 0;
                end
            end
        end
        idx_above_thresh = nonzeros(tmp);
        frame_begin_idx = [frame_begin_idx; ...
            idx_above_thresh+(read_idx-1)*num_samples];
        
        % for visualize & debug
        subplot(2, 1, 1);
        plot(mag2db(abs(signal)));
        xline(idx_above_thresh);
        subplot(2, 1, 2);
        plot(mag2dB(abs(res)));
        yline(mag2dB(threshold))
        pause(.1);
    end
end
end