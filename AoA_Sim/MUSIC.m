% this script is for MUSIC algorithm test
% RALPH O.SCHMID, Multiple Emitter Location and Signal Parameter 
% Estimation, IEEE TRANSACTIONS ON ANTENNAS AND PROPAGATION, VOL. 
% AP-34, NO. 3, MARCH 1986
%% preparation of inputs
% clear all;
M_x = 2;            
M_y = 2;
M = M_x*M_y;        % # of antenna (assume uniform planar array)
D = 1;              % # of signal source
theta = 50;         % elevation of signal source
phi = 120;          % azimuth of signal source
f = 1;              % incident signal freq
d = 10;            % antenna spacing over wavelength ratio
                    % d = 0.5 means half wavelength spacing 
                    % d > 0.5 will cause ambiguity
SNR = 10;
K = 500;            % # of time samples
t = linspace(0, 1, K);

a_x = exp(-j*2*pi*d*[0:M_x-1]*cosd(theta)*cosd(phi)).';
a_y = exp(-j*2*pi*d*[0:M_y-1]*cosd(theta)*sind(phi)).';
A = kron(a_x, a_y);
F = exp(j*2*pi*f*t);% the waveform of F doesn't matter
X = awgn(A*F, SNR);

%% Algorithm
% Step 0: collect data, form S
S = X*X' / K;
% Step 1: calculate eigenstructure of S
[V, DiagMat] = eig(S);
% Step 2: decide number of signals D
diag_vec = diag(DiagMat);
D_hat = M - sum(diag_vec < max(diag_vec) / 5);
% Step 3: evaluate P versus theta, phi;
E_N = V(:, 1:M-D_hat);
theta_hat = [0:.5:90];
phi_hat = [0:1:360];
P = zeros(length(theta_hat), length(phi_hat));
for idx_1 = 1:length(theta_hat)
    for idx_2 = 1:length(phi_hat)
        theta_ = theta_hat(idx_1);
        phi_ = phi_hat(idx_2);
        
        a_x = exp(-1j*2*pi*d*[0:M_x-1]*cosd(theta_)*cosd(phi_)).';
        a_y = exp(-1j*2*pi*d*[0:M_y-1]*cosd(theta_)*sind(phi_)).';
        a = kron(a_x, a_y);
        P(idx_1, idx_2) = 1/(a'*(E_N*E_N')*a);
    end
end
mesh(repmat(theta_hat', [1 length(phi_hat)]), ...
    repmat(phi_hat, [length(theta_hat) 1]), db(P));
xlabel('\theta'); ylabel('\phi'); zlabel('P_{\theta, \phi} (dB)');