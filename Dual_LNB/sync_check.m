%%
clear all; close all; clc;
addpath ../Tool_Functions/;
setParam;

%% load filename
mon = 10; day = 16; hr = 19; minu = 59;
sample_rate = 2e6;
center_freq = 11.325e9;
IQ_Sample_file_base_name = get_file_name_new(mon, day, hr, minu, center_freq, sample_rate);
% rx0_file = replace(IQ_Sample_file_base_name, '.dat', '_rx0.dat');
% rx1_file = replace(IQ_Sample_file_base_name, '.dat', '_rx1.dat');
rx0_file = '/home/ishani/LeoPNT/USRP_data/1_10/time_20_44_freq_11_325G_bw_2.0M_1704941134.9844222_inrx0.dat'
rx1_file = '/home/ishani/LeoPNT/USRP_data/1_10/time_20_44_freq_11_325G_bw_2.0M_1704941134.9844222_inrx1.dat'

%%
f_hardware = 145642; % not needed
central_bw = 2e6; %2.024e6;
T_avg = 1;
n_fft = 2^10;
t_fft = n_fft/central_bw;
num_read_samples = T_avg*sample_rate; %t_fft*sample_rate;

idx = 1;
figure;
time = num_read_samples/sample_rate;
move_by = num_read_samples/2;
time_array0 = [];
peak_array0 = [];
time_array1 = [];
peak_array1 = [];
while 1
    sig0 = read_complex_binary2(rx0_file, num_read_samples, idx);
    sig1 = read_complex_binary2(rx1_file, num_read_samples, idx);
    
    if length(sig0) ~= num_read_samples
        fprintf("breaking beacuse of sig 0")
        break;
    end
    if length(sig1) ~= num_read_samples
        fprintf("breaking beacuse of sig 1")
        break;
    end
    sig0 = resample(sig0, central_bw, sample_rate);
    sig1 = resample(sig1, central_bw, sample_rate);

    [sig_fft_abs0, f] = fft_avg(sig0, central_bw, n_fft, f_hardware);
    [sig_fft_abs1, f] = fft_avg(sig1, central_bw, n_fft, f_hardware);
    % [max0, midx0] = maxk(sig_fft_abs0, 20); % find 10 peaks - 9 tones and 1 constant hardware induced
    % [max1, midx1] = maxk(sig_fft_abs1, 20); % find 10 peaks - 9 tones and 1 constant hardware induced
    % mean_sig_amp0 = mean(sig_fft_abs0);
    % mean_sig_amp1 = mean(sig_fft_abs1);
    % peaks0 = [];
    % peaks1 = [];
    % peaks_idx0 = [];
    % peaks_idx1 = [];
    % 
    % for i=1:1:length(max0)
    %     if max0(i) > mean(sig_fft_abs0)+2*std(sig_fft_abs0) 
    %         if i>1 && any((abs(midx0(i)-midx0(1:i-1)) < 5))
    %             continue
    %         end
    %         peaks0 = [peaks0 max0(i)];
    %         peaks_idx0 = [peaks_idx0 midx0(i)];
    %     end
    % end
    % 
    % for i=1:1:length(max1)
    %     if max1(i) > mean(sig_fft_abs1)+2*std(sig_fft_abs1) 
    %         if i>1 && any((abs(midx1(i)-midx1(1:i-1)) < 5))
    %             continue
    %         end
    %         peaks1 = [peaks1 max1(i)];
    %         peaks_idx1 = [peaks_idx1 midx1(i)];
    %     end
    % end
    % peak_subarray0 = zeros(1, n_fft);
    % peak_subarray0(peaks_idx0) = peaks0;
    % time_array0 = [time_array0; time];
    % peak_array0 = [peak_array0; peak_subarray0];
    % 
    % peak_subarray1 = zeros(1, n_fft);
    % peak_subarray1(peaks_idx1) = peaks1;
    % time_array1 = [time_array1; time];
    % peak_array1 = [peak_array1; peak_subarray1];

    plot(10*log10(sig_fft_abs0));
    hold on;

    plot(10*log10(sig_fft_abs1));
    % scatter(peaks_idx0, 10*log10(peaks0), 'filled');
    % scatter(peaks_idx1, 10*log10(peaks1), 'filled');
    xlim([0,length(sig_fft_abs0)])

    
    ylim([-5,25])
    title(join([num2str(time), " ",num2str(peak2rms(sig_fft_abs0))]));
    pause(0.1);
    clf;
    idx = idx+move_by;
    time = time+move_by/sample_rate;
   

end
