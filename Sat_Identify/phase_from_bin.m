addpath ../Tool_Functions/;
%% file
f_0 = "/home/ishani/LeoPNT/USRP_data/12_27/time_20_47_freq_11_325G_bw_2.0M_1703724657.2378652_inrx0.dat";
f_1 = strrep(f_0,'rx0','rx1');
f_2 = strrep(f_0,'rx0','rx2');
%% 
% load("../Starloc/1_8/output_tracks.mat")
% look at the first lnb
% tracks_dict = tracks_dict{1};
track = tracks_dict.track_6;
sample_rate = 2e6;
noise_idx = 0;
noise_t = noise_idx/sample_rate;
t_list = track(:,1);
freq_bin_list = track(:,2);
central_bw = 1.024e6;
del_phi = zeros(2,length(t_list));
for idx = 1:length(t_list)
    t = t_list(idx);
    freq_bin = freq_bin_list(idx);
    start_idx = t*sample_rate+noise_idx;
    sig_0 = read_complex_binary2(f_0, sample_rate, start_idx);
    sig_0 = resample(sig_0, central_bw, sample_rate);
    sig_1 = read_complex_binary2(f_1, sample_rate, start_idx);
    sig_1 = resample(sig_1, central_bw, sample_rate);
    sig_2 = read_complex_binary2(f_2, sample_rate, start_idx);
    sig_2 = resample(sig_2, central_bw, sample_rate);
    subplot(3,1,1);
    plot(db(fft_avg(sig_0,sample_rate,1024,0)));
    xlim([1 1024]); ylim([10 25]);xline(freq_bin);
    subplot(3,1,2);
    plot(db(fft_avg(sig_1,sample_rate,1024,0)));
    xlim([1 1024]); ylim([10 25]);xline(freq_bin);
    subplot(3,1,3);
    plot(db(fft_avg(sig_2,sample_rate,1024,0)));
    xlim([1 1024]); ylim([30 45]);xline(freq_bin);
    title(num2str((t+idx)))
    pause(0.2);
    
    ph_0 = fft_phase_avg(sig_0, sample_rate, 1024, freq_bin);
    ph_1 = fft_phase_avg(sig_1, sample_rate, 1024, freq_bin);
    ph_2 = fft_phase_avg(sig_2, sample_rate, 1024, freq_bin);
    del_phi(:, idx) = [ph_0-ph_1;ph_0-ph_2];
end

function [phi, f] = fft_phase_avg(sig, bw, n_fft, freq_bin)
% calculates the average spectrum power
% length(sig) = multiple of n_fft

l = length(sig);
if mod(l, n_fft) ~= 0
    % error('length of signal should be multiple of fft points');
    sig = sig(1:end-mod(l, n_fft));
    l = length(sig);
end

f = linspace(-bw/2, bw/2, n_fft);
f_bin = f(2)-f(1);
signal_reshape = reshape(sig, [n_fft l/n_fft]);
signal_reshape_fft = fftshift(fft(signal_reshape, n_fft, 1), 1);
ph = angle(signal_reshape_fft);
phi = phase_avg(ph(freq_bin,:));
% sig_fft = sum(abs(signal_reshape_fft).^2, 2);
% sig_fft(abs(f-f_hardware)<2*f_bin) = mean(sig_fft(abs(f-f_hardware)<2*f_bin));

end