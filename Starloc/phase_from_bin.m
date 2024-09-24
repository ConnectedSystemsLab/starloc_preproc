%%%%%%%%%% PART 1: doppler tracking and satellite splitting %%%%%%%%%%%%%%%
% first specify the date here, make sure that res.mat is saved to this
% folder (also for id doppler, simulation results needed), make sure the
% root directory is Starloc/
% date_ = "13Mar2024_02_20/";
% date_ = "6Mar2024_04_19/";
% have a look at original tracks
addpath ../Tool_Functions/;
if date_(end) ~= '/'
    date_ = date_+"/";
end
sample_rate = load(date_+"info.mat","sample_rate").sample_rate;
num_read_samples = 14e-3*sample_rate;
f = linspace(-sample_rate/2, sample_rate/2, num_read_samples);
load(date_+"res.mat");
% filter out wideband sig & have a look at res
f_bin = res(:,2);
% res = res(f_bin < 2e4 & f_bin > 0.9e4 & (f_bin > 1.261e4 | f_bin < 1.259e4) & (f_bin > 1.546e4 | f_bin < 1.536e4) & (f_bin > 9900 | f_bin < 9700) & (f_bin > 1.354e4 | f_bin < 1.352e4),:);
clear f_bin;
figure(1); 
plot(res(:,1),res(:,2),'.');
%save teh plot
saveas(gcf, date_+"doppler_track.png");
%% split different satellites
% need to specify when does a satellite appear and end, intervals can
% overlap
% 2_5-6Feb2024_00:48:59
% period_starts = [20 340 360 470 720];
% period_ends = [60 400 410 535 770];
% 2_5-5Feb2024_23:41:22
% period_starts = [640 780 865];
% period_ends = [690 850 890];
% 2_5-5Feb2024_23:58:08
% period_starts = [0 30 130 190 230 310 370 380 510 600];
% period_ends = [20 80 185 230 280 360 430 410 550 630];
% 20Feb2024_22_01
% period_starts = [30 160 400 430 680 730 780];
% period_ends = [60 200 425 490 730 760 810];
% 20Feb2024_23_19
% period_starts = [190 230 230 270 270 324 645 790];
% period_ends = [220 275 275 320 310 360 680 832];
% 6Mar2024_03_25
% period_starts = [40 145 370 425 525 570 720];
% period_ends = [70 185 400 450 560 600 760];
% 6Mar2024_03_51
% period_starts = [28 90 125 155 425 435 716 755];
% period_ends = [60 130 155 205 455 490 750 790];
% 6Mar2024_04_19 - this is the one we were using
% period_starts = [172 230 420 465 508 700 745 790];
% period_ends = [205 255 456 500 530 740 775 835];
% 6Mar2024_04_55
% period_starts = [80 80 160 495 840];
% period_ends = [110 110 210 525 870];
% 6Mar2024_05_10
% period_starts = [135 185 210 260 285 490 490 660 755];
% period_ends = [170 235 248 290 332 550 550 690 790];
% 6Mar2024_05_38
% period_starts = [68 270 305 600 600 645 760];
% period_ends = [98 295 345 635 635 680 790];
% 6Mar2024_06_08
% period_starts = [48 55 290 290 655];
% period_ends = [80 95 330 330 685];
% 6Mar2024_06_38
% period_starts = [30 360];
% period_ends = [70 420];
% 6Mar2024_07_20
% period_starts = [140 140 290 290 320 480 650];
% period_ends = [190 190 345 345 345 510 690];
% 12MarMar2024_04_35
% period_starts = [100 125];
% period_ends = [124 170];
% 12MarMar2024_06_41
% period_starts = [13 385 705 720 755];
% period_ends = [47 420 755 760 785];
% 12MarMar2024_22_05
% period_starts = [40 480 805];
% period_ends = [90 510 840];
% 12MarMar2024_23_17
% period_starts = [50 160 195 440 760 805 850 855];
% period_ends = [85 205 230 480 805 830 879 879];
% 12MarMar2024_23_35
% period_starts = [10 128 360 360 671 715 810];
% period_ends = [50 166 400 400 705 760 850];å
% 13MarMar2024_00_35
% period_starts = [350 390 390 460 680 720 730];å
% period_ends = [390 450 450 505 760 760 770];
% 13MarMar2024_00_54
% period_starts = [290 340 340 385 640 700];
% period_ends = [320 400 385 415 690 760];
% 13MarMar2024_02_20
% period_starts = [70 140 360 470 470 520 670 750];
% period_ends = [100 185 430 500 500 560 710 790];
% 13MarMar2024_03_17
% thresh = 15
% period_starts = [10 120 155 190 190 220 220 410 600 640 710 850];
% period_ends = [45 150 185 230 220 270 260 440 650 670 750 880];
% 13MarMar2024_03_59
% period_starts = [235 275 470 730];
% period_ends = [275 310 520 780];
% 13MarMar2024_05_37
% thresh = 15
% period_starts = [40 330 340 600 650 700 750];
% period_ends = [80 380 390 650 700 750 800];
% 13MarMar2024_06_14
% period_starts = [160 260 290 480 570 610];
% period_ends = [190 310 330 530 620 640];

