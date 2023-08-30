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
startTime = datetime('now') + hours(5);     % UTC time
duration = seconds(minutes(10));
stopTime = startTime + seconds(duration);
sampleTime = 2;                             % s
sc = satelliteScenario(startTime, stopTime, sampleTime);

% Satellite setting
sats = satellite(sc, TLE);
numSatellites = length(sats);
fprintf('load done, %d starlink satellites in total\n', numSatellites);

% GS setting
minElevation = 60;
c = physconst("Lightspeed");
F_c = 11.575e9;     % carrier frequency
lambda = c/F_c;     % wavelength
d = lambda/2;       % antenna spacing
% location 1
lat(1) = +40.11389690596162;
lon(1) = -88.22484814695467;
lat(2) = lat(1);
lon(2) = lon(1)+rad2deg(d/6378e3)/cosd(lat(1));
% to do so is to ensure distance(lat_1, lat_2)=d;
% location 2
lat(3) = +40.61389690596162;
lon(3) = -88.72484814695467;
lat(4) = lat(3);
lon(4) = lon(3)+rad2deg(d/6378e3)/cosd(lat(1));
gs = groundStation(sc, "Name", '1', "Latitude", lat, ...
    "Longitude", lon, "MinElevationAngle", minElevation);

% res init
numHours = stopTime - startTime;
numSamples = seconds(numHours) / sampleTime;
numSamples = round(numSamples);

%% AoA simulation

[~, el_1, r_1] = aer(gs(1), sats);
[~, el_2, r_2] = aer(gs(2), sats);
% visible_num = sum(elevation>=minElevation, 2);
visible_idx = el_1>minElevation & el_2>minElevation;

AoA_1 = r_1-r_2;
% AoA_1 = acosd(AoA_1/d);
AoA_1 = AoA_1 / lambda * 2*pi;
AoA_1(~visible_idx) = nan;

fprintf('simulation done, %d mins used\n', round(toc/60));

%% figs
close all;
t = linspace(0, duration/60, numSamples+1);
figure(1);
hold on; grid on;
for idx = 1:numSatellites
    if ~isempty(find(~isnan(AoA_1(idx, :))))
        plot(t, AoA_1(idx, :), 'DisplayName', sats(idx).Name, 'LineWidth', 1);
    end
end
legend;
xlabel('t (min)');
ylabel('\Delta \phi (rad)');
