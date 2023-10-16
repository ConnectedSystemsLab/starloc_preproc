%% generate the matrix of colors for plots 
c = turbo(256);
c = c(1:5:end, :);
perm_indices = randperm(length(c));
shuffled_c = c(perm_indices, :);
%% load tracks identified from exp data and plug NaN where ever you have no track point
load('Central_Tone_Tracking/output_tracks_dict.mat')
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
    f = -1.024e6/2:1.024e6/1024:1.024e6/2;
    for j=1:1:length(all_time_stamps)
        expected_ts = all_time_stamps(j);
        if any(track(:,1)==expected_ts)
            all_freq_track_points(j) = f(track(m,2));
            m = m+1;
        end
    end
    complete_tracks_cell{i} = [all_time_stamps;all_freq_track_points]';
end
%% parameter search for all tracks 

% load('Sat_Identify/dopp_recover_cell_9_14_11_27.mat');
% uncomment below if you don't have the file saved
F_c = 11.575e9;
dopp_recover_cell = cell([length(complete_tracks_cell) 1]);
for i=1:1:length(complete_tracks_cell)
    dopp_exp = complete_tracks_cell{i}(:,2);
    if length(dopp_exp) < 10
        continue
    end
%     t = [0:length(dopp_exp)-1]'*0.5;
    t = complete_tracks_cell{i}(:,1);
    [dopp_recover, orb_param] = orbit_estimate(t, dopp_exp, F_c);
    dopp_recover_cell{i} = [complete_tracks_cell{i}(:,1) dopp_recover];
%     plot(t, dopp_recover);
%     hold on;
end
%% plot estimated doppler

for i=1:1:length(dopp_recover_cell)
    if length(dopp_recover_cell{i}) > 1
        plot(dopp_recover_cell{i}(2:end,1), diff(dopp_recover_cell{i}(:,2)), '--', 'Color', shuffled_c(i,:), 'LineWidth', 1.5);
        hold on;
    else
        disp(i)
    end
end
    
%% get doppler obtained from simulations and plot
load('Satellite_Sim/python_code/sat_dopp_dict.mat')
gt_cell = struct2cell(sat_dopp_dict);
for i=1:1:length(gt_cell)
if length(gt_cell{i})>1
plot(gt_cell{i}(2:end,1), diff(-gt_cell{i}(:,2)), 'Color', shuffled_c(i,:), 'LineWidth', 1.5);
hold on;
end
end

%% plot track_dict vs recovered doppler
figure;
for i=1:1:length(complete_tracks_cell)
    if length(complete_tracks_cell{i})>1
        plot(complete_tracks_cell{i}(:,1), complete_tracks_cell{i}(:,2), '--', 'Color', shuffled_c(i,:), 'LineWidth', 1.5);
        hold on;
    end
end

for i=1:1:length(dopp_recover_cell)
    if length(dopp_recover_cell{i})>1
        plot(dopp_recover_cell{i}(:,1), dopp_recover_cell{i}(:,2), 'Color', shuffled_c(i,:), 'LineWidth', 1.5);
        hold on;
    end
end