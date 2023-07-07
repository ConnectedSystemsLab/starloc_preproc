function test_estimate_cfo()

close all
% addpath ../SRC_CODE_master
% addpath ../SRC_CODE_master/functions
addpath ../SRC_CODE
addpath ../SRC_CODE/functions
load ../Mat_Files/Test/Estimate_CFO_Test.mat
load ../Mat_Files/Parameters.mat

cfo_values = zeros(1,size(signal,1));

for m = 1:1:size(signal,1)
    cfo_values(m) = estimate_cfo(signal(m,1:num_bins),signal(m,1+num_bins:num_bins*2),fs);
end

save ../Results/Result_CFO_estimation.mat cfo_values