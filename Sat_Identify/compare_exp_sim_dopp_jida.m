% This script identifies the satellites id
% make sure the running path is "Sat_Identify/"

%% load tracks identified from exp data
load('../Central_Tone_Tracking/output_tracks_2.mat');
tracks_cell_pre = struct2cell(tracks_dict);
num_tracks_pre = length(tracks_cell_pre);
tracks_cell = {};
time_step = 0.5;

for ii = 1:num_tracks_pre
    track = tracks_cell_pre{ii};
    num_points = size(track, 1);
    % discard short tracks
    if time_step*num_points < 10
        continue;
    end

    freq_bin = track(:, 1);
    
    t = [track(1, 1):time_step:track(end, 1)]';
    freq_track = NaN(length(t), 1);
    f = linspace(-1.024e6/2, 1.024e6/2, 1024)';
    for jj = 1:num_points
        t_in_track = track(jj, 1);
        freq_track(t == t_in_track) = f(track(jj, 2));
    end
    % append new tracks
    tracks_cell{end+1} = [t freq_track];
end
tracks_cell = tracks_cell';
%% for debug & visulization
% original discrete points
load('../Central_Tone_Tracking/peak_arr_9_14_11_27_5.mat');
time_array = [0.5:time_step:(size(peak_array, 1)-1)*time_step+0.5]';
hold on;
for ii = 1:1:length(time_array)
    peak_idxes = find(peak_array(ii,:));
    peak_idxes = peak_idxes(peak_idxes~=518);
    plot(time_array(ii)*ones(1,length(peak_idxes)), f(peak_idxes), '.', Color=[0 0 1]);
end
for ii = 1:length(tracks_cell)
    track = tracks_cell{ii};
    t = track(:, 1);
    freq_track = track(:, 2);
    plot(t, freq_track, LineWidth=2);
end