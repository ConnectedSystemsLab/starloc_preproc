tic;
% TLE set up
today_date = datetime("today");
mon = 9; day = 14;
TLE = "tles/"+num2str(mon)+"_"+num2str(day)+"/Starlink.tle";
if ~exist("tles/"+num2str(mon)+"_"+num2str(day))
    mkdir("tles/"+num2str(mon)+"_"+num2str(day));
    URL = "https://celestrak.org/NORAD/elements/supplemental/" + ...
    "sup-gp.php?FILE=starlink&FORMAT=tle";
    urlwrite(URL, TLE);
end
startTime = datetime(2023, mon, day, 11, 27, 5) + hours(5);     % UTC time
duration = seconds(minutes(10));
stopTime = startTime + seconds(duration);
sampleTime = 1;                             % s
sc = satelliteScenario(startTime, stopTime, sampleTime);

sats = satellite(sc, TLE);
numSats = length(sats);
G = 6.6743e-11;
M = 5.9722e24;
r_E = 6378e3;

%% 
[inclination, h] = deal(zeros(numSats, 1));
for idx = 1:numSats
    sat = sats(idx);
    orbit_ele = orbitalElements(sat);
    T = orbit_ele.Period;
    inclination(idx) = orbit_ele.Inclination;
    h(idx) = (T^2/4/pi^2*G*M)^(1/3)-r_E;
end
subplot(2,1,1);plot(inclination);subplot(2,1,2);plot(h);