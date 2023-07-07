function test_correct_channel()

close all
% addpath ../SRC_CODE_master
% addpath ../SRC_CODE_master/functions
addpath ../SRC_CODE
addpath ../SRC_CODE/functions
load ../Mat_Files/Test/Channel_Test.mat
load ../Mat_Files/Parameters.mat

H = estimate_channel(signal(1:num_bins),signal(1+num_bins:num_bins*2));

ss=[];
sc=[];
for m=1:1:(length(signal)/num_bins)
    sym_freq = (1/sqrt(num_bins))*fft(signal(1+num_bins*(m-1):num_bins*m));
    ss = [ss;sym_freq];
    sym_freq_no_channel = correct_channel(sym_freq,H);
    sc = [sc;sym_freq_no_channel];
end

h=figure;
subplot(1,2,1);plot(ss,'.');ylabel('Imag');xlabel('Real');title('Constellation Before Channel Correction'); axis([-3 3 -3 3])
subplot(1,2,2);plot(sc,'.');ylabel('Imag');xlabel('Real');title('Constellation After Channel Correction'); axis([-2 2 -2 2])
saveas(h,'../Results/Result_Cons_Channel_Corr.fig','fig');

end