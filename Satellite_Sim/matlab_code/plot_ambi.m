load ambiguity_sim.mat;
num_ambi = size(az, 1);

%% AoA Estimation
hold on;
plot(t_list, az_gt, LineWidth=1)
for i = 1:num_ambi
    plot(t_list, rad2deg(az(i,:)), '--');
end

%% Localization
hold on;
plot(lat_1, lon_1, Marker="o", DisplayName='GT');
for i = 1:num_ambi
    scatter(lat_est(i,:), lon_est(i,:), Marker='.', DisplayName='estimate');
end
legend

%% AoA error plot
% hold on;
% plot(t_list, el);
subplot(2,1,1);
% hold on;
yyaxis left;
plot(t_list, elevation-el);
yyaxis right;
plot(t_list, elevation);
subplot(2,1,2);
plot(t_list, azimuth-az);

%% AoA debug
load aoa.mat;
c = 299792458.0;
fc = 11.575e9;
lam = c/fc;
d = lam/2;
phi_mat = atan2(-del_phi_2, -del_phi_1);
phi_mat = mod(phi_mat, 2*pi);
az_mat = 2*pi - phi_mat;
el_mat = acos(-del_phi_1*lam/(2*pi*d*cos(az_mat)));
az_mat = rad2deg(az_mat); el_mat = rad2deg(el_mat);