% calculate the doppler frequency shift from tle file
% Matlab satellite communication toolbox needed
% clear all; clc; close all;
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
mon = 9; day = 14;
TLE = "tles/"+num2str(mon)+"_"+num2str(day)+"/Starlink.tle";
% startTime = datetime("now") - hours(8);     % UTC time
startTime = datetime(2023,9,14,11,27,5) + hours(5);     % UTC time
duration = seconds(minutes(6));
stopTime = startTime + seconds(duration);
sampleTime = .5;                             % s
sc = satelliteScenario(startTime, stopTime, sampleTime);

% Satellite setting
sats = satellite(sc, TLE);
numSatellites = length(sats);
fprintf('load done, %d starlink satellites in total\n', numSatellites);

% GS setting
GSName = "U. of I.";
minElevation = 60;
% real location
lat = +40.11389690596162;
lon = -88.22484814695467;
gs = groundStation(sc, "Name", GSName, "Latitude", lat, ...
    "Longitude", lon, "MinElevationAngle", minElevation);

% res init
numHours = stopTime - startTime;
numSamples = seconds(numHours) / sampleTime;
numSamples = round(numSamples);

c = physconst("Lightspeed");
F_c = 11.575e9;

%% simulate doppler, azimuth, elevation
t = linspace(0, duration, numSamples+1);
doppler = dopplershift(gs, sats, Frequency=F_c);
[az, el, ~] = aer(gs, sats);
visible_idx = el>minElevation;
fprintf('simulation done, %d mins used\n', round(toc/60));

%% save simulation result as a struct
for idx = 1:numSatellites
    sat_struct(idx).doppler = doppler(idx, :).';
    sat_struct(idx).azimuth = az(idx, :).';
    sat_struct(idx).elevation = el(idx, :).';
    sat_struct(idx).t = t.';
    sat_struct(idx).name = sats(idx).Name;
end
%% figs

figure(1);
dopp_2 = doppler;
% avoid low elevation sats
dopp_2(~visible_idx) = nan;
% avoid quick passing sats
for idx = 1:numSatellites
    if ~isempty(find(~isnan(dopp_2(idx, :))))
        visible_duration = sum(~isnan(dopp_2(idx, :)))*sampleTime;
        % if visible_duration < 20
        %     dopp_2(idx, :) = nan;
        % end
    end
end
visible_num = sum(~isnan(dopp_2));
plot(t, visible_num);
hold on; grid on; 
plot(t, repmat(mean(visible_num), numSamples+1), '--', 'Color', [0 1 0]);
xlabel('t/min');
ylabel('visible satellite #');
title("minElevation = " + num2str(minElevation) + " degrees");
%% figs
t = linspace(0, duration, numSamples+1);
figure(2);
hold on; grid on;
for idx = 1:numSatellites
    if ~isempty(find(~isnan(dopp_2(idx, :))))
        plot(t, dopp_2(idx, :), 'DisplayName', sats(idx).Name, 'LineStyle', '--');
    end
end
legend;
%% figs
t = linspace(0, duration, numSamples+1);
figure(3);
hold on; grid on;
for idx = 1:numSatellites
    if ~isempty(find(~isnan(dopp_2(idx, :))))
        plot(t(2:end), diff(dopp_2(idx, :))/sampleTime, 'DisplayName', sats(idx).Name, 'LineStyle', '--');
    end
end
legend;

%% real curve
figure(3);
hold on; grid on;
for idx = 1:numSatellites
    if sats(idx).Name == "STARLINK-1012"
        plot(t(2:end), diff(doppler(:, idx)), 'DisplayName', sats(idx).Name);
        plot(t(2:end), diff(ans(idx,:)), 'DisplayName', sats(idx).Name);
        break;
    end
end
legend;
