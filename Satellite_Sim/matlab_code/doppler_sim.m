% calculate the doppler frequency shift from tle file
% Matlab satellite communication toolbox needed
clear all; clc;
tic;
% TLE set up
URL = "https://celestrak.org/NORAD/elements/supplemental/" + ...
    "sup-gp.php?FILE=starlink&FORMAT=tle";
TLE = 'Starlink.tle';
urlwrite(URL, TLE);

%% System parameters
% time setting
startTime = datetime('now') + hours(5);     % UTC time
duration = seconds(hours(24));
stopTime = startTime + seconds(duration);
sampleTime = 5;                             % s
sc = satelliteScenario(startTime, stopTime, sampleTime);

% Satellite setting
sats = satellite(sc, TLE);
numSatellites = length(sats);
fprintf('load done, %d starlink satellites in total\n', numSatellites);

% GS setting
GSName = "U. of I.";
minElevation = 30;
lat = +40.11389690596162;
lon = -88.22484814695467;
gs = groundStation(sc, "Name", GSName, "Latitude", lat, ...
    "Longitude", lon, "MinElevationAngle", minElevation);

% res init
numHours = stopTime - startTime;
numSamples = seconds(numHours) / sampleTime;
numSamples = round(numSamples);
% doppler = NaN(numSamples+1, numSatellites);
% elevation = zeros(numSamples+1, numSatellites);
% visible_num = zeros(numSamples+1, 1);

c = physconst("Lightspeed");
F_c = 11.325e9;

%% add a waitbar to visualize the process
% bar_1 = waitbar(0, 'doppler calculation');
% doppler = dopplershift(gs, sats, Frequency=F_c)';

% [az, el, ~] = aer(sats, gs);
[az, el, ~] = aer(gs, sats);
elevation = el';
visible_num = sum(elevation>=minElevation, 2);

[~, satV] = states(sats, "CoordinateFrame", "geographic");
dir = zeros(3, size(el, 2), size(el, 1));
dir(1, :, :) = (cosd(el).*cosd(az))';
dir(2, :, :) = (cosd(el).*sind(az))';
dir(3, :, :) = (-sind(el))';
doppler = -squeeze(dot(satV, dir, 1))*F_c/c;

fprintf('simulation done, %d mins used\n', round(toc/60));
clear sats; clear satV; clear dir;

%% figs
t = linspace(0, duration/60, numSamples+1);
plot(t, visible_num);
hold on; grid on; 
plot(t, repmat(mean(visible_num), numSamples+1), '--', 'Color', [0 1 0]);
xlabel('t/min');
ylabel('visible satellite #');
title("minElevation = " + num2str(minElevation) + " degrees");