function test_rx_ofdm_chain()

close all
% addpath ../SRC_CODE_master
% addpath ../SRC_CODE_master/functions
addpath ../SRC_CODE
addpath ../SRC_CODE/functions
load ../Mat_Files/Test/RX_chain.mat
load ../Mat_Files/Parameters.mat

bits_data = zeros(size(signal,1),num_bins_data*num_syms_data);

for m = 1:1:size(signal,1)
    bits_data(m,:) = rx_ofdm_chain(signal(m,:));
end

save('../Results/RX_Chain_Test.mat','bits_data')