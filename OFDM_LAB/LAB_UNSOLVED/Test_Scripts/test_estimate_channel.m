function test_estimate_channel()

close all
% addpath ../SRC_CODE_master
% addpath ../SRC_CODE_master/functions
addpath ../SRC_CODE
addpath ../SRC_CODE/functions
load ../Mat_Files/Test/Channel_Test.mat
load ../Mat_Files/Parameters.mat

H = estimate_channel(signal(1:num_bins),signal(1+num_bins:num_bins*2));

save ../Results/Result_Channel_Estimation.mat H

H(convert_bin_index_normal_to_fft(gaurd_bins,num_bins)) = 0;
ht = ifft(H);
H(convert_bin_index_normal_to_fft(gaurd_bins,num_bins)) = nan;

h=figure;
subplot(2,1,1);stairs(convert_bin_index_fft_to_normal([1:num_bins],num_bins),abs(H));ylabel('|H|');xlabel('Subcarrier Index');title('Channel in the Frequency Domain');axis([-36 36 min(abs(H))*0.9 max(abs(H))*1.1]);
subplot(2,1,2);stem([0:num_bins/2-1]*1e6/fs,abs(ht(1:num_bins/2)),'.');ylabel('|h|');xlabel('Time (microseconds)');title('Channel Taps in the Time Domain'); axis([-1e6/fs (num_bins/2)*1e6/fs 0 abs(ht(1))*1.1]);
saveas(h,'../Results/Result_Channel.fig','fig');

end