% period_starts = [0 47 127 146 190 240 287 303 340 354 370 405 475 510 562];
% period_ends = [ 24 60 142 165 210 260 300 335 350 365 395 425 505  542 594];

% period_starts = [26 60 75 110 146 215 294 323 349 353 441 470 490 535 566 575]
% period_ends = [56 72 106 142 176 224 308 344 351 389 466 475 526 562 570 599]

% 30Jun2024_06_00_00_synthetic 
period_starts = [26 75 110 146 323 353 441 490 535 575]
period_ends = [56 106 142 176 344 389 466 526 562 599]

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
    dis_thersh = 25;
    if sat_id == 200
        dis_thersh = 4;
        display(["sat_id = 200"]);
    end
    if sat_id == 300
        display(["sat_id = 300"]);
        continue;
    end
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
            if abs(t_curr-t_last)<14e-3*15 && abs(f_bin_cur-f_bin_last)<30 % made 30 from 5 to play with synthetic data
                if_assigned = true;
                tracks{jj} = [tracks{jj} ; pnt_curr];
                break;
            end
        end
        if ~if_assigned
            tracks{length(tracks)+1} = pnt_curr;
        end
    end
    % find the longest lasting centertone track for a atellite & polyfit it
    max_l = 0; max_idx = 0;
    for jj = 1:length(tracks)
        tmp = tracks{jj};
        duration = tmp(end,1)-tmp(1,1);
        if duration > max_l
            max_l = duration;
            max_idx = jj;
        end
    end
    % Polyfit the longest centertone track
    track_main = tracks{max_idx};
    a = polyfit(track_main(:,1), track_main(:,2), 1);
    % Connect the rest of the points (that belong to other centertone tracks) to the main track by subtracking the frequency difference
    bin_freq = sample_rate/num_read_samples;
    % bin_spacing = round(44e3/bin_freq);
    bin_spacing = 43.9e3/bin_freq;
    for ii = 1:num_points
        pnt_curr = res_1sat(ii,:); t_curr = pnt_curr(1); f_bin_cur = pnt_curr(2);
        f_bin_tar = polyval(a,t_curr);
        for jj = -8:8
            dis = abs(f_bin_tar+jj*bin_spacing-f_bin_cur);
            if dis < dis_thersh
                bias = [0 round(jj*bin_spacing) 0 0 0];
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
        if min(abs(dis)) < dis_thersh
            dopp_track = [dopp_track ; res_1sat(ii,:)];
            [~,argmin] = min(abs(dis));
        end
    end
    dopp_track_dict{sat_id} = dopp_track;
    dopp_track_main_dict{sat_id} = track_main;

    if sat_id == 200
        for jj = 1:length(tracks)
            tmp = tracks{jj};
            duration_(jj) = tmp(end,1)-tmp(1,1);
        end
        [~, aaa] = maxk(duration_,3);
        dopp_track_main_dict{sat_id+1} = tracks{aaa(end)};
        del_phh = unwrap(angle(dopp_track(:,4))-angle(dopp_track(:,5)));
        bb = polyfit(dopp_track(:,1), del_phh, 1);
        del_phh_all = angle(res_1sat(:,4))-angle(res_1sat(:,5));
        del_phh_tar = polyval(bb, res_1sat(:,1));
        idx_first_sat = sum(abs(min(del_phh_all-del_phh_tar+[-2:2]*2*pi, 2)) < .9,2)==1;
        dopp_track_dict{sat_id} = res_1sat(idx_first_sat, :);
        
        dopp_track_ = tracks{aaa(end)};
        del_phh = unwrap(angle(dopp_track_(:,4))-angle(dopp_track_(:,5)));
        bb = polyfit(dopp_track_(:,1), del_phh, 1);
        del_phh_all = angle(res_1sat(~idx_first_sat,4))-angle(res_1sat(~idx_first_sat,5));
        del_phh_tar = polyval(bb, res_1sat(~idx_first_sat,1));
        idx_sec_sat = sum(abs(min(del_phh_all-del_phh_tar+[-2:2]*2*pi, 2)) < .9,2)==1;
        res_1sat_ = res_1sat(~idx_first_sat,:);
        dopp_track_dict{sat_id+1} = res_1sat_(idx_sec_sat, :);
        
    end

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
for sat_id = 1:num_periods
    dopp_track_main_dict{sat_id}(:,2) = f(dopp_track_main_dict{sat_id}(:,2));
