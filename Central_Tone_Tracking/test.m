% clear all; clc; close all;
addpath ../Tool_Functions/;

mon = 8; day = 1; hr = 15; minu = 2;
sample_rate = 100e6;
center_freq = 11.575e9;
bw = sample_rate;
IQ_Sample_file = get_file_name(mon,day,hr,minu,center_freq,bw);
% f = fopen(IQ_Sample_file, 'rb');

%% 1
L = 1e4;
% L = 1.4*1e-3*100e6;
plot(abs(tmp));
m = zeros(length(signal), 1);
delay = round(1024*100/240);
tmp_shift = circshift(tmp, delay);
tmp_shift(1:delay) = 0;
window_idx = L;L = 1e4;
% L = 1.4*1e-3*100e6;
plot(abs(tmp));
m = zeros(length(signal), 1);
delay = round(1024*100/240);
tmp_shift = circshift(tmp, delay);
tmp_shift(1:delay) = 0;
window_idx = L;
ratio = zeros(length(tmp), 1);
c_ = zeros(length(tmp), 1);
p_ = zeros(length(tmp), 1);
c_(1) = sum(tmp(1:L).*tmp_shift(1:L));
p_(1) = norm(tmp(1:L));
idx_2 = L;
idx_1 = idx_2 - L + 1;
for idx_2 = L+1:length(tmp)
    idx_1 = idx_2 - L + 1;
    c = c - tmp(idx_1)*tmp_shift(idx_1)' + tmp(idx_2)*tmp_shift(idx_2)';
    p = p - abs(tmp(idx_1)) + abs(tmp(idx_2));
    c_(idx_1) = c; p_(idx_1) = p;
end
ratio = abs(p_).^2 ./ p.^2;
% for idx = 1:length(signal)
%     if idx
%     end
% end
%% 2
pss = get_pss();
pss_ = resample(pss, 100, 250);
figure;
plot(mag2db(abs(signal))-40);
hold on;
plot(mag2db(abs(xcorr(pss_, signal))));
ratio = zeros(length(tmp), 1);
c_ = zeros(length(tmp), 1);
p_ = zeros(length(tmp), 1);
c_(1) = sum(tmp(1:L).*tmp_shift(1:L));
p_(1) = norm(tmp(1:L));
idx_2 = L;
idx_1 = idx_2 - L + 1;
for idx_2 = L+1:length(tmp)
    idx_1 = idx_2 - L + 1;
    c = c - tmp(idx_1)*tmp_shift(idx_1)' + tmp(idx_2)*tmp_shift(idx_2)';
    p = p - abs(tmp(idx_1))+ abs(tmp(idx_2));
    c_(idx_1) = c; p_(idx_1) = p;
end
ratio = abs(p_).^2 ./ p.^2;
% for idx = 1:length(signal)
%     if idx
%     end
% end
%% pss xcorr
pss = get_pss();
pss_up = repmat(pss, [1 5]);
pss_up = reshape(pss_up', [numel(pss_up), 1]);
pss_dsamp = downsample(pss_up, 12);
figure;
% plot(mag2db(abs(signal))-40);
% hold on;
plot(mag2db(abs(xcorr(signal, pss_dsamp))));
hold on;
plot(mag2db(abs(xcorr(signal, resample(pss, 10, 24)))));

%% down sample test
[pss, p] = get_pss();
t = linspace(0, 1056/240e6, 440)';
pss_dsamp_2 = zeros(440, 1);
for idx = 1:1056
    pss_dsamp_2 = pss_dsamp_2+sinc(t*240e6+1-idx)*p(idx);
end
pss_dsamp_1 = resample(pss, 10, 24);
figure;
subplot(2,1,1);
plot(mag2db(abs(xcorr(signal, pss_dsamp_1))));
xlim([2e7 4e7-1]);
subplot(2,1,2);
% plot(mag2db(abs(xcorr(signal, pss_dsamp_2))));
plot(mag2db(abs(filter(conj(pss_dsamp_1(end:-1:1)), 1, signal))));
% xlim([2e7 4e7-1]);
