% calculate the doppler frequency shift from tle file
% Matlab satellite communication toolbox needed

tic;

% time setting
startTime = datetime('now');
startTime = startTime + hours(5);       % UTC time
duration = seconds(days(1));
stopTime = startTime + seconds(duration);
sampleTime = 5;                         % s
sc = satelliteScenario(startTime, stopTime, sampleTime);

% satellite setting
tleFilePath = 'Starlink.tle';
tleInfo = readlines(tleFilePath);
% fprintf('loading tle files...\n');
% sats = satellite(sc, tleFilePath);

% numSatellites = length(sats);
numSatellites = length(tleInfo)/3;
% fprintf('load done, %d starlink satellites in total\n', numSatellites);

% GS setting
GSName = "U. of I.";
minElevation = 30;
lat = 40.110558;
lon = -88.228333;
gs = groundStation(sc, "Name", GSName, "Latitude", lat, ...
    "Longitude", lon, "MinElevationAngle", minElevation);

% Access analysis
% ac = access(gs, sats);
% acStatus = accessStatus(ac);    % bool valued

% Latency & Velocity
numHours = stopTime - startTime;
numSamples = seconds(numHours) / sampleTime;
numSamples = round(numSamples);
% [az, el, r] = deal(zeros(numSamples+1, numSatellites));
% [satV, dir] = deal(zeros(3, numSamples+1, numSatellites));
% [latency, dopV] = deal(NaN(numSamples+1, numSatellites));
doppler = NaN(numSamples+1, numSatellites);
visible_num = zeros(numSamples+1, 1);
c = physconst("Lightspeed");
F_c = 12.325e9;

%% add a waitbar to visualize the process
bar_1 = waitbar(0, 'doppler calculation');
for isat = 1:numSatellites
    % f = fopen("tmp.tle", "w");
    % fprintf(f, '%s\n', tleInfo((isat-1)*3+1, :));
    % fprintf(f, '%s\n', tleInfo((isat-1)*3+2, :));
    % fprintf(f, '%s', tleInfo((isat-1)*3+3, :));
    % fclose(f);
    sat = satellite(sc, "tles/"+num2str(isat)+'.tle');
    
    dopp_result = dopplershift(gs, sat, Frequency=F_c)';
    doppler(:, isat) = dopp_result;
    visible_num = visible_num + ~isnan(dopp_result);
    waitBarMessage = ['Computing', num2str(100*isat/numSatellites), '%'];
    waitbar(isat/numSatellites, bar_1, waitBarMessage);
end

toc;