end
%% plot doppler bin
figure(10); hold on;
% plot(res(:,1),res(:,2),'.', DisplayName="discrete", Color=[0 0 0]);
for sat_id = 1:num_periods
    dopp_track = dopp_track_dict{sat_id};
    plot(dopp_track(:,1), dopp_track(:,2), 'o', DisplayName="sat #"+num2str(sat_id),  MarkerSize=3);
end
legend(FontSize=12);xlabel('t (s)'); ylabel('f (Hz)');
saveas(gcf, date_+"doppler_bin.png");
%% plot delta_phi
figure(2);
for sat_id = 1:num_periods
    subplot(4,4,sat_id)
    dopp_track = dopp_track_dict{sat_id};
    hold on;
    plot(dopp_track(:,1), angle(dopp_track(:,3))-angle(dopp_track(:,4)), '.')
    plot(dopp_track(:,1), angle(dopp_track(:,4))-angle(dopp_track(:,5)), '.')
    title("Sat #"+num2str(sat_id))
    xlabel('t (s)');
    ylabel('phase diff (rad)')
    legend("rx0/rx1", "rx1/rx2");
    legend;
end
%% doppler-track
slope_mes = zeros(num_periods, 2);
for sat_id = 1:num_periods
    dopp_track = dopp_track_dict{sat_id};
    t_repeat = dopp_track(:,1);
    del_phi_repeat_01 = unwrap(angle(dopp_track(:,3))-angle(dopp_track(:,4)));
    del_phi_repeat_12 = unwrap(angle(dopp_track(:,4))-angle(dopp_track(:,5)));
    coeff_01 = polyfit(t_repeat, del_phi_repeat_01, 1);
    coeff_12 = polyfit(t_repeat, del_phi_repeat_12, 1);
    slope_mes(sat_id, 1) = coeff_01(1);
    slope_mes(sat_id, 2) = coeff_12(1);
end
save(date_+"doppler_track.mat", "dopp_track_main_dict", 'slope_mes');
%%
%%%%%%%%%% PART 2: ID %%%%%%%%%%%%%%%
% doppler sim & identify
% first load the doppler from date folder

load(date_+"output_doppler.mat");
% load(date_+"output_doppler_coarsegs.mat");
sat_sim_fn = fieldnames(sat_dopp_dict);
for sat_id = 1:num_periods
    dopp_main = dopp_track_main_dict{sat_id};
    % dopp_main(:,2) = f(dopp_main(:,2));
    t = unique(dopp_main(:,1));
    dopp_main_ = zeros(length(t), 3);
    for idx = 1:length(t)
        t_now = t(idx);
        ii = find(dopp_main(:,1)==t_now);
        dopp_main_(idx,1) = t_now;
        dopp_main_(idx,2) = mean(dopp_main(ii,2));
        dopp_main_(idx,3) = mean(dopp_main(ii,3)); % TODO: why take mean only of frequency an one phase? Good thing is dopp_track_main_dict is not used anymore
    end
    dopp_track_main_dict{sat_id} = dopp_main_;
end
% id
id_dict = {};
freq_offset = zeros(num_periods, 1);
for sat_id = 1:num_periods
    min_var = inf;
    dopp_main = dopp_track_main_dict{sat_id};
    dopp_main(:,1) = dopp_main(:,1); % TODO: What is this??
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
        a = polyfit(t_list(sim_idx_1:sim_idx_2), sim_dopp(sim_idx_1:sim_idx_2), 2);
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
%% NOTE: script after this is not really used here. Only necessary variables are saved and all phase processing scripts are in python
%% process delta_phi
load(date_+"info.mat","ref_sig_idx","phase_offset_01","phase_offset_21");
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
r = 1e10; lambda = 3e8/11.325e9;
d = 13.25e-2;
loc_3d = r*[cosd(el_gt).*sind(az_gt) cosd(el_gt).*cosd(az_gt) sind(el_gt)];

alpha = -1.5873754562576043; 
R_alpha = [cosd(alpha) -sind(alpha) 0;sind(alpha) cosd(alpha) 0;0 0 1];
beta = 1.4328434818441846; 
R_beta = [cosd(beta) 0 sind(beta);0 1 0;-sind(beta) 0 cosd(beta)];
gamma = 1.99; 
R_gamma = [1 0 0;0 cosd(gamma) -sind(gamma);0 sind(gamma) cosd(gamma)];
R = R_alpha*R_beta*R_gamma;

