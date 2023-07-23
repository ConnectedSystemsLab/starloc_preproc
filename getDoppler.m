function [f_doppler, el, t_doppler] = getDoppler(tle_file_path, fc, duration)
% calculate the doppler frequency shift from tle file
% Matlab satellite communication toolbox needed
% use Starlink 6089 as an example

% time setting
startTime = datetime(2023, 7, 22, 11, 55, 0);
startTime = startTime + hours(5);       % UTC time
startTime = startTime + days(1.8) + minutes(23);
stopTime = startTime + seconds(duration);
% sampleTime = 1e-3;  % s
sampleTime = duration / 1000;  % s
sc = satelliteScenario(startTime, stopTime, sampleTime);

% satellite setting
sat = satellite(sc, tle_file_path);
% show(sat)
% groundTrack(sat, "LeadTime",1200);  % s

% GS setting
name = "U. of I.";
lat = 40.110558;  % degrees
lon = -88.228333;  % degrees
gs = groundStation(sc, "Name", name, "Latitude", lat, "Longitude", lon);

% Access analysis
ac = access(sat, gs);
acStatus = accessStatus(ac);

% Latency & Velocity
numHours = stopTime - startTime;
numSamples = seconds(numHours)/sampleTime;
numSamples = round(numSamples);
[az, el, r] = deal(zeros(numSamples+1,1));
[satV, dir] = deal(zeros(3,numSamples+1));
[latency, dopV] = deal(NaN(numSamples+1,1));
c = physconst("Lightspeed");
for itime = 0:numSamples
  time = startTime + seconds(itime*sampleTime);
  idx = itime+1;
  % Calculate latency and doppler only when the satellite has access to the
  % ground station.
  if acStatus(idx)
    % Calculate azimuth, elevation, and range from the satellite to the
    % ground station
    [az(idx), el(idx), r(idx)] = aer(sat, gs, time);

    % Calculate latency
    latency(idx) = r(idx) / c;

    % Calculate satellite velocity in North/East/Down (NED) frame of
    % satellite. Physically, this is the ECEF velocity, represented in NED
    % frame. Therefore, the relative velocity with respect to the ground
    % station is also the same.
    [~, satV(:,idx)] = states(sat, time, "CoordinateFrame", "geographic");

    % Calculate the direction of gs with respect to sat in sat NED frame
    dir(:, idx) = [cosd(el(idx))*cosd(az(idx)); ...
      cosd(el(idx))*sind(az(idx)); ...
      -sind(el(idx))];

    % Calculate the velocity along the line between the gs and the sat.
    % This velocity determines the doppler frequency.
    dopV(idx) = dot(satV(:,idx), dir(:,idx));
  end
end
% figure(1);
% plot(1000*latency)  % ms
% title("Latency vs. Time")
% xlabel("Simulation Time (s)")
% ylabel("Latency (ms)")
% grid on
% figure(2);
% plot(dopV)
% title("Satellite Velocity Along the Line Between Sat and GS")
% xlabel("Simulation Time (s)")
% ylabel("Velocity (m/s)")
% grid on

% doppler
t_doppler = linspace(0, duration, numSamples+1)';
f_doppler = dopV*fc/c;

end

