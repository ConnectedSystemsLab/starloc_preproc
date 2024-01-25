addpath ../Tool_Functions/;
%% file
% f_0 = "D:\Desktop\study\2023_autumn\box\1_8\time_17_5_25_freq_11_325G_bw_2.0M_inrx0.dat";
f_0 = "/home/ishani/LeoPNT/USRP_data/1_21/time_23_5_freq_11_325G_bw_2.0M_1705900406.6641364_inrx0.dat";
f_1 = strrep(f_0,'rx0','rx1');
f_2 = strrep(f_0,'rx0','rx2');
sample_rate = 2e6;
num_read_samples = 14e-3*sample_rate;
f = linspace(-sample_rate/2, sample_rate/2, num_read_samples);
noise_idx = 131400000;

%% track doppler
res = [];
start_idx = noise_idx+1;
thresh = 3;
if_visual = 0;
tic;
while start_idx < 690*sample_rate
    sig_0 = read_complex_binary2(f_0, num_read_samples, start_idx);
    sig_1 = read_complex_binary2(f_1, num_read_samples, start_idx);
    sig_2 = read_complex_binary2(f_2, num_read_samples, start_idx);
    start_idx = start_idx+num_read_samples;
    if start_idx < noise_idx
        continue;
    end
    sig_0_fft = fftshift(fft(sig_0));
    sig_1_fft = fftshift(fft(sig_1));
    sig_2_fft = fftshift(fft(sig_2));
    sig_0_fft_abs = abs(sig_0_fft);
    sig_1_fft_abs = abs(sig_1_fft);
    sig_2_fft_abs = abs(sig_2_fft);

    pw_avg_0 = mean(sig_0_fft_abs);
    pw_avg_1 = mean(sig_1_fft_abs);
    pw_avg_2 = mean(sig_2_fft_abs);
    % find peak indexes in frequency spectrum
    idx_0 = sig_0_fft_abs>thresh*pw_avg_0;
    idx_1 = sig_1_fft_abs>thresh*pw_avg_1;
    idx_2 = sig_2_fft_abs>thresh*pw_avg_2;
    % find common indexes for peaks in the frequency spectrum 
    idx_com = intersect(intersect(find(idx_0), find(idx_1)), find(idx_2));
    t = (start_idx-num_read_samples/2)/sample_rate;
    for ii = 1:length(idx_com)
        idx_com_ii = idx_com(ii);
        res = [res ; [t idx_com_ii sig_0_fft(idx_com_ii) sig_1_fft(idx_com_ii) sig_2_fft(idx_com_ii)]];
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
fprintf('Elapsed time: %f seconds\n', elapsed_time);save('res.mat','res');
quit (0,"force");
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
xlabel('t / s'); ylabel('f_d / Hz'); title('Tracked central tones');
%% plot delta_phi
figure(2);
for sat_id = 1:num_periods
    subplot(3,3,sat_id)
    dopp_track = dopp_track_dict{sat_id};
    hold on;
    plot(dopp_track(:,1), angle(dopp_track(:,3))-angle(dopp_track(:,4)), '.')
    plot(dopp_track(:,1), angle(dopp_track(:,3))-angle(dopp_track(:,5)), '.')
    title("Sat #"+num2str(sat_id))
    % ylim([-pi pi]);
    % clf;
end
%% ID
% id_dict{}
%% process delta_phi
sat_good = 7;
dopp_track = dopp_track_dict{sat_good};
t_repeat = dopp_track(:,1);
del_phi_repeat_01 = unwrap(angle(dopp_track(:,3))-angle(dopp_track(:,4)));
del_phi_repeat_02 = unwrap(angle(dopp_track(:,3))-angle(dopp_track(:,5)));
coeff_01 = polyfit(t_repeat, del_phi_repeat_01, 2);
coeff_02 = polyfit(t_repeat, del_phi_repeat_02, 2);
t = unique(t_repeat);
del_phi_01 = zeros(length(t),1);
del_phi_02 = zeros(length(t),1);
for idx = 1:length(t)
    t_now = t(idx);
    ii = find(t_repeat==t_now);
    del_phi_01(idx) = sum(abs(dopp_track(ii,3:4)).^2,2)'*del_phi_repeat_01(ii) / sum(abs(dopp_track(ii,3:4)).^2,'all'); % weighed mean
    del_phi_02(idx) = sum(abs(dopp_track(ii,[3 5])).^2,2)'*del_phi_repeat_02(ii) / sum(abs(dopp_track(ii,[3 5])).^2,'all');
end
% compare with gt
load ../../box/1_10/output_doppler.mat
sat_sim_fn = fieldnames(sat_dopp_dict);
name = id_dict{sat_good};
if sat_good == 7
    name = "STARLINK-30966";
elseif sat_good == 1
    name = "STARLINK-6365";
elseif sat_good == 4
    name = "STARLINK-5784";
elseif sat_good == 9
    name = "STARLINK-5598";
end
sat_dopp = getfield(sat_dopp_dict, name);
dopp_track = dopp_track_dict{sat_good};
t = unique(dopp_track(:,1));
t_sim = t_list(t_list>t(1)&t_list<t(end));
az_gt = sat_dopp(2,:)'; az_gt = az_gt(t_list>t(1)&t_list<t(end));
el_gt = sat_dopp(3,:)'; el_gt = el_gt(t_list>t(1)&t_list<t(end));
r = 1e10;
d = 13.25e-2;
% az_gt = az_gt-1;
phi = 360-az_gt; theta = el_gt;
lambda = 3e8/11.325e9;
loc_3d = r*[cosd(theta).*cosd(phi) cosd(theta).*sind(phi) sind(theta)];
range_0 = vecnorm((loc_3d-[0 0 0])');
range_1 = vecnorm((loc_3d-[d 0 0])');
range_2 = vecnorm((loc_3d-[0 -d 0])');
del_phi_01_gt = -(range_0-range_1)/lambda*2*pi;
del_phi_02_gt = -(range_0-range_2)/lambda*2*pi;

phase_offset_01 = -2.6259220015834757;
phase_offset_02 = -3.0204142063436374;
% plot
figure;hold on
plot(t_repeat,del_phi_repeat_01-phase_offset_01-2*pi, '.')
plot(t_repeat,del_phi_repeat_02-phase_offset_02, '.')
plot(t_sim, del_phi_01_gt,  LineWidth=3)
plot(t_sim, del_phi_02_gt,  LineWidth=3)
title('Sat # 4')
legend("angle(rx0/rx1) - real","angle(rx0/rx2) - real","angle(rx0/rx1) - simulated","angle(rx0/rx2) - simulated")
legend
% plot(t,polyval(coeff_01, t)-phase_offset_01)
% plot(t,polyval(coeff_02, t)-phase_offset_02)

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
% sat_good_7 should be "STARLINK-30966";
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