function test_decode_rx_packets()

close all
% addpath ../SRC_CODE_master
% addpath ../SRC_CODE_master/functions
addpath ../SRC_CODE
addpath ../SRC_CODE/functions
load ../Mat_Files/Test/RX_chain.mat
load ../Mat_Files/Parameters.mat


bits_data = zeros(10,num_bins_data*num_syms_data);

for j = 1:10
    disp(['Decoding Packet Number: ', num2str(j)])
	samples=read_complex_binary2(['../Mat_Files/RX_Data/location_',num2str(j),'.dat']);
	bits_data(j,:) = rx_ofdm_chain(samples);
end

save('../Results/Decode_RX_Pkts.mat','bits_data')