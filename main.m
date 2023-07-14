clear all; clc;


%% parameters

% independent params
F_s = 240e6;            % channel bandwidth; information symbol rate (Hz)
N = 1024;               % # of subcarriers          
N_g = 32;               % # of guard interval
T_f = 1/750;            % frame period (s)
T_fg = 68/15*1e-6;      % frame guard interval (s)
N_sf = 302;             % # of non-zero symbols in a frame
N_sfd = 298;            % # of data (non-synchronization) symbols in a frame
F_ci = (10.7+F_s/N/2/1e9+0.25*([1:8]'-0.5))*1e9;
                        % center frequency of ith channel

% derived params
T = N/F_s;              % useful (non-cyclic) OFDM symbol interval
T_g = N_g/F_s;          % symbol guard interval
T_sym = T+T_g;          % OFDM symbol duration including guard interval
F = F_s/N;              % subcarrier spacing
F_delta = F_ci(2)-F_ci(1);
F_g = F_delta - F_s;    % width of guard band between channels

% other params
% Operating in baseband for simulations. Setting F_c = 0.
F_c = 0; %F_ci(7);
N_f = 20;               % # of generated frames
N_sym = T_sym*F_s;      % # of samples per symbol including guard interval

%% baseband transmit signal

x = zeros((N_sf+1)*N_sym*N_f, 1);   % time domain signal
% frequency domain
for frame = 1:N_f
    % frame structure
    % frequency domain symbols (dim-1: symbol; dim-2: subcarrier)
    X = zeros(N_sf, N); 

    % X(1,:) = PSS
    % "PSS was found to lack any discernible constellation structure when
    % viewed in the frequency domain"

    % X(2,:) = SSS
    % "SSS was found to be a standard OFDM symbol, with 4QAM modulation"
    X(2,:) = getSSS(N);

    % X(301,:) = CM1SS
    % "CM1SS is found to contain some information symbols that are constant from
    % frame to frame."
    X(301,:) = qammod(randi([0 3], 1, N), 4)/sqrt(2);

    % X(302,:) = CSS
    % "the CSS's constellation clusters form a box aligned with the horizontal
    % and vertical axes"
    X(302,:) = qammod(randi([0 3], 1, N), 4)/sqrt(2);

    % X(3:301,:) = data symbols
    X(3:300,:) = pskmod(randi([0 3], N_sfd, N), 4);
    % gutter
    X(:, [1 2 N-1 N]) = 0;

% time domain
x_slice = zeros((N_sf+1)*N_sym, 1);
for idx = 1:302
    if idx == 1
        x_slice(1:N_sym) = getPSS(N_g, N, N_sym);
        continue;
    else
        tmp = zeros(T_sym*F_s, 1);
        tmp(N_g+1:end) = sqrt(N)*ifft(X(idx, :).');
        tmp(1:N_g) = tmp(end-N_g+1:end);
        x_slice((idx-1)*N_sym+1:idx*N_sym) = tmp;
    end
end
    x((frame-1)*(N_sf+1)*N_sym+1:frame*(N_sf+1)*N_sym) = x_slice;
end
t = [1:(N_sf+1)*N_sym*N_f]'/F_s;
x_real = abs(x);
figure(1);
plot(t, x_real)
%% TX
% TODO

% frames appended by zeros and using carrier/center frequency (F_c) as 0 for
% simulations
x_transmit = [zeros(100000,1); x_real.*cos(2*pi*F_c*t+angle(x)) ; zeros(100000,1)];
%% channel
% TODO 
SNR = 10;
y = x_transmit / 5;     % attenuation
y = awgn(y, SNR);

%% RX
% TODO

% Receiver in the paper samples 62.5MHz of bandwidth => 240e6/62.5e6 ~ 4
y_receive = downsample(y, 4); 
%% test
% this will generate a figure similar to fig 3.
frame = 1;
y_slice = y((frame-1)*(N_sf+1)*N_sym+1:frame*(N_sf+1)*N_sym);

corr = xcorr(y_slice, y_slice) / length(y_slice);
figure(2);
plot(mag2dB(abs(corr)), LineWidth=1);

corr_frames = xcorr(y_receive, y_receive) / length(y_receive);
figure(3);
plot(mag2dB(abs(corr_frames)), LineWidth=1);

