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
    plot(t, freq_track, LineWidth=2.5);
end

%% compare with the simulated result
% load simulated result
close all;
load("../Satellite_Sim/matlab_code/sat_struct.mat");
num_sats = length(sat_struct);
sat_candidates = [];
% avoid low elevation & quick passing sats
for idx = 1:num_sats
    tt = sat_struct(idx).t;
    sampleTime = tt(2)-tt(1);
    dopp = sat_struct(idx).doppler;
    el = sat_struct(idx).elevation;
    ele_max = max(el);
    if ele_max < 60
        continue;
    end
    sat_struct(idx).doppler(el < 30) = NaN;
    if ~isempty(find(~isnan(dopp)))
        visible_duration = sum(~isnan(sat_struct(idx).doppler))*sampleTime;
        if visible_duration >= 20
            sat_candidates = [sat_candidates ; sat_struct(idx)];
        end
    end
end
hold on;
for idx = 1:length(sat_candidates)
    plot(sat_candidates(idx).t, sat_candidates(idx).doppler, ...
        'DisplayName', sat_candidates(idx).name, 'LineStyle', '--');
end
legend
for ii = 1:length(tracks_cell)
    cfo(ii) = 0;
    err = inf;
    mostlikely_name = "";
    track = tracks_cell{ii};
    t = track(:, 1);
    freq_track = track(:, 2);
    % plot(t, freq_track, LineWidth=1);
    for idx = 1:length(sat_candidates)
        possible_sat = sat_candidates(idx);
        t_sat = possible_sat.t;
        t_idx = (t_sat >= t(1)) & (t_sat <= t(end));
        dopp_sat = possible_sat.doppler;
        dopp_sat = dopp_sat(t_idx);
        % if sum(isnan(dopp_sat)) ~= 0
        %     continue;
        % end
        is_nan = isnan(dopp_sat) | isnan(freq_track);
        if sum(~is_nan) == 0
            continue;
        end
        variance = var(freq_track(~is_nan) - dopp_sat(~is_nan));
        if variance < err
            err = variance;
            cfo(ii) = mean(freq_track(~is_nan) - dopp_sat(~is_nan));
            mostlikely_name = possible_sat.name;
        end
    end
    plot(t, freq_track-cfo(ii), LineWidth=1.5, ...
        DisplayName="(likely "+mostlikely_name+")");
end
% % interpolate the tracked tones
% for ii = 1:length(tracks_cell)
%     track = tracks_cell{ii};
%     t = track(:, 1);
%     freq_track = track(:, 2);
%     is_nan = isnan(freq_track);
%     t = t(~is_nan); freq_track = freq_track(~is_nan);
%     poly_coeff = polyfit(t, freq_track, 4);
%     % plot(t, freq_track, t, polyval(poly_coeff, t), '--');
%     track(~is_nan, 2) = polyval(poly_coeff, t);
%     tracks_cell{ii} = track;
% end
% hold on;
% for ii = 1:length(tracks_cell)
%     track = tracks_cell{ii};
%     t = track(:, 1);
%     freq_track = track(:, 2);
%     poly_coeff = polyfit(t, freq_track, 3);
%     track(:, 2) = polyval(poly_coeff, t);
%     plot(t(2:end), diff(freq_track)/time_step, LineWidth=1);
% end