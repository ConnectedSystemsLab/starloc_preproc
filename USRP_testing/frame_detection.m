% IQ_Sample_file = ['/home/ishani/LeoPNT/USRP_data/' ...
%     'capture_2023_07_24_bw-100_center-1_325_time-15_38.dat'];
IQ_Sample_file = ['/home/ishani/LeoPNT/USRP_data/' ...
    'IQ_Samples_06_22_23_16_15_20MHz_11950-youtubelive.dat'];
num_samples = 1e6/8;      % # of samples read for one time
f = fopen(IQ_Sample_file, 'rb');
sample_rate = 100e6;
packet_len = 2e4/5;
num_detect_frame = 5e2*10;
frame_count = 0;
fail_count = 0;
threshold_1 = 1.5;
threshold_2 = 1/threshold_1;
window_size = packet_len;
result = [];

while 1
    max_ratio = -Inf;
    sig_ = fread(f, [num_samples*2 1], 'float');
    sig = sig_(1:2:end) + sig_(2:2:end)*1j;
    find_frame = false;
    
    for jj = 1:100:numel(sig)-2*window_size+1
        ratio = 1/((sum(abs(sig(jj:jj+window_size-1)).^2))/sum(abs(sig(jj+window_size:jj+2*window_size-1)).^2));
        if ratio > max_ratio
            max_ratio = ratio;
        end
        if ~find_frame
            if ratio > threshold_1
                packet_start_index = jj+window_size;
                find_frame = true;
                % max_ratio = ratio;
            end
        else
            if ratio < threshold_2
                packet_end_index = jj+2*window_size;
                break;
            end
        end
        % ratio_all(jj+window_size) mag2dB= ratio;
    end
    if find_frame
        fail_count = 0;
        result = [result ; sig(packet_start_index:packet_end_index)];
        frame_count = frame_count+1;
        if mod(frame_count, 10) == 0
        frame_count
            if frame_count == num_detect_frame
                break;
            end
        end
    else
        fail_count = fail_count+1;
        if fail_count == 10
            fail_count = 0;
            for idx = 1:25
                sig_ = fread(f, [num_samples*2 1], 'float');
            end
        end
    end
    plot(10*log10(abs(sig)));
    if find_frame
        xline(packet_start_index);
        xline(packet_end_index);
    end
    pause(0.01);
end

%% corr test
corr_frames = xcorr(result);
figure;
plot(10*log10(abs(corr_frames)));
title('correlation: all frames');
% xlim([length(corr_frames)/2 - 500*2 length(corr_frames)/2 + 500*2])