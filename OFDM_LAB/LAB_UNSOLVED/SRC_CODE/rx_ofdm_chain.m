function [ bits_data ] = rx_ofdm_chain(rx_signal)

load ../Mat_Files/Parameters.mat

bits_data = [];

% Use this variable to help you set the data subcarriers from pilot
% subcarriers from unused subcarriers
subcarrier_config = ones(1,num_bins);
subcarrier_config(convert_bin_index_normal_to_fft(gaurd_bins,num_bins)) = 0;
subcarrier_config(convert_bin_index_normal_to_fft(pilots,num_bins)) = 3; 

% Use this variable to keep track at which sample you are in packet
current_index = 1;

%% PACKET DETECTION

%  ... add your code here ... %

%% CFO ESTIMATION AND CORRECTION

%  ... add your code here ... %

%% CHANNEL ESTIMATION

%  ... add your code here ... %

%% DECODING
for m = 1:1:num_syms_data

%  ... add your code here ... %

end
    
end