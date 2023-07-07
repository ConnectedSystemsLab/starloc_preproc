function [ rx_sym_no_channel ] = correct_channel(rx_sym,H)

load ../Mat_Files/Parameters.mat

rx_sym_no_channel = rx_sym./H;

rx_sym_no_channel(convert_bin_index_normal_to_fft(gaurd_bins,num_bins)) = 0;

end