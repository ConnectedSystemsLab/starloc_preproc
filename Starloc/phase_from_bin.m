%%%%%%%%%% PART 1: doppler tracking and satellite splitting %%%%%%%%%%%%%%%
% first specify the date here, make sure that res.mat is saved to this
% folder (also for id doppler, simulation results needed), make sure the
% root directory is Starloc/
date = "2_3/";
% have a look at original tracks
addpath ../Tool_Functions/;
sample_rate = 2e6;
num_read_samples = 14e-3*sample_rate;
f = linspace(-sample_rate/2, sample_rate/2, num_read_samples);
load(date+"res.mat");
% filter out wideband sig & have a look at res
f_bin = res(:,2);
res = res(f_bin < 2e4 & f_bin > 0.9e4,:);
res = res(f_bin > 1.3595e4 | f_bin < 1.356e4,:);
clear f_bin;
plot(res(:,1),res(:,2),'.');
%% split different satellites
% need to specify when does a satellite appear and end, intervals can
% overlap
% 1_10
% period_starts = [90 130 170 210 255 310 540 780 910];
% period_ends = [120 150 210 255 310 333 580 810 960];
% 1_21-1
% period_starts = [150 180 580 670];
% period_ends = [180 230 640 690];
% 2_3-3Feb2024_22:03:48
period_starts = [5 58 155 205 390 450];
period_ends = [25 97 183 230 430 500];

num_periods = length(period_starts);
res_ = {};
for ii = 1:num_periods
    res_{ii} = [];
end
for ii = 1:size(res,1)
    pnt_ii = res(ii,:);
    t_ii = pnt_ii(1);
    for jj = 1:num_periods
        if t_ii >= period_starts(jj) && t_ii <= period_ends(jj)
            res_{jj} = [res_{jj} ; pnt_ii];
        end
    end
end
% track & connect
dopp_track_dict = {};
dopp_track_main_dict = {};
for sat_id = 1:num_periods
res_1sat = res_{sat_id};
num_points = size(res_1sat, 1);
tracks = {};
for ii = 1:num_points
    pnt_curr = res_1sat(ii,:); t_curr = pnt_curr(1); f_bin_cur = pnt_curr(2);
    if_assigned = false;
    for jj = 1:length(tracks)
        cur_track = tracks{jj};
        last_track_point = cur_track(end,:);
        t_last = last_track_point(1);
        f_bin_last = last_track_point(2);
        if abs(t_curr-t_last)<14e-3*15 && abs(f_bin_cur-f_bin_last)<15
            if_assigned = true;
            tracks{jj} = [tracks{jj} ; pnt_curr];
            break;
        end
    end
    if ~if_assigned
        tracks{length(tracks)+1} = pnt_curr;
    end
end
% find the longest & polyfit it
max_l = 0; max_idx = 0;
for jj = 1:length(tracks)
    tmp = tracks{jj};
    duration = tmp(end,1)-tmp(1,1);
    if duration > max_l
        max_l = duration;
        max_idx = jj;
    end
end
% pick up others
track_main = tracks{max_idx};
a = polyfit(track_main(:,1), track_main(:,2), 1);
bin_freq = sample_rate/num_read_samples;
bin_spacing = round(44e3/bin_freq);
for ii = 1:num_points
    pnt_curr = res_1sat(ii,:); t_curr = pnt_curr(1); f_bin_cur = pnt_curr(2);
    f_bin_tar = polyval(a,t_curr);
    for jj = -8:8
        dis = abs(f_bin_tar+jj*bin_spacing-f_bin_cur);
        if dis < 10
            bias = [0 jj*bin_spacing 0 0 0];
            track_main = [track_main ; res_1sat(ii,:)-bias];
            break;
        end
    end    
end
a = polyfit(track_main(:,1), track_main(:,2), 2);
dopp_track = [];
for ii = 1:num_points
    pnt_curr = res_1sat(ii,:); t_curr = pnt_curr(1); f_bin_cur = pnt_curr(2);
    f_bin_tar = polyval(a,t_curr)+[-8:8]*bin_spacing;
    dis = f_bin_cur-f_bin_tar;
    if min(abs(dis)) < 10
        dopp_track = [dopp_track ; res_1sat(ii,:)];
        [~,argmin] = min(abs(dis));
    end
