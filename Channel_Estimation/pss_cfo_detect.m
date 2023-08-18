clear all; close all; clc;
addpath ../Tool_Functions/;

% load file
mon = 8; day = 12; hr = 10; minu = 7;
sample_rate = 100e6;
center_freq = 11.575e9;
IQ_Sample_file = get_file_name(mon, day, hr, minu, center_freq, sample_rate);

%% pss detect
[pss_begin_idx] = frame_detect_pss(IQ_Sample_file, sample_rate, 0);
T_f = 1/750;
N_f = T_f*sample_rate;
frame_num = length(pss_begin_idx);

%% CFO estimation
pss = resample(get_pss(), sample_rate, 240e6);
pss_len = length(pss);
peak_num = 9;
filter_kernal = zeros(480, 1);
filter_idx = 1;
for ii = 1:peak_num
    filter_kernal(floor(filter_idx)) = 1;
    filter_idx = filter_idx+128*10/24;
end
for idx = 1:frame_num
    if idx<2000
        continue;
    end
    pss_recv = read_complex_binary2(IQ_Sample_file, pss_len, pss_begin_idx(idx));
    cor = xcorr(pss_recv);
    [~, peak_idxs] = maxk(abs(cor), peak_num);
    % a = findpeaks(abs(cor), MinPeakDistance=10);
    subplot(2, 1, 1); plot(abs(cor));
    
    % res = xcorr(filter_kernal, abs(cor));
    % peak_idxs = sort(peak_idxs);
%     peak_idxs = [227;280;333;387;440;493;547;600;653];
    sub_idxs = [67;121;174;227;281;334;387];
    for ii = 1:6
        p2 = pss_recv(sub_idxs(ii+1):sub_idxs(ii+1)+52);
        p1 = pss_recv(sub_idxs(ii):sub_idxs(ii)+52);
        ra(ii) = sum(p1.*conj(p2));
    end
    t = (peak_idxs-peak_idxs(peak_num/2+1/2))/sample_rate;
    subplot(2, 1, 2); plot(t, unwrap(angle(cor(peak_idxs))));
    [k, b] = least_square(t, unwrap(angle(cor(peak_idxs))));
    hold on; ylim([-1.2 1.2]);
    plot(t, k*t+b, '--');
end