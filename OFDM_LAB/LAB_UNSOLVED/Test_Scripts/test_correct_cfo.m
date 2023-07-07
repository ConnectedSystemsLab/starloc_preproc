function test_correct_cfo()

close all
% addpath ../SRC_CODE_master
% addpath ../SRC_CODE_master/functions
addpath ../SRC_CODE
addpath ../SRC_CODE/functions
load ../Mat_Files/Test/Correct_CFO_Test.mat
load ../Mat_Files/Parameters.mat

cfo = estimate_cfo(signal(1,1:num_bins),signal(1,1+num_bins:num_bins*2),fs);

signal_no_cfo = correct_cfo(signal,cfo,fs);

save ../Results/Result_CFO_Correction.mat signal_no_cfo cfo

h=figure;
subplot(1,2,1);ylabel('Imag');xlabel('Real');title('Constellation Before CFO Correction');
ylim([-1.5,1.5])
xlim([-1.5,1.5])
subplot(1,2,2);ylabel('Imag');xlabel('Real');title('Constellation After CFO Correction');
ylim([-1.5,1.5])
xlim([-1.5,1.5])

for m=1:1:(length(signal)/num_bins)
pause(0.25);
subplot(1,2,1);hold on;plot((1/sqrt(num_bins))*fft(signal(1+num_bins*(m-1):num_bins*m)),'.b');
subplot(1,2,2);hold on;plot((1/sqrt(num_bins))*fft(signal_no_cfo(1+num_bins*(m-1):num_bins*m)),'.r');
end

saveas(h,'../Results/Result_Cons_CFO_Corr.fig','fig');


end