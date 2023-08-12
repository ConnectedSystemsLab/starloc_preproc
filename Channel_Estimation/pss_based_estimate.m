clear all; close all; clc;
addpath ../Tool_Functions/;

% load file
mon = 8; day = 12; hr = 10; minu = 7;
sample_rate = 100e6;
center_freq = 11.575e9;
IQ_Sample_file = get_file_name(mon, day, hr, minu, center_freq, sample_rate);

%% pss detect
[pss_begin_idx] = frame_detect_pss(IQ_Sample_file, sample_rate);

%% calculate amplitude & phase
T_f = 1/750;
N_f = T_f*sample_rate;
frame_num = length(pss_begin_idx);
[t, amplitude, phase] = deal(zeros(frame_num, 1));

% time of frames
t_diff = diff(pss_begin_idx)/N_f*T_f;       % (s)
for idx = 2:frame_num
    t(idx) = t(idx-1)+t_diff(idx-1);
end

pss = resample(get_pss(), sample_rate, 240e6);
for idx = 1:frame_num
    recv = read_complex_binary2(IQ_Sample_file, pss_len, pss_begin_idx(idx));
    ratio = recv./pss;      % 440*1 complex
    amplitude(idx) = mean(abs(ratio));
    phase(idx) = phase_avg(angle(ratio));
end

%% Fig plot
figure(1);
plot(t, unwrap(phase));
title('phase change over time');
figure(2);
plot(t, amplitude);
abs_avg = filter(ones(1e2,1)/1e2, 1, amplitude);
hold on; plot(t, abs_avg);
title('amplitude change over time');