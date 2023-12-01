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