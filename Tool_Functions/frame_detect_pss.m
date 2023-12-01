function [frame_begin_idx] = frame_detect_pss(file_path, sample_rate, if_visual)
% frame detection algorithm based on pss sequence & matched filter
% input: the path of .dat file; sample_rate
% output: the index of frames
% note: only high sample rate will work (e.g., 100 MHz)
% otherwise the correlation peak might not be observed

fprintf("Detecting frames in %s\n", file_path);
tic;
addpath ../Tool_Functions/

N = 1024+32;                % FFT size + CP size
Fs = 240e6;                 % transmit sample rate
t_read = 1e-2;              % duration of each file read
num_samples = t_read*sample_rate;
frame_begin_idx = [];
[pss, ~] = get_pss();
pss_resamp = resample(pss, sample_rate, 240e6);

% noise estimation (assumes data begins with noise)
noise = read_complex_binary2(file_path, num_samples, 1);
% matched filter based detection
% the correlation of a & b = the convolution of a and reverse(b)
filter_kernal = conj(pss_resamp(end:-1:1));
% z stores the filter's state
z = zeros(length(filter_kernal)-1, 1);

read_idx = 1;           % # of read times
% need to be adjusted
threshold = 10*mean(abs(filter(filter_kernal, 1, noise)));
find_frame = false;

while 1
    read_idx = read_idx+1;
    if ~find_frame
        read_idx = read_idx+20;
        % if don't find anything, skip to speed up
        % so that the noise can be skipped quickly
    end
    % the index in the whole file
    file_idx = (read_idx-1)*num_samples+1;

    % [signal, is_end] = fread_complex(f, num_samples);
    signal = read_complex_binary2(file_path, num_samples, file_idx);
    signal = signal.*exp(j*2*pi*-85e3*[0:num_samples-1]'/sample_rate);
    if length(signal) ~= num_samples
        % this means the end of the file
        break;
    end
    
    % do the correlation of raw data with pss
    [res, z] = filter(filter_kernal, 1, signal, z);
    idx_above_thresh = abs(res) > threshold;
    idx_above_thresh = find(idx_above_thresh);
    tmp = idx_above_thresh;

    if ~isempty(idx_above_thresh)
        find_frame = true; cnt = 0;
        % eliminate adjacent results
        for idx = 1:length(idx_above_thresh)
            if tmp(idx) == 0
                continue;
            end
            idx_1 = idx_above_thresh(idx);
            idx_2_ = abs(idx_above_thresh-idx_1) <= 20*ceil(sample_rate/Fs*N);
            idx_2 = idx_above_thresh(idx_2_);
            [~, ii_] = max(abs(res(idx_2)));
            idx_2_max = idx_2(ii_);
            % jj = idx_2 ~= idx_2_max;
            for mm = 1:length(idx_2)
                if idx_2(mm) ~= idx_2_max
                    tmp(tmp == idx_2(mm)) = 0;
                end
            end
        end
        idx_above_thresh = nonzeros(tmp) - ceil(sample_rate/Fs*N);
        frame_begin_idx = [frame_begin_idx; ...
            idx_above_thresh+(read_idx-1)*num_samples];
        
        if if_visual
        % for visualize & debug
            subplot(2, 1, 1);
            plot(mag2db(abs(signal)));
            xline(idx_above_thresh);
            subplot(2, 1, 2);
            plot(mag2dB(abs(res)));
            yline(mag2dB(threshold))
            pause(.1);
        end
    else
        if find_frame
            % if already find frame && don't find frame in the next 50 file
            % reads, then stop finding frames and end the function
            if cnt < 50
                cnt = cnt+1;
            else
                break;
            end
        end
    end
end

% print result and save .mat file
fprintf("Detect done in %d s, %d frames found in total\n", round(toc), length(frame_begin_idx));
file_name = split(file_path, '/');
file_name = file_name{end};
file_name = file_name(1:end-4);
% file_name
today_month = month(datetime);
today_day = day(datetime);
root_dir = "../bash_scripts/new_files_output/"+num2str(today_month)+"_"+num2str(today_day)+"/";
if ~exist(root_dir)
    mkdir(root_dir);
end
% if find_frame
%     save(root_dir+file_name+"_1.mat", "frame_begin_idx");
%     frame_num = length(frame_begin_idx);
%     N_f = ceil(1/750*sample_rate);
%     frames = zeros(frame_num, N_f);
%     for idx = 1:frame_num
%         frames(idx, :) = read_complex_binary2(file_path, N_f, frame_begin_idx(idx));
%     end
%     save("../bash_scripts/new_files/"+num2str(today_month)+"_"+num2str(today_day)+"/"+file_name+".mat", "frames");
%     fprintf("FIND FRAMESSSSSSSSSSSSSSSSSSSSSSSSSSSS!\n");
% else
%     save(root_dir+file_name+"_0.mat", "frame_begin_idx");
% end
end