end
dopp_track_dict{sat_id} = dopp_track;
dopp_track_main_dict{sat_id} = track_main;
% remove that from res
if sat_id ~= num_periods
    if period_starts(sat_id+1) <= period_ends(sat_id)
        for ii = 1:size(dopp_track,1)
            rm_idx = find(sum(res_{sat_id+1}==dopp_track(ii, :),2)==5);
            res_{sat_id+1}(rm_idx, :) = [];
        end
    end
end
end
%% plot doppler bin
figure(10); hold on;
plot(res(:,1),res(:,2),'.', DisplayName="discrete");
for sat_id = 1:num_periods
    dopp_track = dopp_track_dict{sat_id};
    plot(dopp_track(:,1), dopp_track(:,2), '.', DisplayName="sat #"+num2str(sat_id));
end
legend;xlabel('t / s'); ylabel('f_d / Hz'); title('Tracked central tones');
%% plot delta_phi
figure(2);
for sat_id = 1:num_periods
    subplot(2,3,sat_id)
    dopp_track = dopp_track_dict{sat_id};
    hold on;
    plot(dopp_track(:,1), angle(dopp_track(:,3))-angle(dopp_track(:,4)), '.')
    plot(dopp_track(:,1), angle(dopp_track(:,3))-angle(dopp_track(:,5)), '.')
    title("Sat #"+num2str(sat_id))
    xlabel('t (s)');
    ylabel('phase diff (rad)')
    legend("rx0/rx1", "rx0/rx2");
    legend;
    % ylim([-pi pi]);
    % clf;
end
%%
%%%%%%%%%% PART 2: ID %%%%%%%%%%%%%%%
%% ID - cheat, if not cheating, skip and run the following section
% 1_10
% id_dict{1} = "STARLINK-6365";
% id_dict{2} = "STARLINK-5247";
% id_dict{3} = "STARLINK-5729";
% id_dict{4} = "STARLINK-5784";
% id_dict{5} = "STARLINK-5761";
% id_dict{6} = "STARLINK-30859";
% id_dict{7} = "STARLINK-30966";
% id_dict{8} = "STARLINK-5237";
% id_dict{9} = "STARLINK-5598";

% 1_21 -1
id_dict{1} = "STARLINK-6247";
id_dict{2} = "STARLINK-4175";
id_dict{3} = "STARLINK-6079";
id_dict{4} = "STARLINK-6245";


%% doppler sim & identify
% first load the doppler from date folder
load(date+"output_doppler.mat");
sat_sim_fn = fieldnames(sat_dopp_dict);
for sat_id = 1:num_periods
    dopp_main = dopp_track_main_dict{sat_id};
    dopp_main(:,2) = f(dopp_main(:,2));
    t = unique(dopp_main(:,1));
    dopp_main_ = zeros(length(t), 2);
    for idx = 1:length(t)
        t_now = t(idx);
        ii = find(dopp_main(:,1)==t_now);
        dopp_main_(idx,1) = t_now;
        dopp_main_(idx,2) = mean(dopp_main(ii,2));
    end
    dopp_track_main_dict{sat_id} = dopp_main_;
end
% id
id_dict = {};
freq_offset = zeros(num_periods, 1);
for sat_id = 1:num_periods
    min_var = inf;
    dopp_main = dopp_track_main_dict{sat_id};
    dopp_main(:,1) = dopp_main(:,1);
    t_1 = dopp_main(1,1); t_2 = dopp_main(end,1);
    [~,sim_idx_1] = min(abs(t_list-t_1));
    [~,sim_idx_2] = min(abs(t_list-t_2));
    for idx = 1:length(sat_sim_fn)
        name = sat_sim_fn{idx};
        sim_data = getfield(sat_dopp_dict, name);
        sim_dopp = sim_data(1,:);
        if sum(isnan(sim_dopp(sim_idx_1:sim_idx_2)))
            continue;
        end
        a = polyfit(t_list(sim_idx_1:sim_idx_2), sim_dopp(sim_idx_1:sim_idx_2), 1);
        dopp_tar = polyval(a,dopp_main(:,1));
        dopp_var = var(dopp_main(:,2)-dopp_tar);
        if dopp_var < min_var
            min_var = dopp_var;
            id_dict{sat_id} = name;
            freq_offset(sat_id) = mean(-(dopp_main(:,2)-dopp_tar));
        end
    end
end
%% plot id result
% results saved to variable "id_dict", can also see its name in the figure
% window
% since there are too many satellites, click on "edit plot" in the figure
% window tool bar and right click the simulated dashed curve and "open
% property inspector" to see its name
figure;hold on;
for idx = 1:length(sat_sim_fn)
    name = sat_sim_fn{idx};
    sim_data = getfield(sat_dopp_dict, name);
    plot(t_list, sim_data(1,:), '--', DisplayName=name);
