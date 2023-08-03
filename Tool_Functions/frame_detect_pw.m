function [idxs, num_f] = frame_detect_pw(file_path, sample_rate, num_samples)
% frame detection algorithm based on sliding window & power detection
tic;
fprintf("Decting frames in %s\n", file_path);
addpath ../Tool_Functions/
T_f = 1.33e-3;
N_f = T_f*sample_rate;

idxs_tmp = [];
f = fopen(file_path, 'rb');
window_size = 2e3;
filter_kernal = ones(window_size, 1)/window_size;
z = zeros(window_size-1, 1);

is_end = false;
read_idx = 0;           % # of read times
detect_count = 0;       % # of detected frame
pw_threshold = -15.5;     % 10*log10(*), dB
while ~is_end
    read_idx = read_idx+1;
    
    [signal, is_end] = fread_complex(f, num_samples);
    sig_pw = abs(signal).^2;
    
    [pw_avg, z] = filter(filter_kernal, 1, sig_pw, z);
    idx_above_thresh = pw_avg > 10^(pw_threshold/10);
    idx_above_thresh = diff(idx_above_thresh);
    if ~isempty(find(idx_above_thresh))
        idx_new = find(idx_above_thresh)+(read_idx-1)*num_samples;
        % % merge adjacent points
        % idx_new_merge = idx_new(diff(idx_new)>1e3);
        % if ~isempty(idx_new_merge)
        %     idx_new_merge = [idx_new_merge ; idx_new(end)];
        % else
        %     continue;
        % end
        % idxs_tmp = [idxs_tmp; idx_new_merge];
        num_frames = diff(idx_new)/N_f;
        is_integer = abs(num_frames-round(num_frames))<=4e-2 & num_frames > 0.8;
        is_integer = [is_integer;0];
        is_int_shift = circshift(is_integer, 1);
        idx_new = idx_new(is_integer | is_int_shift);
        if ~isempty(idx_new)
            idxs_tmp = [idxs_tmp; idx_new];
            plot(mag2db(abs(signal)));
            xline(mod(idx_new, num_samples));
            pause(.1);
        end
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
idxs = idxs_tmp;

num_f = length(idxs)/2;
fprintf("%d frames found, %d s used\n", num_f, round(toc));
end