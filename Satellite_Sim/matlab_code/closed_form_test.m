% clear all; clc; close all;
TLE = "test.tle";

startTime = datetime(2023,9,5,11,38,1) + hours(5);     % UTC time
UTCTime = [startTime.Year startTime.Month startTime.Day startTime.Hour startTime.Minute startTime.Second];
duration = seconds(minutes(12));
stopTime = startTime + seconds(duration);
sampleTime = 1;                             % s
sc = satelliteScenario(startTime, stopTime, sampleTime);

% Satellite setting
sat = satellite(sc, TLE);

% GS setting
GSName = "U. of I.";
minElevation = 0;
% real location
lat = +40.11389690596162;
lon = -88.22484814695467;
alt = 215;
gs = groundStation(sc, "Name", GSName, "Latitude", lat, ...
    "Longitude", lon, "MinElevationAngle", minElevation);

c = physconst("Lightspeed");
F_c = 11.575e9;
r_E = 6378e3;
omega_E = 7.2921150e-5;

%% 
t = [0:sampleTime:duration]'; numSamp = length(t);
sat_coordinate = states(sat);
% gs_coordinate = lla2eci([lat lon 0], UTCTime)';
% r_vec = sat_coordinate - repmat(gs_coordinate, [1 numSamp]);
r_ = sqrt(sum(sat_coordinate.^2, 1));
h = mean(r_-r_E);
r = mean(r_);
[az, el, ~] = aer(gs, sat);
[el_max, t_0] = max(el);
doppler_1 = dopplershift(gs, sat, 'Frequency', F_c);

orbit_ele = orbitalElements(sat);
inclination = orbit_ele.Inclination;

subsat_unit_vec = sat_coordinate./r_;
unit_vec_1 = subsat_unit_vec(:, 1);
psi = zeros(numSamp, 1);
for idx = 1:numSamp
    psi(idx) = real(acos(dot(unit_vec_1, subsat_unit_vec(:, idx))));
    % psi(idx) = psi(idx)-(idx-1)*omega_E*cosd(inclination)*sampleTime/2;
end
psi = psi-psi(t_0);

omega_s = mean(diff(psi))/sampleTime;
omega_F = omega_s-omega_E*cosd(inclination);
psi = omega_F*(t-t(t_0));

%% 
doppler_2 = r_E*r*sin(psi)*cos(acos(r_E/r*cosd(el_max))-deg2rad(el_max))*omega_F;
doppler_2 = doppler_2 ./ sqrt(r_E^2+r^2-2*r_E*r*cos(psi)*cos(acos(r_E/r*cosd(el_max))-deg2rad(el_max)));
doppler_2 = -F_c/c*doppler_2;

%%
doppler_3 = r_E*r*sin(psi)*cos(h/r*cotd(el_max))*omega_F;
doppler_3 = doppler_3 ./ sqrt(r_E^2+r^2-2*r_E*r*cos(psi)*cos(h/r*cotd(el_max)));
doppler_3 = -F_c/c*doppler_3;

%%
plot(t, doppler_1, '--'); hold on; plot(t, doppler_3);