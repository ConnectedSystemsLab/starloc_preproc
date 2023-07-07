function [ h_new ] = correct_residual_cfo_sfo(h_prev, r_cfo , r_sfo)
% 
%

load ../Mat_Files/Parameters.mat

phase_cfo = 2*pi*(num_bins+cp)*r_cfo/fs;
phase_sfo = 2*pi*(num_bins+cp)*r_sfo/(num_bins*fs);

phase_correction = phase_cfo.*ones(1,num_bins) + phase_sfo.*convert_bin_index_fft_to_normal([1:1:num_bins],num_bins);

h_new = h_prev.*exp(1i*(phase_correction));

end