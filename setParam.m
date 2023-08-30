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
F_c = F_ci(7);          % F_ci(7);
% F_c = 0;          % F_ci(7);
N_f = 3e2;              % # of generated frames
N_sym = T_sym*F_s;      % # of samples per symbol including guard interval
duty_ratio = .5;         % probability that a frame contains signal