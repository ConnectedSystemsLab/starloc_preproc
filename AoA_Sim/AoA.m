% this script is used for simulating how phase difference between a LNB 
% array will vary. Make sure that the path is set as
% 'starlinf_ofdm/AoA_Sim' when running this script. 

%% download TLE from celestrack
today_date = datetime("today");
% mon = today_date.Month; day = today_date.Day;
mon = 11; day = 5;
TLE = "tles/"+num2str(mon)+"_"+num2str(day)+"/Starlink.tle";
if ~exist("tles/"+num2str(mon)+"_"+num2str(day))
    mkdir("tles/"+num2str(mon)+"_"+num2str(day));
    URL = "https://celestrak.org/NORAD/elements/supplemental/" + ...
    "sup-gp.php?FILE=starlink&FORMAT=tle";
    urlwrite(URL, TLE);
end

%% Satellite & LNB setup

% time setting
startTime = datetime(2023, 11, 5, 0, 0, 0) + hours(5);     % UTC time
duration = seconds(minutes(1));
stopTime = startTime + seconds(duration);
sampleTime = 1;                             % in second
sc = satelliteScenario(startTime, stopTime, sampleTime);

% Satellite setting
% sats = satellite(sc, TLE);
% numSatellites = length(sats);
% fprintf('load done, %d starlink satellites in total\n', numSatellites);

% LNB setting
minElevation = 60;                % minimum elevation of visible sats
c = physconst("Lightspeed");      % speed of light
F_c = 11.575e9;                   % carrier frequency
lambda = c / F_c;                 % wavelength
d = lambda / 2;                   % antenna spacing

% LNB locations
% assume we have 4 synchronized LNBs, placed in the 
% following way:
% ------------         N
% |LNB2 LNB4 |       W + E
% |LNB1 LNB3 |         S
% ------------

R_E = 6378e3;                   % earth radius (meter)
lat(1) = +40.11389690596162;    % latitude of LNB1
lon(1) = -88.22484814695467;    % longtitude of LNB1
lat(2) = lat(1)+rad2deg(d/R_E); % latitude of LNB2
lon(2) = lon(1);                % longtitude of LNB2
lat(3) = lat(1);                % latitude of LNB3
lon(3) = lon(1)+rad2deg(d/R_E)/cosd(lat(1));
                                % longtitude of LNB3
lat(4) = lat(3)+rad2deg(d/R_E); % latitude of LNB4
lon(4) = lon(3);                % longtitude of LNB4

LNBs = groundStation(sc, "Name", 'uiuc', "Latitude", lat, ...
    "Longitude", lon, "MinElevationAngle", minElevation);

%% compute the distance between satellites to 4 LNBs
% Ran this and found that 4291-th satellite passes overhead. Uncomment it
% to find out which satellite passes overhead

num_LNBs = 4; 
num_sats = length(sats); 
num_time_samples = duration/sampleTime+1;
[elevation, range] = deal(zeros(num_sats, num_time_samples, num_LNBs));
for ii = 1:num_LNBs
    [~, elevation(:,:,ii), range(:,:,ii)] = aer(LNBs(ii), sats);
end

tmp = elevation>minElevation;
visible_idx = tmp(:,:,1)&tmp(:,:,2)&tmp(:,:,3)&tmp(:,:,4);
for idx = 1:num_sats
    if sum(visible_idx(idx, :)) == length(visible_idx(idx,:))
        sats(idx).Name
        break;
    end
end

% compute the phase difference
% sat = sats(4291);
% num_LNBs = 4; num_time_samples = duration/sampleTime+1;
% [azimuth, elevation, range] = deal(zeros(num_time_samples, num_LNBs));
% for ii = 1:num_LNBs
%     [azimuth(:,ii), elevation(:,ii), range(:,ii)] = aer(LNBs(ii), sat);
% end
% phase_diff = (range-range(:,1))/lambda*2*pi;
% 
% tt = [0:num_time_samples-1]*sampleTime;
% hold on;
% for ii = 1:num_LNBs
%     plot(tt, phase_diff(:,ii));
% end
% xlabel('time (s)'); ylabel('relative phase to LNB-1 (rad)');
% title('phase result for satellite ' + sat.Name);

