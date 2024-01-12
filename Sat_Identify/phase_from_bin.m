addpath ../Tool_Functions/;
%% file
% f_0 = "D:\Desktop\study\2023_autumn\box\1_8\time_17_5_25_freq_11_325G_bw_2.0M_inrx0.dat";
f_0 = "/home/ishani/LeoPNT/USRP_data/1_10/time_20_44_freq_11_325G_bw_2.0M_1704943526.988162_inrx0.dat";
f_1 = strrep(f_0,'rx0','rx1');
f_2 = strrep(f_0,'rx0','rx2');
sample_rate = 2e6;
%% track doppler
res = [];
num_read_samples = 14e-3*sample_rate;
f = linspace(-sample_rate/2, sample_rate/2, num_read_samples);
noise_idx = 58200000;
start_idx = (0)*sample_rate+noise_idx;

thresh = 2.5;
if_visual = 0;
while start_idx < (0+1050)*sample_rate+noise_idx
    sig_0 = read_complex_binary2(f_0, num_read_samples, start_idx);
    sig_1 = read_complex_binary2(f_1, num_read_samples, start_idx);
    sig_2 = read_complex_binary2(f_2, num_read_samples, start_idx);
    start_idx = start_idx+num_read_samples;

    sig_0_fft = fftshift(fft(sig_0));
    sig_1_fft = fftshift(fft(sig_1));
    sig_2_fft = fftshift(fft(sig_2));
    sig_0_fft_abs = abs(sig_0_fft);
    sig_1_fft_abs = abs(sig_1_fft);
    sig_2_fft_abs = abs(sig_2_fft);

    pw_avg_0 = mean(sig_0_fft_abs);
    pw_avg_1 = mean(sig_1_fft_abs);
    pw_avg_2 = mean(sig_2_fft_abs);
    idx_0 = sig_0_fft_abs>thresh*pw_avg_0;
    idx_1 = sig_1_fft_abs>thresh*pw_avg_1;
    idx_2 = sig_2_fft_abs>thresh*pw_avg_2;
    idx_com = intersect(intersect(find(idx_0), find(idx_1)), find(idx_2));
    t = (start_idx-num_read_samples/2-noise_idx)/sample_rate
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
save('res.mat','res');
quit (0,"force");
%% track & connect
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
    if size(tmp,1) > max_l
        max_l = size(tmp,1);
        max_idx = jj;
    end
end
%% pick up others
track_main = tracks{max_idx};
a = polyfit(track_main(:,1), track_main(:,2), 3);
dopp_track = [];
bin_freq = sample_rate/num_read_samples;
bin_spacing = round(44e3/bin_freq);
for ii = 1:num_points
    pnt_curr = res(ii,:); t_curr = pnt_curr(1); f_bin_cur = pnt_curr(2);
    f_bin_tar = polyval(a,t_curr)+[-8:8]*bin_spacing;
    dis = f_bin_cur-f_bin_tar;
    if min(abs(dis)) < 5
        dopp_track = [dopp_track ; res(ii,:)];
    end
end
res(:,2) = f(res(:,2));
dopp_track(:,2) = f(dopp_track(:,2));
%% plot doppler bin
figure(1);
plot(dopp_track(:,1), dopp_track(:,2), '.');
%% plot delta_phi
figure(2);
plot(dopp_track(:,1), angle(dopp_track(:,3))-angle(dopp_track(:,4)), '.')
ylim([-pi pi]);
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
%% doppler sim
fn = fieldnames(sat_dopp_dict);
figure;hold on;
for idx = 1:length(fn)
    name = fn{idx};
    sim_data = getfield(sat_dopp_dict, name);
    plot(t_list, sim_data(2,:), '--', DisplayName=name);
end
legend
