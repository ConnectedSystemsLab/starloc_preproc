clear all; close all; clc
mon = 9; day = 14;
TLE = "tles/"+num2str(mon)+"_"+num2str(day)+"/Starlink.tle";
% startTime = datetime("now") - hours(8);     % UTC time
startTime = datetime(2023,9,14,11,27,5) + hours(5);     % UTC time
duration = seconds(minutes(8));
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
t = linspace(0, duration, numSamples+1);
load("el.mat"); load("doppler.mat");
visible_idx = el>minElevation;
doppler(~visible_idx) = nan;

%% time step = 0.5s, frequency resolution = 1kHz
doppler_quant = round(doppler./1e3)*1e3;

for idx = 1:numSatellites
    if ~isempty(find(~isnan(doppler_quant(idx, :))))
        if sats(idx).Name == "STARLINK-1139"
            dopp_ = doppler_quant(idx, :).';
            break;
        end
    end
end

is_nan = isnan(dopp_);
dopp_ = dopp_(~is_nan);
t_ = t(~is_nan);
% plot(t_, dopp_);
p = polyfit(t_, dopp_, 5);

hold on;
for idx = 1:numSatellites
    if ~isempty(find(~isnan(doppler_quant(idx, :))))
        if sats(idx).Name == "STARLINK-1139"
            plot(t_(2:end), diff(polyval(p, t_))/sampleTime, 'DisplayName', sats(idx).Name);
            plot(t(2:end), diff(doppler(idx, :))/sampleTime, 'DisplayName', sats(idx).Name);
            break;
        end
    end
end