end
for sat_id = 1:num_periods
    dopp_main = dopp_track_main_dict{sat_id};
    plot(dopp_main(:,1), dopp_main(:,2)+freq_offset(sat_id), '.')
end

%% process delta_phi
figure;
for sat_good = 1:num_periods
dopp_track = dopp_track_dict{sat_good};
t_repeat = dopp_track(:,1);
del_phi_repeat_01 = unwrap(angle(dopp_track(:,3))-angle(dopp_track(:,4)));
del_phi_repeat_02 = unwrap(angle(dopp_track(:,3))-angle(dopp_track(:,5)));
del_phi_repeat_12 = unwrap(angle(dopp_track(:,4))-angle(dopp_track(:,5)));
coeff_01 = polyfit(t_repeat, del_phi_repeat_01, 2);
coeff_02 = polyfit(t_repeat, del_phi_repeat_02, 2);
coeff_12 = polyfit(t_repeat, del_phi_repeat_12, 2);
% compare with gt
load(date+"output_doppler.mat")
sat_sim_fn = fieldnames(sat_dopp_dict);
name = id_dict{sat_good};
sat_dopp = getfield(sat_dopp_dict, name);
dopp_track = dopp_track_dict{sat_good};
t = unique(dopp_track(:,1));
t_sim = t_list(t_list>t(1)-1&t_list<t(end)+1);
az_gt = sat_dopp(2,:)'; az_gt = az_gt(t_list>t(1)-1&t_list<t(end)+1);
el_gt = sat_dopp(3,:)'; el_gt = el_gt(t_list>t(1)-1&t_list<t(end)+1);

