% clear all; clc; close all;

%% load empirical data
load dopp_exp.mat;
dopp_exp_2 = NaN(1952, 1);
for idx = 1:1952
    win = dopp_exp((idx-1)*10+1:idx*10);
    cnt = 0; tmp = 0;
    for ii = 1:10
        if ~isnan(win(ii))
            tmp = tmp+win(ii);
            cnt = cnt+1;
        end
    end
    if cnt ~= 0
        dopp_exp_2(idx) = tmp/cnt;
    end
end
F_c = 11.575e9;
t = [0:length(dopp_exp_2)-1]'*0.1;
figure(1); plot(t, dopp_exp_2)

%% parameter search
[dopp_recover, orb_param] = orbit_estimate(t, dopp_exp_2, F_c);
hold on;
plot(t, dopp_recover);

%% compare
% System parameters
% time setting
tic;
<<<<<<< HEAD
startTime = datetime(2023,8,29,16,41+7,17+3) + hours(5);     % UTC time
duration = seconds(minutes(3));
=======
startTime = datetime(2023,8,29,16,46,57) + hours(5);     % UTC time
duration = seconds(minutes(15));
>>>>>>> refs/remotes/origin/main
stopTime = startTime + seconds(duration);
sampleTime = 1;                             % s
sc = satelliteScenario(startTime, stopTime, sampleTime);
TLE = "tles/"+num2str(8)+"_"+num2str(29)+"/Starlink.tle";
% Satellite setting
sats = satellite(sc, TLE);
numSatellites = length(sats);
fprintf('load done, %d starlink satellites in total\n', numSatellites);

% GS setting
GSName = "U. of I.";
minElevation = 25;
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
%%
% [az, el, ~] = aer(sats, gs);
[az, el, ~] = aer(gs, sats);
elevation = el';
visible_num = sum(elevation>=minElevation, 2);
visible_idx = elevation>minElevation;

[~, satV] = states(sats, "CoordinateFrame", "geographic");
dir = zeros(3, size(el, 2), size(el, 1));
dir(1, :, :) = (cosd(el).*cosd(az))';
dir(2, :, :) = (cosd(el).*sind(az))';
dir(3, :, :) = (-sind(el))';
doppler = -squeeze(dot(satV, dir, 1))*F_c/c;
doppler(~visible_idx) = nan;

% doppler = dopplershift(sats, gs, Frequency=F_c);
fprintf('simulation done, %d mins used\n', round(toc/60));

%% figs
t_ = [0:sampleTime:duration]';
figure(1);
hold on; grid on;
for idx = 1:numSatellites
    if ~isempty(find(~isnan(doppler(:, idx))))
        % if sats(idx).Name ~= 'STARLINK-6084'
        %     continue;
        % end
        sat = sats(idx);
        param = orbitalElements(sat);
        [az, el, ~] = aer(gs, sat);
        % if max(el) < 45 || max(el) > 65
        %     continue;
        % end
        % if abs(param.Inclination-53) >2
        %     continue;
        % end

        plot(t_(2:end), diff(doppler(:, idx)), 'DisplayName', sats(idx).Name, 'LineStyle', '--');
    end
end
legend;

%%
for ii = 1:1000
    tmp = plot([NaN(ii, 1) ; diff(my_mean(dopp_recover,1))], LineWidth=1, Color=[0 0 1]);
    pause(.3)
    delete(tmp);
end