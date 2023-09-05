clear all; close all; clc;
addpath ../Tool_Functions/;
%%
% load file
mon = 8; day = 12; hr = 10; minu = 7;
sample_rate = 100e6;
center_freq = 11.575e9;
IQ_Sample_file = get_file_name(mon, day, hr, minu, center_freq, sample_rate);

%% pss detect
% [pss_begin_idx] = frame_detect_pss(IQ_Sample_file, sample_rate, 0);
load('pss_begin_idx.mat');
pss_begin_idx=[];
if isempty(pss_begin_idx)
    [pss_begin_idx] = frame_detect_pss(IQ_Sample_file, sample_rate, 0);
end
%%
T_f = 1/750;
N_f = T_f*sample_rate;
frame_num = length(pss_begin_idx);

%% CFO estimation

pss = get_pss();                
pss = pss(33:end); % 1024 points pss sequence (cp removed)
[t, angs] = deal(zeros(frame_num, 1));
t_diff = diff(pss_begin_idx)/N_f*T_f;       % (s)
for idx = 2:frame_num
    t(idx) = t(idx-1)+t_diff(idx-1);
end

for idx = 1:frame_num
    pss_recv = read_complex_binary2(IQ_Sample_file, 440, pss_begin_idx(idx));
    % resample the recieved signal to 240 MHz
    % if idx<2000
    %     continue;end
    pss_recv = my_resample(pss_recv, 240, 100);
    % remove cp
    pss_recv = pss_recv(33:end);
    
    % extract 7 repeated sub-sequences
    sub_idxs = 128*[1:7]';
    sub_seq = zeros(7, 128);
    for ii = 1:7
        sub_seq(ii,:) = pss_recv(sub_idxs(ii)+1:sub_idxs(ii)+128);
    end
    % calculate subseq_{i+1}/subseq_{i}
    for ii = 1:6
        ratio(ii) = conj(sub_seq(ii+1,:))*sub_seq(ii,:).';
        % ratio(ii) = phase_avg(unwrap(angle(conj(sub_seq(ii+1,:)).*sub_seq(ii,:))));
    end
    % average the angle of 6 ratios
    angs(idx) = mean(angle(ratio));plot(angle(ratio))
    % angs(idx) = phase_avg(ratio);plot(ratio)
end

% calculate cfo from the angles
cfo = -(240e6/(2*pi*128))*unwrap(angs);
% do the linear regression
[k, b] = least_square(t, cfo);
figure(10); plot(t, cfo); hold on; plot(t, k*t+b, '--', LineWidth=1);