% calculate the gt delta phi
% ref: https://msl.cs.uiuc.edu/planning/node102.html
r = 1e10; d = 13.25e-2; lambda = 3e8/11.325e9;
loc_3d = r*[cosd(el_gt).*sind(az_gt) cosd(el_gt).*cosd(az_gt) sind(el_gt)];
loc_1 = [0 ; 0 ; 0];
loc_0 = [0 ; -d ; 0];
loc_2 = [d ; 0 ; 0];
alpha = 1; R_alpha = [cosd(alpha) -sind(alpha) 0;sind(alpha) cosd(alpha) 0;0 0 1];
beta = -1.34; R_beta = [cosd(beta) 0 sind(beta);0 1 0;-sind(beta) 0 cosd(beta)];
gamma = 2.6; R_gamma = [1 0 0;0 cosd(gamma) -sind(gamma);0 sind(gamma) cosd(gamma)];
R = R_alpha*R_beta*R_gamma;
range_1 = vecnorm((loc_3d-(R*loc_1)')');
range_0 = vecnorm((loc_3d-(R*loc_0)')');
range_2 = vecnorm((loc_3d-(R*loc_2)')');
del_phi_01_gt = -(range_0-range_1)/lambda*2*pi;
del_phi_02_gt = -(range_0-range_2)/lambda*2*pi;
del_phi_12_gt = -(range_1-range_2)/lambda*2*pi;

load(date+"info.mat","ref_sig_idx");
load(date+"info.mat","phase_offset_01");
load(date+"info.mat","phase_offset_21");
[~,ref_sig_ii] = min(abs(ref_sig_idx(:,1)/sample_rate-t_sim(1)));
phase_offset_01 = phase_offset_01(ref_sig_ii);
phase_offset_12 = -phase_offset_21(ref_sig_ii);
del_phi_repeat_01 = del_phi_repeat_01-phase_offset_01;
del_phi_repeat_12 = del_phi_repeat_12-phase_offset_12;
param_01 = polyfit(t_repeat, del_phi_repeat_01, 2);
param_12 = polyfit(t_repeat, del_phi_repeat_12, 2);
candidates_01 = polyval(param_01, t_sim)+[-2:2]'*2*pi;
candidates_12 = polyval(param_12, t_sim)+[-2:2]'*2*pi;
dis_01 = mean(candidates_01-del_phi_01_gt,2);
dis_12 = mean(candidates_12-del_phi_12_gt,2);
[~, min_idx] = min(abs(dis_01));
del_phi_repeat_01 = del_phi_repeat_01+2*pi*(min_idx-3);
[~, min_idx] = min(abs(dis_12));
del_phi_repeat_12 = del_phi_repeat_12+2*pi*(min_idx-3);
param_01 = polyfit(t_repeat, del_phi_repeat_01, 2);
param_12 = polyfit(t_repeat, del_phi_repeat_12, 2);
% plot
subplot(2,3,sat_good);hold on; 
plot(t_repeat,del_phi_repeat_01, '.',DisplayName="angle(rx0/rx1) - real")
plot(t_repeat,del_phi_repeat_12, '.',DisplayName="angle(rx1/rx2) - real")
plot(t_sim, del_phi_01_gt,  LineWidth=3, Color=[0.00,0.45,0.74],DisplayName="angle(rx0/rx1) - simulated")
plot(t_sim, del_phi_12_gt,  LineWidth=3, Color=[0.85,0.33,0.10],DisplayName="angle(rx1/rx2) - simulated")
plot(t_repeat, polyval(param_01,t_repeat),'--',DisplayName='angle(rx0/rx1) - LS',LineWidth=3,Color=[1,0.45,0.74])
plot(t_repeat, polyval(param_12,t_repeat),'--',DisplayName='angle(rx1/rx2) - LS',LineWidth=3,Color=[0,0.33,0.10])
title("Sat #"+num2str(sat_good)+", gap01="+num2str(mean(polyval(param_01,t_sim)-del_phi_01_gt))+", gap12="+num2str(mean(polyval(param_12,t_sim)-del_phi_12_gt)))
legend
% plot(t,polyval(coeff_01, t)-phase_offset_01)
% plot(t,polyval(coeff_02, t)-phase_offset_02)
end

%%%%%%%%%% PART 3: test parts %%%%%%%%%%%%%%%
%% test
bias_err = [];
slope_err = [];
theta_err_list = [-4:0.2:4];
phi_err_list = [-4:0.2:4];
gamma_err_list = [0];
for ii = 1:length(theta_err_list)
theta_err_list(ii)
for jj = 1:length(phi_err_list)
phi_err_list(jj)
for kk = 1:length(gamma_err_list)
tmp = zeros(1,8); tmp_ = zeros(1,8);
for sat_good = 1:4
dopp_track = dopp_track_dict{sat_good};
t_repeat = dopp_track(:,1);
del_phi_repeat_01 = unwrap(angle(dopp_track(:,3))-angle(dopp_track(:,4)));
del_phi_repeat_02 = unwrap(angle(dopp_track(:,3))-angle(dopp_track(:,5)));
del_phi_repeat_12 = unwrap(angle(dopp_track(:,4))-angle(dopp_track(:,5)));
coeff_01 = polyfit(t_repeat, del_phi_repeat_01, 2);
coeff_02 = polyfit(t_repeat, del_phi_repeat_02, 2);
coeff_12 = polyfit(t_repeat, del_phi_repeat_12, 2);
% compare with gt
load ../../box/1_21/output_doppler_1_new.mat
sat_sim_fn = fieldnames(sat_dopp_dict);
name = id_dict{sat_good};
sat_dopp = getfield(sat_dopp_dict, name);
dopp_track = dopp_track_dict{sat_good};
t = unique(dopp_track(:,1));
t_sim = t_list(t_list>t(1)-1&t_list<t(end)+1);
az_gt = sat_dopp(2,:)'; az_gt = az_gt(t_list>t(1)-1&t_list<t(end)+1);
el_gt = sat_dopp(3,:)'; el_gt = el_gt(t_list>t(1)-1&t_list<t(end)+1);
r = 1e8;
d = 13.25e-2;
lambda = 3e8/11.325e9;
loc_3d = r*[cosd(el_gt).*sind(az_gt) cosd(el_gt).*cosd(az_gt) sind(el_gt)];
theta_err = theta_err_list(ii);
phi_err = phi_err_list(jj);
gamma_err = gamma_err_list(kk);
rx_0 = [0 -d 0]; rx_2 = [-d 0 0];
% R_yaw = [cosd(yaw_err) -sind(yaw_err) 0; sind(yaw_err) cosd(yaw_err) 0 ; 0 0 1];
% R_pitch = [cosd(pitch_err) 0 -sind(pitch_err);0 1 0;sind(pitch_err) 0 cosd(pitch_err)];
% R_roll = [1 0 0; 0 cosd(roll_err) -sind(roll_err);0 sind(roll_err) cosd(roll_err)];
range_1 = vecnorm((loc_3d-[0 0 0])');
% range_0 = vecnorm((loc_3d-rx_0*R_yaw'*R_pitch'*R_roll')');
% range_2 = vecnorm((loc_3d-rx_2*R_yaw'*R_pitch'*R_roll')');
range_2 = vecnorm((loc_3d-d*[-cosd(theta_err)*cosd(phi_err) -sind(theta_err)*cosd(phi_err) -sind(phi_err)])');
range_0 = vecnorm((loc_3d-d*[-sind(theta_err)*cosd(gamma_err) -cosd(theta_err)*cosd(gamma_err) sind(gamma_err)])');
% d*[-sind(theta_err)*cosd(gamma_err) -cosd(theta_err)*cosd(gamma_err) sind(gamma_err)]
del_phi_01_gt = -(range_0-range_1)/lambda*2*pi;
del_phi_02_gt = -(range_0-range_2)/lambda*2*pi;
del_phi_12_gt = -(range_1-range_2)/lambda*2*pi;

phase_offset_01 = -1.8778144183525671;
phase_offset_02 = 1.419487080207238;
phase_offset_12 = -2.9858594869711377;
del_phi_repeat_01 = del_phi_repeat_01-phase_offset_01;
del_phi_repeat_12 = del_phi_repeat_12-phase_offset_12;
param_01 = polyfit(t_repeat, del_phi_repeat_01, 1);
param_01_gt = polyfit(t_sim, del_phi_01_gt, 1);
param_12 = polyfit(t_repeat, del_phi_repeat_12, 1);
param_12_gt = polyfit(t_sim, del_phi_12_gt, 1);
candidates_01 = polyval(param_01, t_sim)+[-2:2]'*2*pi;
candidates_12 = polyval(param_12, t_sim)+[-2:2]'*2*pi;
dis_01 = mean(candidates_01-del_phi_01_gt,2);
dis_12 = mean(candidates_12-del_phi_12_gt,2);
[min_err_01, min_idx] = min(abs(dis_01));
del_phi_repeat_01 = del_phi_repeat_01+2*pi*(min_idx-3);
[min_err_12, min_idx] = min(abs(dis_12));
del_phi_repeat_12 = del_phi_repeat_12+2*pi*(min_idx-3);
param_01 = polyfit(t_repeat, del_phi_repeat_01, 1);
param_12 = polyfit(t_repeat, del_phi_repeat_12, 1);
tmp(sat_good*2-1) = min_err_01;
tmp(sat_good*2) = min_err_12;
tmp_(sat_good*2-1) = abs(param_01(1)-param_01_gt(1));
tmp_(sat_good*2) = abs(param_12(1)-param_12_gt(1));
% plot
% if theta_err == 2.6 && phi_err == -3
if size(bias_err,1) == 1398
subplot(2,2,sat_good);hold on; 
plot(t_repeat,del_phi_repeat_01, '.',DisplayName="angle(rx0/rx1) - real")
% plot(t_repeat,del_phi_repeat_02-phase_offset_02, '.',DisplayName="angle(rx0/rx2) - real")
plot(t_repeat,del_phi_repeat_12, '.',DisplayName="angle(rx1/rx2) - real")
plot(t_sim, del_phi_01_gt,  LineWidth=3, Color=[0.00,0.45,0.74],DisplayName="angle(rx0/rx1) - simulated")
% plot(t_sim, del_phi_02_gt,  LineWidth=3, Color=[0.85,0.33,0.10],DisplayName="angle(rx0/rx2) - simulated")
plot(t_sim, del_phi_12_gt,  LineWidth=3, Color=[0.85,0.33,0.10],DisplayName="angle(rx1/rx2) - simulated")
% plot(t_sim, del_phi_12_gt,  LineWidth=3, Color=[0.93,0.69,0.13])
plot(t_repeat, polyval(param_01,t_repeat),'--',DisplayName='angle(rx0/rx1) - LS',LineWidth=3,Color=[1,0.45,0.74])
plot(t_repeat, polyval(param_12,t_repeat),'--',DisplayName='angle(rx1/rx2) - LS',LineWidth=3,Color=[0,0.33,0.10])
title("Sat #"+num2str(sat_good))
legend
end
% plot(t,polyval(coeff_01, t)-phase_offset_01)
% plot(t,polyval(coeff_02, t)-phase_offset_02)
end
bias_err = [bias_err ; tmp];
slope_err = [slope_err ; tmp_];
end
end
end
%%
hold on;
plot(bias_err(:,2))
plot(bias_err(:,4))
plot(bias_err(:,6))
plot(bias_err(:,8))
%%
hold on;
plot(slope_err(:,2))
plot(slope_err(:,4))
plot(slope_err(:,6))
plot(slope_err(:,8))