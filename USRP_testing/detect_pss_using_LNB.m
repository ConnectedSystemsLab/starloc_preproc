addpath ../Tool_Functions/;

% load file
IQ_Sample_file = '/home/ishani/LeoPNT/USRP_data/1_5/time_15_00_freq_11_575G_bw_25.0M_1704488444.0657296_inrx0.dat'
center_freq = 11.575e9;
sample_rate = 25e6;
desired_sample_rate = 25e6;
if_visual = 1;

N = 1024+32;                % FFT size + CP size
Fs = 240e6;                 % transmit sample rate
t_read = 1e-2;              % duration of each file read
num_samples = t_read*sample_rate;
frame_begin_idx = [];
[pss, ~] = get_pss();
pss_resamp = resample(pss, desired_sample_rate, 240e6);

% noise estimation (assumes data begins with noise)
noise = read_complex_binary2(IQ_Sample_file, num_samples, 1);
% figure;
% plot(noise)
% matched filter based detection
% the correlation of a & b = the convolution of a and reverse(b)
filter_kernal = conj(pss_resamp(end:-1:1));
% z stores the filter's state
z = zeros(length(filter_kernal)-1, 1);

read_idx = 1;           % # of read times
% need to be adjusted
threshold = 5*mean(abs(filter(filter_kernal, 1, noise)));
find_frame = false;

while 1
    read_idx = read_idx+1;
    % if ~find_frame
    %     read_idx = read_idx+20;
    %     % if don't find anything, skip to speed up
    %     % so that the noise can be skipped quickly
    % end
    % the index in the whole file
    file_idx = (read_idx-1)*num_samples+1;

    % [signal, is_end] = fread_complex(f, num_samples);
    signal = read_complex_binary2(IQ_Sample_file, num_samples, file_idx);
    fprintf('%d \n', length(signal))
    if length(signal) ~= num_samples
        % this means the end of the file
        break;
    end
    signal = resample(signal, desired_sample_rate,sample_rate);
    num_samples_ = length(signal);
    % signal = signal.*exp(j*2*pi*-85e3*[0:num_samples_-1]'/desired_sample_rate);
    % plot(real(signal));
    % ylim([0,2])
    % pause(.1);
    % 
    
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
            idx_2_ = abs(idx_above_thresh-idx_1) <= 20*ceil(desired_sample_rate/Fs*N);
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
        idx_above_thresh = nonzeros(tmp) - ceil(desired_sample_rate/Fs*N);
        % fprintf('%f\n', idx_above_thresh)
        frame_begin_idx = [frame_begin_idx; ...
            ceil(idx_above_thresh/desired_sample_rate*sample_rate+(read_idx-1)*num_samples)];

        if if_visual
        % for visualize & debug
            subplot(2, 1, 1);
            plot(mag2db(abs(signal)));
            xline(idx_above_thresh);
            ylim([-50,5])
            subplot(2, 1, 2);
            plot(mag2dB(abs(res)));
            yline(mag2dB(threshold))
            ylim([-20,12])
            pause(.1);
        end
    else
        continue
        % if find_frame
        %     % if already find frame && don't find frame in the next 50 file
        %     % reads, then stop finding frames and end the function
        %     if cnt < 50
        %         cnt = cnt+1;
        %     else
        %         break;
        %     end
        % end
    end
end