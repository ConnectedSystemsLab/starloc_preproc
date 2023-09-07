% clear all; clc; close all;
addpath ../Tool_Functions/
TLE = "test.tle";

startTime = datetime(2023,9,6,15,38,1) + hours(5);     % UTC time
UTCTime = [startTime.Year startTime.Month startTime.Day startTime.Hour startTime.Minute startTime.Second];
duration = seconds(minutes(5));
stopTime = startTime + seconds(duration);
sampleTime = .1;                             % s
sc = satelliteScenario(startTime, stopTime, sampleTime);
t = [0:sampleTime:duration]';

% Satellite setting
sat = satellite(sc, TLE);

% GS setting
GSName = "U. of I.";
minElevation = 0;
% real location
lat = +40.11389690596162;
lon = -88.22484814695467;
gs = groundStation(sc, "Name", GSName, "Latitude", lat, ...
    "Longitude", lon, "MinElevationAngle", minElevation);
F_c = 11.575e9;

% curve & orbit param from built in funcs 
[~,inclination,h,t_0,el_max,b] = doppler_curve_1(gs, sat, t, F_c);
% doppler_1 = dopplershift(gs, sat, Frequency=F_c);

%% add noise
doppler = doppler_curve_2(t,h,inclination,t_0,el_max,b,F_c);
for idx = 1:length(doppler)
    if rand(1)<.5
        doppler(idx) = NaN;
    end
end
doppler = doppler+1e3*randn(size(doppler));
figure(1); plot(t, doppler, LineWidth=1);

%% parameter search
dopp_recover = orbit_estimate(t, doppler, F_c);
hold on;
plot(t, dopp_recover);