loc_1 = [0 ; 0 ; 0];
loc_0 = [0 ; -d ; 0];
loc_2 = [d ; 0 ; 0];
% loc_1 = [0 ; 0 ; 0];
% loc_2 = d_10*[cosd(alpha)*cosd(gamma) ; -sind(alpha)*cosd(gamma) ; sind(gamma)];
% loc_0 = d_12*[-sind(alpha)*cosd(beta) ; -cosd(alpha)*cosd(beta) ; -sind(beta)];
% R = eye(3);
% R = R_gamma*R_beta*R_alpha;
range_1 = vecnorm((loc_3d-(R*loc_1)')');
range_0 = vecnorm((loc_3d-(R*loc_0)')');
range_2 = vecnorm((loc_3d-(R*loc_2)')');
del_phi_01_gt = -(range_0-range_1)/lambda*2*pi;
del_phi_02_gt = -(range_0-range_2)/lambda*2*pi;
del_phi_12_gt = -(range_1-range_2)/lambda*2*pi;

[~,ref_sig_ii] = min(abs(ref_sig_idx(:,1)/sample_rate-t_sim(1)));
phase_offset_01_ = phase_offset_01(ref_sig_ii);
phase_offset_12_ = -phase_offset_21(ref_sig_ii);
del_phi_repeat_01 = del_phi_repeat_01-phase_offset_01_;
del_phi_repeat_12 = del_phi_repeat_12-phase_offset_12_;
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
param_01 = polyfit(t_repeat, del_phi_repeat_01, 1);
param_12 = polyfit(t_repeat, del_phi_repeat_12, 1);
% plot
subplot(4,4,sat_good);hold on; 
plot(t_repeat,del_phi_repeat_01, '.',DisplayName="angle(rx0/rx1) - real")
plot(t_repeat,del_phi_repeat_12, '.',DisplayName="angle(rx1/rx2) - real")
plot(t_sim, del_phi_01_gt,  LineWidth=3, Color=[0.00,0.45,0.74],DisplayName="angle(rx0/rx1) - simulated")
plot(t_sim, del_phi_12_gt,  LineWidth=3, Color=[0.85,0.33,0.10],DisplayName="angle(rx1/rx2) - simulated")
plot(t_repeat, polyval(param_01,t_repeat),'--',DisplayName='angle(rx0/rx1) - LS',LineWidth=3,Color=[1,0.45,0.74])
plot(t_repeat, polyval(param_12,t_repeat),'--',DisplayName='angle(rx1/rx2) - LS',LineWidth=3,Color=[0,0.33,0.10])
title("Sat #"+num2str(sat_good)+", gap01="+num2str(mean(polyval(param_01,t_sim)-del_phi_01_gt))+", gap12="+num2str(mean(polyval(param_12,t_sim)-del_phi_12_gt)))
% legend
% plot(t,polyval(coeff_01, t)-phase_offset_01)
% plot(t,polyval(coeff_02, t)-phase_offset_02)
saveas(gcf, date_+"phase_comp.png");
end

%%%%%%%%%% PART 3: test parts %%%%%%%%%%%%%%%
%% test
% this part has been moved to an independent script, we only save the
% necessary data
save(date_+"phase_comp.mat", "dopp_track_dict", "sat_dopp_dict", "id_dict", "freq_offset");

%% skyplot
sat_sim_fn = fieldnames(sat_dopp_dict);
figure;
for sat_good = 1:length(id_dict)
    id = id_dict{sat_good};
    sat_dopp = getfield(sat_dopp_dict, id);
    dopp_track = dopp_track_dict{sat_good};
    t = unique(dopp_track(:,1));
    t_sim = t_list(t_list>t(1)-1&t_list<t(end)+1);
    az_gt = sat_dopp(2,:)'; az_gt = az_gt(t_list>t(1)-1&t_list<t(end)+1);
    el_gt = sat_dopp(3,:)'; el_gt = el_gt(t_list>t(1)-1&t_list<t(end)+1);
    polarplot(deg2rad(90-az_gt),90-el_gt, LineWidth=2, DisplayName=id_dict{sat_good}); hold on;
    polarscatter(deg2rad(90-az_gt(1)),90-el_gt(1), DisplayName="Start point #"+num2str(sat_good))
end
legend;
thetaticks([0 90 180 270])
thetaticklabels({'East','North','West','South'})
rticks([0 5 10 15 20])
rticklabels({'90^\circ','85^\circ','80^\circ','75^\circ','70^\circ'})