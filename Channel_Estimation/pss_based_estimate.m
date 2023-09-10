% clear all; close all; clc;
addpath ../Tool_Functions/;

% load file
mon = 9; day = 8; hr = 12; minu = 5;
sample_rate = 100e6;
center_freq = 11.575e9;
IQ_Sample_file = get_file_name(mon, day, hr, minu, center_freq, sample_rate);

%% pss detect
[pss_begin_idx] = frame_detect_pss(IQ_Sample_file, sample_rate, 1);
T_f = 1/750;
N_f = T_f*sample_rate;
frame_num = length(pss_begin_idx);

%% coarse doppler compensation
[dopp_list, dopp_param, t_dopp] = central_tone_tracking(...
    IQ_Sample_file, pss_begin_idx, sample_rate, 1, 9);
%% doppler test
load central_tone.mat;
fs = 5e6;
figure;
spectrogram(signal_dsamp, hanning(10240), 0, 10240, fs, 'centered');
t = [0:length(signal_dsamp)-1]'/fs;
f_d = dopp_param(1)*t+dopp_param(2);
% figure; plot(t, f_d);
dopp = chirp(t, -f_d(1), t(end), -f_d(end), 'linear', 'complex');
% dopp = exp(j*2*pi*-f_d.*t);
figure;
spectrogram(dopp, hanning(10240), 0, 10240, fs, 'centered');
figure;
spectrogram(signal_dsamp.*dopp, hanning(10240), 0, 10240, fs, 'centered');

%% calculate amplitude & phase

% time of frames
[t, amplitude, phase] = deal(zeros(frame_num, 1));
t_diff = diff(pss_begin_idx)/N_f*T_f;       % (s)
for idx = 2:frame_num
    t(idx) = t(idx-1)+t_diff(idx-1);
end

pss = resample(get_pss(), sample_rate, 240e6);
pss_len = length(pss);
for idx = 1:frame_num
    % if idx<2000
    %     continue;
    % end
    recv = read_complex_binary2(IQ_Sample_file, pss_len, pss_begin_idx(idx));
    t_dopp = [0:pss_len-1]'/sample_rate;
    % f_d = dopp_param(1)*t(idx)+dopp_param(2);
    % dopp = exp(-j*2*pi*f_d*t_dopp);
    % recv = recv.*dopp;
    ratio = recv./pss;      % 440*1 complex
    amplitude(idx) = mean(abs(ratio));
    phase(idx) = phase_avg(angle(ratio));
end

%% Fig plot
figure(1);
plot(t, unwrap(phase));
title('phase change over time');
xlabel('time / s'); ylabel('phase(h)');
xlim([t(1) t(end)]);
figure(2);
plot(t, amplitude, LineWidth=1);
xlabel('time / s'); ylabel('abs(h)');
xlim([t(1) t(end)]);
title('amplitude change over time');
