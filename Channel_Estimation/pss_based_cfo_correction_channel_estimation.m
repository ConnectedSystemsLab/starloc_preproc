clear all; close all; clc;
addpath ../Tool_Functions/;
setParam;

%% load filename
mon = 8; day = 12; hr = 10; minu = 7;
sample_rate = 100e6;
center_freq = 11.575e9;
IQ_Sample_file = get_file_name(mon, day, hr, minu, center_freq, sample_rate);

%% get pss indexes to use in extracting frames - run only if pss_begin_idx has not been saved
load('pss_begin_idx.mat');

if isempty(pss_begin_idx)
    [pss_begin_idx] = frame_detect_pss(IQ_Sample_file, sample_rate);
end

%%
frame_num = length(pss_begin_idx);

local_pss = resample(get_pss(), sample_rate, 240e6);
