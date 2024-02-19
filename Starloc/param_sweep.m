% this script is for parameter sweeping, sweeping paramters:
% - antenna spacing d_10
% - antenna spacing d_12
% - angle alpha
% - angle beta
% - angle gamma

% load necessary data
date_ = "5Feb2024_23-58-08/";
load(date_+"phase_comp.mat");
load(date_+"output_doppler.mat");
load(date_+"info.mat","ref_sig_idx","phase_offset_01","phase_offset_21","sample_rate");
num_periods = length(dopp_track_dict);    % # of satellites

% first get real measured phase diff, fit it with polynomial and compute 
% the coefficients
for sat_good = 1:num_periods
    dopp_track = dopp_track_dict{sat_good};
    t_repeat = dopp_track(:,1);
    t = unique(dopp_track(:,1));
    t_sim = t_list(t_list>t(1)-1&t_list<t(end)+1);
    del_phi_repeat_01 = unwrap(angle(dopp_track(:,3))-angle(dopp_track(:,4)));
    del_phi_repeat_02 = unwrap(angle(dopp_track(:,3))-angle(dopp_track(:,5)));
    del_phi_repeat_12 = unwrap(angle(dopp_track(:,4))-angle(dopp_track(:,5)));
    
    % compensate the phase offset using ref signal
    [~,ref_sig_ii] = min(abs(ref_sig_idx(:,1)/sample_rate-t_sim(1)));
    phase_offset_01_ = phase_offset_01(ref_sig_ii);
    phase_offset_12_ = -phase_offset_21(ref_sig_ii);
    del_phi_repeat_01 = del_phi_repeat_01-phase_offset_01_;
    del_phi_repeat_12 = del_phi_repeat_12-phase_offset_12_;

    % fit it with a linear function
    param_01_dict{sat_good} = polyfit(t_repeat, del_phi_repeat_01, 2);
    param_12_dict{sat_good} = polyfit(t_repeat, del_phi_repeat_12, 2);
end

% then get ground truth elevation and azimuth
for sat_good = 1:num_periods
    dopp_track = dopp_track_dict{sat_good};
    sat_sim_fn = fieldnames(sat_dopp_dict);
    name = id_dict{sat_good};
    sat_dopp = getfield(sat_dopp_dict, name);
    t = unique(dopp_track(:,1));
    az_gt = sat_dopp(2,:)'; 
    az_gt_dict{sat_good} = az_gt(t_list>t(1)-1&t_list<t(end)+1);
    el_gt = sat_dopp(3,:)'; 
    el_gt_dict{sat_good} = el_gt(t_list>t(1)-1&t_list<t(end)+1);
end

% finally start the parameter sweeping
alpha_list = [-3:0.4:3]; l_1 = length(alpha_list);
beta_list = [-3:0.4:3]; l_2 = length(beta_list);
gamma_list = [-3:0.4:3]; l_3 = length(gamma_list);
d_10_list = linspace(13.25e-2-0.6e-2,13.25e-2+0.6e-2,15);
d_12_list = linspace(13.25e-2-0.6e-2,13.25e-2+0.6e-2,15);
l_4 = length(d_10_list);
l_5 = length(d_12_list);

slope_err = zeros(l_1,l_2,l_3,l_4,l_5,num_periods,2);
bias_err = zeros(l_1,l_2,l_3,l_4,l_5,num_periods,2);
compute_cnt = 0;
for i_1 = 1:l_1
for i_2 = 1:l_2
for i_3 = 1:l_3
for i_4 = 1:l_4
for i_5 = 1:l_5
compute_cnt = compute_cnt+1;
% print computation percentage
compute_cnt*100/l_1/l_2/l_3/l_4/l_5
% tmp = zeros(num_periods,1);
slope_err_1_config = zeros(num_periods,2);
bias_err_1_config = zeros(num_periods,2);
for sat_good = 1:num_periods

% location of sat
dopp_track = dopp_track_dict{sat_good};
t = unique(dopp_track(:,1));
t_sim = t_list(t_list>t(1)-1&t_list<t(end)+1);
az_gt = az_gt_dict{sat_good};
el_gt = el_gt_dict{sat_good};
r = 1e8; lambda = 3e8/11.325e9;
loc_3d = r*[cosd(el_gt).*sind(az_gt) cosd(el_gt).*cosd(az_gt) sind(el_gt)];

% location of array
alpha = alpha_list(i_1);
beta = beta_list(i_2);
gamma = gamma_list(i_3);
d_10 = d_10_list(i_4);
d_12 = d_12_list(i_5);
% loc_1 = [0 ; 0 ; 0];
% loc_0 = [0 ; -d ; 0];
% loc_2 = [d ; 0 ; 0];
loc_1 = [0 ; 0 ; 0];
loc_2 = d_10*[cosd(alpha)*cosd(gamma) ; -sind(alpha)*cosd(gamma) ; sind(gamma)];
loc_0 = d_12*[-sind(alpha)*cosd(beta) ; -cosd(alpha)*cosd(beta) ; -sind(beta)];

