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
F_c = 11.575e9;
% time setting
% startTime = datetime('now') + hours(5);     % UTC time
startTime = datetime(2023,8,28,16,39,1) + hours(5);     % UTC time
duration = seconds(minutes(1));
stopTime = startTime + seconds(duration);
sampleTime = 1;                             % s
sc = satelliteScenario(startTime, stopTime, sampleTime);

% Satellite setting
sats = satellite(sc, TLE);
numSatellites = length(sats);
fprintf('load done, %d starlink satellites in total\n', numSatellites);

% GS setting
GSName_1 = "Tian an men";
GSName_2 = "Tsinghua";
radias = 100e3;         % distance uncertainty = 100 km
orbit_height = 550e3;   % LEO orbit height = 550 km
minElevation = 70;
elevation_1 = atand(orbit_height/(radias+orbit_height/tand(minElevation)));
% center location
lat_1 = 39.9055;
lon_1 = 116.3976;
gs_1 = groundStation(sc, "Name", GSName_1, "Latitude", lat_1, ...
    "Longitude", lon_1, "MinElevationAngle", elevation_1);
% real location
lat_2 = 40.20383;
lon_2 = 116.52632;
gs_2 = groundStation(sc, "Name", GSName_2, "Latitude", lat_2, ...
    "Longitude", lon_2, "MinElevationAngle", minElevation);

distance(lat_1,lon_1,lat_2,lon_2,wgs84Ellipsoid)

%% calculate doppler

[doppler_1, t] = doppler_calculation(sats, gs_1, F_c, duration, sampleTime);
[doppler_2, ~] = doppler_calculation(sats, gs_2, F_c, duration, sampleTime);

%% 
close all; figure(1); hold on; grid on;
for idx = 1:numSatellites
    if ~isempty(find(~isnan(doppler_1(:, idx)))) && ~isempty(find(~isnan(doppler_2(:, idx))))
        co = rand(1, 3);
        plot(t, doppler_1(:, idx), 'DisplayName', "1-"+sats(idx).Name, 'LineStyle', '--', 'LineWidth', 1, 'Color', co);
        plot(t, doppler_2(:, idx), 'DisplayName', "2-"+sats(idx).Name, 'LineWidth', 1, 'Color', co);
    elseif ~isempty(find(~isnan(doppler_2(:, idx))))
        plot(t, doppler_2(:, idx), 'DisplayName', "2-"+sats(idx).Name);
    elseif ~isempty(find(~isnan(doppler_1(:, idx))))
        plot(t, doppler_1(:, idx), 'DisplayName', "1-"+sats(idx).Name, 'LineStyle', '--');
    end
end
legend;
