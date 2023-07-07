function [ r_cfo , r_sfo ] = estimate_residual_cfo_sfo(rx_sym, h)

load ../Mat_Files/Parameters.mat

tx_pilots = 1 - 2*(bits_pilots);

rx_pilots = rx_sym(convert_bin_index_normal_to_fft(pilots,num_bins))./h(convert_bin_index_normal_to_fft(pilots,num_bins));

phase_accumulated = angle(rx_pilots./tx_pilots);

% figure(20)
% hold on
% plot(phase_accumulated,'Color',rand(3,1))

esti_params = regress(phase_accumulated', [ones(1,length(pilots)); pilots]');

r_cfo = esti_params(1)*fs /(2*pi*(num_bins+cp));
r_sfo = esti_params(2)*fs /(2*pi*(num_bins+cp)/num_bins);


end