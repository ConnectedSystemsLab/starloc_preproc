%%
clear all; close all; clc;
addpath ../;
addpath ../Tool_Functions/;
setParam;

%% load filename
%  IQ_Sample_file = "D:\Desktop\study\2023_summer\starlink_ofdm\time_11_27_freq_11_575G_bw_2.0M.dat";
mon = 9; day = 14; hr = 11; minu = 27;
sample_rate = 2e6;
center_freq = 11.575e9;
IQ_Sample_file = get_file_name(mon, day, hr, minu, center_freq, sample_rate);
%%
f_hardware = 145642; % not needed
central_bw = 1.024e6;
T_avg = 1;
n_fft = 2^10;
t_fft = n_fft/central_bw;
num_read_samples = T_avg*sample_rate; %t_fft*sample_rate;

idx = 1;
fig = figure;
time = num_read_samples/sample_rate;
move_by = num_read_samples/2;
time_array = [];
peak_array = [];
while 1
    sig = read_complex_binary2(IQ_Sample_file, num_read_samples, idx);
    if length(sig) ~= num_read_samples
        fprintf("breaking\n");
        close(fig);
        break;
    end
    
    sig = resample(sig, central_bw, sample_rate);
    [sig_fft_abs, f] = fft_avg(sig, central_bw, n_fft, f_hardware);
    [max, midx] = maxk(sig_fft_abs, 20); % find 10 peaks - 9 tones and 1 constant hardware induced
    mean_sig_amp = mean(sig_fft_abs);
    peaks = [];
    peaks_idx = [];
    for i=1:1:length(max)
        if max(i) > mean(sig_fft_abs)+2*std(sig_fft_abs) 
            if i>1 && any((abs(midx(i)-midx(1:i-1)) < 5))
                continue
            end
            peaks = [peaks max(i)];
            peaks_idx = [peaks_idx midx(i)];
        end
    end
    peak_subarray = zeros(1, n_fft);
    peak_subarray(peaks_idx) = peaks;
    time_array = [time_array; time];
    peak_array = [peak_array; peak_subarray];
    
%     alpha = 2.5;
%     opts = {'Window', gausswin(n_fft,alpha), 'FFTLength', n_fft};
%     stft(sig, sample_rate, opts{:});
%     plot((abs(fftshift(fft(sig)./sqrt(num_read_samples)))));
%     ylim([0,0.05]);

    scatter(peaks_idx, peaks, 'filled');
    xlim([0,length(sig_fft_abs)])
    hold on;
    plot(sig_fft_abs);
    ylim([0,70])
    title(join([num2str(time), " ",num2str(peak2rms(sig_fft_abs))]));
    pause(0.1);
    clf;
    idx = idx+move_by;
    time = time+move_by/sample_rate;
    if time == 280
        1
    end
end
%% select one sat
tt = []; dd = [];
for i = 1:1:length(time_array)
    peak_idxes = find(peak_array(i,:));
    peak_idxes = peak_idxes(peak_idxes~=518);
    if time_array(i)<272.5 || time_array(i)>309.5
        continue
    end
    if isempty(peak_idxes)
        continue
    end
    tt = [tt ; time_array(i)];
    [~,ii] = min(abs(peak_idxes-(-2.92*time_array(i)+1336)));
    dd = [dd ; peak_idxes(ii)];
end
%%
figure;
for i = 1:1:length(time_array)
    peak_idxes = find(peak_array(i,:));
    peak_idxes = peak_idxes(peak_idxes~=518);
    scatter(time_array(i)*ones(1,length(peak_idxes)), peak_idxes, 'blue', 'filled');
    hold on;
end
%% point-to-curve assignment plot (run python script to get output)
load('output_tracks.mat')
field_Names = fieldnames(tracks_dict);
for i=1:1:length(fieldNames)
arr = tracks_dict.(fieldNames{i});
scatter(arr(:,1), arr(:,2), 'filled')
hold on;
end
%%
% Fill in the missing points in doppler curve with nan
% load('track_5_coords.mat');
track_5_coords = track_28_coords;
% track_5_coords(:,1);
start_time_stamp = track_5_coords(1,1);
stop_time_stamp = track_5_coords(end,1);
freq_bin = track_5_coords(:,1);
time_step = 0.5;
all_time_stamps = start_time_stamp:time_step:stop_time_stamp;
all_freq_track_points = NaN([1 length(all_time_stamps)]);
m = 1;
f = -1e6:2e6/1024:1e6-1;
for i=1:1:length(all_time_stamps)
    expected_ts = all_time_stamps(i);
    if any(track_5_coords(:,1)==expected_ts)
        all_freq_track_points(i) = f(track_5_coords(m,2));
        m = m+1;
    end
end

%%
% get complete track points for all tracks
tracks_cell = struct2cell(tracks_dict);
complete_tracks_cell = cell([length(tracks_cell) 1]);
for i=1:1:length(tracks_cell)
    track = tracks_cell{i};
    start_time_stamp = track(1,1);
    stop_time_stamp = track(end,1);
    freq_bin = track(:,1);
    time_step = 0.5;
    all_time_stamps = start_time_stamp:time_step:stop_time_stamp;
    all_freq_track_points = NaN([1 length(all_time_stamps)]);
    m = 1;
    f = -1e6:2e6/1024:1e6-1;
    for j=1:1:length(all_time_stamps)
        expected_ts = all_time_stamps(j);
        if any(track(:,1)==expected_ts)
            all_freq_track_points(j) = f(track(m,2));
            m = m+1;
        end
    end
    complete_tracks_cell{i} = [all_time_stamps;all_freq_track_points]';
end
%%
% f_hardware = 145642; % not needed
% T_avg = 1;
% central_bw = 1.024e6;
% n_fft = 1024;
% t_fft = n_fft/central_bw;
% num_read_samples = t_fft*sample_rate;
% % num_read_samples = T_avg*sample_rate;
% ​
% idx = 1;
% figure;
% while idx <= pss_begin_idx(end)
%     sig = read_complex_binary2(IQ_Sample_file, num_read_samples, idx);
%     if length(sig) ~= num_read_samples
%         fprintf("breaking")
%         break;
%     end
%     
%     sig = resample(sig, central_bw, sample_rate);
%     [sig_fft_abs, f] = fft_avg(sig, central_bw, n_fft, f_hardware);
%     % sig_fft = fftshift(fft(sig, n_fft))/n_fft;
%     % sig_fft_abs = abs(sig_fft);
%     f = linspace(-central_bw/2, central_bw/2, n_fft)';
%     plot(mag2db(sig_fft_abs));
%     % xlim([6e4,7.5e4]);
%     % ylim([0,100]);
%     pause(0.1);
%     
% end
%%
figure;
struct_cell = struct2cell(tracks_dict);
for i=1:1:length(struct_cell)
    scatter(struct_cell{i}(1:end,1), (struct_cell{i}(:,2)));
    title(i);
    pause(0.5);
    clf;
end