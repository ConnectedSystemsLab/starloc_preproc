function [ signal ] = tx_ofdm_chain(bits_data)

load ../Mat_Files/Parameters.mat
addpath functions

signal = zeros(1,num_samples);

% Use this variable to create each symbol in the frequency domain before
% taking the fft
symbol_freq = zeros(1,num_bins);

% Use this variable to help you set the data subcarriers from pilot
% subcarriers from unused subcarriers
subcarrier_config = ones(1,num_bins);
subcarrier_config(convert_bin_index_normal_to_fft(gaurd_bins,num_bins)) = 0;
subcarrier_config(convert_bin_index_normal_to_fft(pilots,num_bins)) = 3; 


%% ADD PREAMBLE SYMBOLS
for m = 1:1:num_syms_preamble
    
    % The bits are mapped as 1-2*bits since bit 0 is modulated to 1 and bit
    % 1 is modulated to -1
    
    symbol_freq(subcarrier_config~=0) = 1-2*fftshift(bits_preamble);
    symbol_time = sqrt(num_bins)*ifft(symbol_freq);
    signal(1+(m-1)*num_bins:m*num_bins) = symbol_time;
end
    signal(1+num_syms_preamble*num_bins:num_syms_preamble*num_bins+cp) =symbol_time(1:cp);

%% ADD DATA SYMBOLS
for m = 1:1:num_syms_data
    symbol_freq(subcarrier_config==1) = 1-2*fftshift(bits_data(1+(m-1)*num_bins_data:m*num_bins_data));
    symbol_freq(subcarrier_config==3) = 1-2*fftshift(bits_pilots);
    symbol_time = sqrt(num_bins)*ifft(symbol_freq);
    signal(1+num_syms_preamble*num_bins+cp+(m-1)*(num_bins+cp):m*(num_bins+cp)+num_syms_preamble*num_bins+cp) = [symbol_time, symbol_time(1:cp)];
end
 
end