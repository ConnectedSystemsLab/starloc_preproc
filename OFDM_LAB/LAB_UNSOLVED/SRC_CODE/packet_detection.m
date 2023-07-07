function [ packet_start_index ] = packet_detection(rx_signal)

load ../Mat_Files/Parameters.mat 

% Dc removal filter
alpha = 0.975; 
rx_signal = filter([1 -1], [1 -alpha], rx_signal);

threshold=6;

%  ... add your code here ... %

end