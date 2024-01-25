addpath ../starlink_ofdm/Tool_Functions/;
% [CHANGE THIS] might need to change this to add the path correctly
f_0 = "/home/ishani/LeoPNT/USRP_data/1_21/time_19_30_freq_11_325G_bw_2.0M_inrx0.dat";
% [CHANGE THIS] change to the path of rx0
f_1 = strrep(f_0,'rx0','rx1');
f_2 = strrep(f_0,'rx0','rx2');

%% calc phase diff
% f ~ 350k-450k
% [CHANGE THIS] 301200000 is the idx when ref sig ends
sample_rate = 2e6;
start_idx = 1*sample_rate;%82e7;%54e7;%30e7;
end_idx = (1+120)*sample_rate;%85e7;%64e7;%;40e7;
curr_idx = start_idx;
num_read_samples = 2e6*0.01638;
phi = [];
f = linspace(-1e6,1e6,num_read_samples);
while curr_idx < end_idx
    iq0 = read_complex_binary2(f_0, num_read_samples, curr_idx);
    iq1 = read_complex_binary2(f_1, num_read_samples, curr_idx);
    iq2 = read_complex_binary2(f_2, num_read_samples, curr_idx);
    iq0_fft = fftshift(fft(iq0));
    iq1_fft = fftshift(fft(iq1));
    iq2_fft = fftshift(fft(iq2));
    iq0_fft(abs(f-190.5e3)>10e3) = 0; % helps in selecting the peak we want to look at 
    iq1_fft(abs(f-190.5e3)>10e3) = 0;
    iq2_fft(abs(f-190.5e3)>10e3) = 0;
    [~, max_idx] = max(abs(iq2_fft));
    % hold on;
    % plot(f, db(iq0_fft));
    % plot(f, db(iq1_fft));
    % plot(f, db(iq2_fft));
    % scatter(f(max_idx),db(iq1_fft(max_idx)));
    % pause(0.1);
    % clf;
    % max_idx = 19470;
    curr_idx = curr_idx+num_read_samples;
    phi = [phi ; angle([iq0_fft(max_idx) iq1_fft(max_idx) iq2_fft(max_idx)])];
end
%% plot fig
% in phi, the i-th column is the phase of rx-i
% [CHANGE THIS] 
% 1.1875615183255415
% 2.7512329670903863
% 1.563671432796857
phase_offset_01 = 0;
phase_offset_02 = 0;
phase_offset_12 = 0;
% phase_offset_12 = -phase_offset_01+phase_offset_02;
del_phi_01 = unwrap(phi(:,1)-phi(:,2))-phase_offset_01;
del_phi_02 = unwrap(phi(:,1)-phi(:,3))-phase_offset_02;
del_phi_12 = unwrap(phi(:,2)-phi(:,3))-phase_offset_12;

hold on
plot(del_phi_01, DisplayName="angle(rx0/rx1)");
plot(del_phi_02, DisplayName="angle(rx0/rx2)");
plot(del_phi_12, DisplayName="angle(rx1/rx2)");
legend
%% expeted phase
l1 = 7.62;
l2 = 0.6;
d = 0.042;
lam = 3e8/11.3252e9;

ex = (((l2*d)/sqrt(l1^2+l2^2))/lam)*2*pi