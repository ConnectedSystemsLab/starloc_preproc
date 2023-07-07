function [ rx_signal_no_cfo ] = correct_cfo(rx_signal,cfo,fs)

load ../Mat_Files/Parameters.mat

rx_signal_no_cfo =rx_signal.*exp((-1i*2*pi*cfo/fs).*[0:length(rx_signal)-1]);

end