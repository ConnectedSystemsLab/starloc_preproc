% calculate the doppler frequency shift from tle file
% Matlab satellite communication toolbox needed
clear all; clc; close all;
tic;
% TLE set up
today_date = datetime("today");
mon = today_date.Month; day = today_date.Day;
TLE = "tles/"+num2str(mon)+"_"+num2str(day)+"/Starlink.tle";
if ~exist("tles/"+num2str(mon)+"_"+num2str(day))
    mkdir("tles/"+num2str(mon)+"_"+num2str(day));
    URL = "https://celestrak.org/NORAD/elements/supplemental/" + ...
    "sup-gp.php?FILE=starlink&FORMAT=tle";
    urlwrite(URL, TLE);
end

%% System parameters
% time setting
% startTime = datetime('now') + hours(5);     % UTC time
startTime = datetime(2023,8,29,13,27,1) + hours(5);     % UTC time
duration = seconds(minutes(2));
stopTime = startTime + seconds(duration);
sampleTime = 1;                             % s
sc = satelliteScenario(startTime, stopTime, sampleTime);

% Satellite setting
sats = satellite(sc, TLE);
numSatellites = length(sats);
fprintf('load done, %d starlink satellites in total\n', numSatellites);

sat = sats(sats.Name=="STARLINK-6101");

% GS setting
GSName = "U. of I.";
minElevation = 45;
% real location
lat_1 = +40.11389690596162;
lon_1 = -88.22484814695467;
gs_1 = groundStation(sc, "Name", GSName, "Latitude", lat_1, ...
    "Longitude", lon_1, "MinElevationAngle", minElevation);
% assumed location
lat_2 = +40.61389690596162;
lon_2 = -88.72484814695467;
gs_2 = groundStation(sc, "Name", GSName, "Latitude", lat_2, ...
    "Longitude", lon_2, "MinElevationAngle", minElevation);

% res init
numHours = stopTime - startTime;
numSamples = seconds(numHours) / sampleTime;
numSamples = round(numSamples);
% doppler = NaN(numSamples+1, numSatellites);
% elevation = zeros(numSamples+1, numSatellites);
% visible_num = zeros(numSamples+1, 1);

c = physconst("Lightspeed");
F_c = 11.575e9;

%% add a waitbar to visualize the process
% bar_1 = waitbar(0, 'doppler calculation');
% doppler = dopplershift(gs, sats, Frequency=F_c)';

% [az, el, ~] = aer(sats, gs);
[az, el, ~] = aer(gs_1, sats);
elevation = el';
visible_num = sum(elevation>=minElevation, 2);
visible_idx = elevation>minElevation & az' > 300;

[~, satV] = states(sats, "CoordinateFrame", "geographic");
dir = zeros(3, size(el, 2), size(el, 1));
dir(1, :, :) = (cosd(el).*cosd(az))';
dir(2, :, :) = (cosd(el).*sind(az))';
dir(3, :, :) = (-sind(el))';
doppler = -squeeze(dot(satV, dir, 1))*F_c/c;
doppler(~visible_idx) = nan;

fprintf('simulation done, %d mins used\n', round(toc/60));

%% figs
close all;
t = linspace(0, duration/60, numSamples+1);
figure(1);
plot(t, visible_num);
hold on; grid on; 
% plot(t, repmat(mean(visible_num), numSamples+1), '--', 'Color', [0 1 0]);
xlabel('t/min');
ylabel('visible satellite #');
title("minElevation = " + num2str(minElevation) + " degrees");
figure(5);
hold on; grid on;
for idx = 1:numSatellites
    if ~isempty(find(~isnan(doppler(:, idx))))
        plot(t, doppler(:, idx), 'DisplayName', sats(idx).Name, 'LineStyle', '--');
    end
end
legend;
figure(3);
hold on; grid on;
for idx = 1:numSatellites
    % if ~isempty(find(~isnan(doppler(:, idx))))
    if sats(idx).Name == "STARLINK-6101"
        plot(t(1:end-1), diff(doppler(:, idx)), 'DisplayName', sats(idx).Name);
    end
end
legend;
figure(4);
hold on; grid on;
for idx = 1:numSatellites
    if ~isempty(find(~isnan(doppler(:, idx))))
        plot(t, sqrt(sum(satV(:,:,idx).^2,1)), 'DisplayName', sats(idx).Name);
    end
end
legend;

%% real curve
% [az, el, ~] = aer(gs_2, sat);
% elevation = el';
% visible_num = sum(elevation>=minElevation, 2);
% visible_idx = elevation>minElevation;
% 
% [~, satV] = states(sat, "CoordinateFrame", "geographic");
% dir = zeros(3, size(el, 2), size(el, 1));
% dir(1, :, :) = (cosd(el).*cosd(az))';
% dir(2, :, :) = (cosd(el).*sind(az))';
% dir(3, :, :) = (-sind(el))';
% doppler = -squeeze(dot(satV, dir, 1))*F_c/c;
% doppler(~visible_idx) = nan;
% % figure(5);
% % plot(t, doppler, 'DisplayName', sat.Name);
