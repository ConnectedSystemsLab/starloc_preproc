function [ cfo ] = estimate_cfo(rx_sym1,rx_sym2,fs)

load ../Mat_Files/Parameters.mat

cfo = -(fs/(2*pi*length(rx_sym1)))*angle(sum(conj(rx_sym2).*rx_sym1));

end