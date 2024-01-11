addpath ../Tool_Functions/;
%% file
% f_0 = "D:\Desktop\study\2023_autumn\box\1_8\time_17_5_25_freq_11_325G_bw_2.0M_inrx0.dat";
% f_1 = strrep(f_0,'rx0','rx1');
% f_2 = strrep(f_0,'rx0','rx2');
sample_rate = 2e6;
num_read_samples = 14e-3*sample_rate;
f = linspace(-sample_rate/2, sample_rate/2, num_read_samples);
t_start = 0;
load ../../box/1_10/res.mat
%% filter out wideband sig & have a look at res
f_bin = res(:,2);
res = res(f_bin < 2e4 & f_bin > 0.9e4,:);
clear f_bin;
plot(res(:,1),res(:,2),'.');
%% track doppler
res = [];
start_idx = (120)*sample_rate;
thresh = 3;
if_visual = 0;
while start_idx < (120+40)*sample_rate
    sig_0 = read_complex_binary2(f_0, num_read_samples, start_idx);
    sig_1 = read_complex_binary2(f_1, num_read_samples, start_idx);
    start_idx = start_idx+num_read_samples;
    sig_0_fft = fftshift(fft(sig_0));
    sig_1_fft = fftshift(fft(sig_1));
    sig_0_fft_abs = abs(sig_0_fft);
    sig_1_fft_abs = abs(sig_1_fft);
    pw_avg_0 = mean(sig_0_fft_abs);
    pw_avg_1 = mean(sig_1_fft_abs);
    idx_0 = sig_0_fft_abs>thresh*pw_avg_0;
    idx_1 = sig_1_fft_abs>thresh*pw_avg_1;
    idx_com = intersect(find(idx_0), find(idx_1));
    t = start_idx/sample_rate;
    for ii = 1:length(idx_com)
        idx_com_ii = idx_com(ii);
        res = [res ; [t idx_com_ii sig_0_fft(idx_com_ii) sig_1_fft(idx_com_ii)]];
    end
    if if_visual
        subplot(2,1,1); hold on; title(num2str(t));
        plot(f,sig_0_fft_abs); scatter(f(idx_com),sig_0_fft_abs(idx_com)); xlim([-600e3 600e3]); ylim([0 10*pw_avg_0]);
        subplot(2,1,2); hold on;
        plot(f,sig_1_fft_abs); scatter(f(idx_com),sig_1_fft_abs(idx_com)); xlim([-600e3 600e3]); ylim([0 10*pw_avg_1]);
        pause(.01);
        clf;
    end
end
%% split different satellites
period_starts = [90 130 170 210 255 310 540 780 910];
period_ends = [120 150 210 255 310 333 620 830 960];
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
%% track & connect
dopp_track_dict = {};
dopp_track_main_dict = {};
for sat_id = 1:num_periods
res = res_{sat_id};
num_points = size(res, 1);
tracks = {};
for ii = 1:num_points
    pnt_curr = res(ii,:); t_curr = pnt_curr(1); f_bin_cur = pnt_curr(2);
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
dopp_track = [];
dopp_track_agg = [];
bin_freq = sample_rate/num_read_samples;
bin_spacing = round(44e3/bin_freq);
for ii = 1:num_points
    pnt_curr = res(ii,:); t_curr = pnt_curr(1); f_bin_cur = pnt_curr(2);
    f_bin_tar = polyval(a,t_curr)+[-8:8]*bin_spacing;
    dis = f_bin_cur-f_bin_tar;
    if min(abs(dis)) < 5
        dopp_track = [dopp_track ; res(ii,:)];
        [~,argmin] = min(abs(dis));
    end
end
dopp_track_dict{sat_id} = dopp_track;
dopp_track_main_dict{sat_id} = track_main;
% res(:,2) = f(res(:,2));
% dopp_track(:,2) = f(dopp_track(:,2));
end
%% plot doppler bin
figure(1); hold on;
for sat_id = 1:num_periods
    dopp_track = dopp_track_dict{sat_id};
    plot(dopp_track(:,1), dopp_track(:,2), '.');
end
%% plot delta_phi
figure(2);
for sat_id = 1:num_periods
    dopp_track = dopp_track_dict{sat_id};
    hold on;
    plot(dopp_track(:,1), angle(dopp_track(:,3))-angle(dopp_track(:,4)), '.')
    plot(dopp_track(:,1), angle(dopp_track(:,3))-angle(dopp_track(:,5)), '.')
    % ylim([-pi pi]);
    clf;
end
%% process delta_phi
t_repeat = dopp_track(:,1);
del_phi_repeat = unwrap(angle(dopp_track(:,3))-angle(dopp_track(:,4)));
t = unique(t_repeat);
del_phi = zeros(length(t),1);
for idx = 1:length(t)
    t_now = t(idx);
    ii = find(t_repeat==t_now);
    % del_phi(idx) = mean(del_phi_repeat(ii));
    del_phi(idx) = sum(abs(dopp_track(ii,3:4)),2)'*del_phi_repeat(ii) / sum(abs(dopp_track(ii,3:4)),'all'); % weighed mean
    angle(dopp_track(ii,3))
    angle(dopp_track(ii,4))
end
%% doppler sim & identify
load ../../box/1_10/output_doppler.mat
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
%% id
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
%% plot id
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
% legend
figure; hold on;
for sat_id = 1:num_periods
    dopp_track = dopp_track_dict{sat_id};
    plot(dopp_track(:,1), dopp_track(:,2), '.', DisplayName=id_dict{sat_id});
end