%% try to estimate the AoA (both azimuth & elevation) using MUSIC
% assume that the satellite is transmitting at F_c+f=11.575 GHz+0.2MHz, 
% i.e., y(t) = exp(j*2*pi*(f+F_c)*t),
% where F_c is the carrier frequency and f is the narrowband tone.
% assume when it arrives at the LNB1 at UIUC, it becomes 
% y_1(t) = A*exp(j*2*pi*(f+F_c)*t)+n_i, 
% where A is path loss,
% n_1 is the noise at LNB-1.
% similarly, for LNB-i (i=2,3,4), there will be time delays since the
% distance between LNB-i will be different from LNB-1, given by
% y_i(t) = A*exp(j*2*pi*(f+F_c)*(t-(r_i-r_1)/c))+n_i,
% = A*exp(-j*2*pi*(f+F_c)*(r_i-r_1)/c)*exp(j*2*pi*(f+F_c)*t)+n_i,
% = A'*exp(j*2*pi*(f+F_c)*t)+n_i.
% where r_i is the distance between the sat and the i-th LNB. If r_i>r_1
% than it arrives later.
% also assume that A is same for different LNBs since they r very
% close to each other
% y_i is in anaglog domain, then LNB & USRP down-converts it at sample it. 
% In the most ideal case where we have synchronized LNBs and USRPs, the
% digital signal we get is removing F_c and substituting continuous time t 
% with discrete time samples n*T_s = n/F_s, i.e.,
% y_i[n] = A'*exp(j*2*pi*f*n*F_s)+n_i,
% from where we start our simulation
%% do the simulation again with higher sample rate
num_LNBs = 4;
F_s = 1e3;
sc_new = satelliteScenario(startTime, stopTime, 1/F_s);
sat = satellite(sc_new, 'tles/11_5/STARLINK-5718.tle');
LNBs = groundStation(sc_new, "Name", 'uiuc', "Latitude", lat, ...
"Longitude", lon, "MinElevationAngle", minElevation);
[azimuth, elevation, range] = deal(zeros(duration*F_s+1, num_LNBs));
for ii = 1:num_LNBs
    [azimuth(:,ii), elevation(:,ii), range(:,ii)] = aer(LNBs(ii), sat);
end

%% compute phase difference
f = 0.2e3;
A = 1;
n = [0:duration*F_s];
y_1 = A*exp(j*2*pi*f*n/F_s);
y_2 = A*exp(-j*2*pi*(f+F_c)*(range(:,2)-range(:,1))'/c).*exp(j*2*pi*f*n/F_s);
y_3 = A*exp(-j*2*pi*(f+F_c)*(range(:,3)-range(:,1))'/c).*exp(j*2*pi*f*n/F_s);
y_4 = A*exp(-j*2*pi*(f+F_c)*(range(:,4)-range(:,1))'/c).*exp(j*2*pi*f*n/F_s);
SNR = 50;
y_1 = awgn(y_1, SNR);
y_2 = awgn(y_2, SNR);
y_3 = awgn(y_3, SNR);
y_4 = awgn(y_4, SNR);

hold on;
plot(angle(y_1.*conj(y_2)));
plot(angle(y_1.*conj(y_3)));
plot(angle(y_1.*conj(y_4)));
xlabel('sample #'); ylabel('relative phase to LNB-1 (rad)');
legend('angle(y_1/y_2)', 'angle(y_1/y_3)', 'angle(y_1/y_4)')
title('phase difference result for STARLINK-6150');

%% use the azimuth to recover location
az = azimuth(:, 1); az = az(end-1750:end);
az = az';
pos_sat = states(sat);  pos_sat = pos_sat(:, end-1750:end);
pos_sat = pos_sat';
% M = zeros(600, 5);
% for ii = 1:600
%     r_i = pos_sat(:, ii);
%     az_i = az(ii);
%     A_i = [-cosd(az_i) 0 0 -sind(az_i) 0; ...
%         0 -cosd(az_i) sind(az_i) 0 0; ...
%         0 0 0 0 cosd(az_i)];
%     M(ii, :) = r_i'*A_i;
% end
% [U, S, V] = svd(M);

F = @(x) norm(sum(pos_sat.*([-cosd(az)*cos(x(1))*cos(x(2))-sind(az)*sin(x(1));
                    -cosd(az)*sin(x(1))*cos(x(2))+sind(az)*cos(x(1));
                    cosd(az)*sin(x(2))].'), 2));
x0 = [1;1];
% options = optimoptions('fsolve','Display','iter');
% [x,fval] = fsolve(F,x0,options);
x = fminsearch(F, x0);
x = rad2deg(x);
%% solver test
F = @(x) [2*x(1) - x(2) - exp(-x(1));
         -x(1) + 2*x(2) - exp(-x(2))];
x0 = [-5;-5];
options = optimoptions('fsolve','Display','iter');
fminsearch
[x,fval] = fsolve(F,x0,options)

%% ECEF coordinate test
pos_sat = states(sat, CoordinateFrame="ecef");
wgs84 = wgs84Ellipsoid("meter");
[a, e, s] = deal(zeros(60001, 1));
for i = 1:60001
    [a(i), e(i), s(i)] = ecef2aer(pos_sat(1,i), pos_sat(2,i), pos_sat(3,i), lat(1), lon(1), 0, wgs84);
end
[a_, e_, s_] = deal(zeros(60001, 1));
% [x_b, y_b, z_b] = geodetic2ecef(lat(1), lon(1), 0);
for i = 1:60001
    % [a_(i), e_(i), s_(i)] = cart2sph(pos_sat(1,i)-x_b, pos_sat(2,i)-y_b, pos_sat(3,i)-z_b);
    [xx, yy, zz] = ecef2enu(pos_sat(1,i), pos_sat(2,i), pos_sat(3,i), lat(1), lon(1), 0, wgs84);
    [a_(i), e_(i), s_(i)] = cart2sph(xx, yy, zz);
end