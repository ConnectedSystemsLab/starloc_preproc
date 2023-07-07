function test_packet_detection()

close all
% addpath ../SRC_CODE_master
% addpath ../SRC_CODE_master/functions
addpath ../SRC_CODE
addpath ../SRC_CODE/functions
load ../Mat_Files/Test/Packet_Detection.mat
load ../Mat_Files/Parameters.mat

[num_sigs, len_sigs] = size(signal);

packets_start_index_test = zeros(1,num_sigs);

for m=1:1:num_sigs
    packets_start_index_test(m) = packet_detection(signal(m,1:len_sigs));
end

save('../Results/Packet_Detection_Test.mat','packets_start_index_test')