% R_alpha = [cosd(alpha_err) -sind(alpha_err) 0;sind(alpha_err) cosd(alpha_err) 0;0 0 1];
% R_beta = [cosd(beta_err) 0 sind(beta_err);0 1 0;-sind(beta_err) 0 cosd(beta_err)];
% R_gamma = [1 0 0;0 cosd(gamma_err) -sind(gamma_err);0 sind(gamma_err) cosd(gamma_err)];
% R = R_alpha*R_beta*R_gamma;
range_1 = vecnorm((loc_3d-(loc_1)')');
range_0 = vecnorm((loc_3d-(loc_0)')');
range_2 = vecnorm((loc_3d-(loc_2)')');
del_phi_01_gt = -(range_0-range_1)/lambda*2*pi;
del_phi_12_gt = -(range_1-range_2)/lambda*2*pi;
param_01_gt = polyfit(t_sim, del_phi_01_gt, 2);
param_12_gt = polyfit(t_sim, del_phi_12_gt, 2);
% candidates_01 = polyval(param_01, t_sim)+[-2:2]'*2*pi;
% candidates_12 = polyval(param_12, t_sim)+[-2:2]'*2*pi;
% dis_01 = mean(candidates_01-del_phi_01_gt,2);
% dis_12 = mean(candidates_12-del_phi_12_gt,2);
% [min_err_01, min_idx] = min(abs(dis_01));
% del_phi_repeat_01 = del_phi_repeat_01+2*pi*(min_idx-3);
% [min_err_12, min_idx] = min(abs(dis_12));
% del_phi_repeat_12 = del_phi_repeat_12+2*pi*(min_idx-3);
% param_01 = polyfit(t_repeat, del_phi_repeat_01, 1);
% param_12 = polyfit(t_repeat, del_phi_repeat_12, 1);
param_01 = param_01_dict{sat_good};
param_12 = param_12_dict{sat_good};
% tmp(sat_good*2-1) = min_err_01;
% tmp(sat_good*2) = min_err_12;
slope_err_1_config(sat_good,1) = abs(param_01(1)-param_01_gt(1));
slope_err_1_config(sat_good,2) = abs(param_12(1)-param_12_gt(1));
bias_err_1_config(sat_good,1) = mean(abs(del_phi_01_gt-polyval(param_01, t_sim)));
bias_err_1_config(sat_good,2) = mean(mod(abs(del_phi_12_gt-polyval(param_12, t_sim)),2*pi));
end
% bias_err = [bias_err ; tmp];
% slope_err = [slope_err ; slope_err_1_config];
slope_err(i_1,i_2,i_3,i_4,i_5,:,:) = slope_err_1_config;
bias_err_1_config(:,1) = 0;
bias_err(i_1,i_2,i_3,i_4,i_5,:,:) = bias_err_1_config;

end
end
end
end
end
save(date_+"sweep_param_res.mat", "slope_err");
sum_slope_err = sum(slope_err,[6 7]);
sum_bias_err = sum(bias_err,[6 7]);
%% 
m_slope = inf;
res_slope = [];
m_bias = inf;
res_bias = [];
for i_1 = 1:l_1
for i_2 = 1:l_2
for i_3 = 1:l_3
for i_4 = 1:l_4
for i_5 = 1:l_5
    if sum_slope_err(i_1,i_2,i_3,i_4,i_5) < m_slope
        m_slope = sum_slope_err(i_1,i_2,i_3,i_4,i_5);
        res_slope = [i_1,i_2,i_3,i_4,i_5];
    end
    if sum_bias_err(i_1,i_2,i_3,i_4,i_5) < m_bias
        m_bias = sum_bias_err(i_1,i_2,i_3,i_4,i_5);
        res_bias = [i_1,i_2,i_3,i_4,i_5];
    end
end
end
end
end
end

m_slope
alpha_list(res_slope(1))
beta_list(res_slope(2))
gamma_list(res_slope(3))
d_10_list(res_slope(4))
d_12_list(res_slope(5))

m_bias
alpha_list(res_bias(1))
beta_list(res_bias(2))
gamma_list(res_bias(3))
d_10_list(res_bias(4))
d_12_list(res_bias(5))
% %%
% hold on;
% plot(bias_err(:,2))
% plot(bias_err(:,4))
% plot(bias_err(:,6))
% plot(bias_err(:,8))
% %%
% figure;hold on;
% plot(slope_err(:,1))
% plot(slope_err(:,3))
% plot(slope_err(:,5))
% plot(slope_err(:,7))
% title("slope err rx0-rx1")
% figure;hold on;
% plot(slope_err(:,2))
% plot(slope_err(:,4))
% plot(slope_err(:,6))
% plot(slope_err(:,8))
% title("slope err rx1-rx2")
