%% experiment setup

clear all; clc;
addpath ../Tool_Functions/;

mon = 8; day = 1; hr = 14; minu = 59;
sample_rate = 100e6;
center_freq = 11.575e9;
bw = sample_rate;
IQ_Sample_file = get_file_name(mon,day,hr,minu,center_freq,bw);
f = fopen(IQ_Sample_file, 'rb');

%% frame detection
frame_idxs = frame_detect_pss(IQ_Sample_file, sample_rate);
