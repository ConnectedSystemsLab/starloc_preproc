% clear all; clc; close all;
addpath ../Tool_Functions/
TLE = "test.tle";

startTime = datetime(2023,9,5,11,42,1) + hours(5);     % UTC time
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

% doppler = dopplershift(gs, sat, 'Frequency', F_c)';
[~,inclination,h,t_0,el_max,b] = doppler_curve_1(gs, sat, t, F_c);
% doppler_1 = dopplershift(gs, sat, Frequency=F_c);
doppler = doppler_curve_2(t,h,inclination,t_0,el_max,b,F_c);

%% parameter search
inclination_list = [53.05 53.21 70 43 97.65];
err = inf;
for i_idx = 1:5
    i_hat = inclination_list(i_idx);
    for h_hat = 530e3:1e3:540e3
        for t_0_hat = 1:300
            for theta_hat = 50:.5:70
                tmp = sum((doppler_curve_2(t,h_hat,i_hat,t_0_hat,theta_hat,0,F_c) - doppler).^2);
                if tmp < err
                    err = tmp;
                    res = [i_hat h_hat t_0_hat theta_hat];
                end
            end
        end
    end
end

%% local optimize
% h = optimvar('h');
% omega = optimvar('omega');
% % omega = 0.00105540365127697; 
% theta = optimvar('theta');
% % theta = deg2rad(63);
% t_0 = optimvar('t_0'); 
% % t_0 = 185;
% b = optimvar('b');
% % b = 0;
% fun = -1/c*r_E*(r_E+h)*sin(omega*(t-t_0))*cos(h/(r_E+h)*cot(theta))*omega...
%     ./sqrt(r_E^2+(r_E+h)^2-2*r_E*(r_E+h)*cos(omega*(t-t_0))*cos(h/(r_E+h)*cot(theta)))+b;
% obj = 1/2*sum((fun-doppler).^2);
% lsqproblem = optimproblem("Objective", obj);
% 
% x0.h = 500e3;
% x0.omega = 1e-3;
% x0.theta = deg2rad(70);
% x0.t_0 = 100;
% x0.b = 0;
% [sol,fval] = solve(lsqproblem,x0);
% 
% %% global optimize
% 
% % h = optimvar('h');
% % omega = optimvar('omega');
% omega = 0.00105540365127697; 
% % theta = optimvar('theta');
% theta = deg2rad(63);
% % t_0 = optimvar('t_0'); 
% t_0 = 185;
% % b = optimvar('b');
% b = 0;
% dopp_calc = @(h)(-1/c*r_E*(r_E+h)*sin(omega*(t-t_0))*cos(h/(r_E+h)*cot(theta))*omega...
%     ./sqrt(r_E^2+(r_E+h)^2-2*r_E*(r_E+h)*cos(omega*(t-t_0))*cos(h/(r_E+h)*cot(theta)))+b);
% fun = @(h)sum(dopp_calc(h)-doppler).^2;
% [xf,ff,flf,of] = fminunc(fun,600e3);
% % obj = 1/2*sum((fun-doppler).^2);

