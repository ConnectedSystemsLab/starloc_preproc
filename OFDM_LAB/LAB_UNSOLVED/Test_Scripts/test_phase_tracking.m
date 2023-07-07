function test_phase_tracking()

close all
% addpath ../SRC_CODE_master
% addpath ../SRC_CODE_master/functions
addpath ../SRC_CODE
addpath ../SRC_CODE/functions
load ../Mat_Files/Test/Test_Phase_Tracking.mat
load ../Mat_Files/Parameters.mat

cfo_r = zeros(1,num_syms_data);
sfo_r = zeros(1,num_syms_data);

k=figure;
subplot(1,2,1);ylabel('Imag');xlabel('Real');title('Constellation Without Phase Tracking ');
xlim([-1.5,1.5])
ylim([-1.5,1.5])
subplot(1,2,2);ylabel('Imag');xlabel('Real');title('Constellation With Phase Tracking');
xlim([-1.5,1.5])
ylim([-1.5,1.5])

for m=1:1:num_syms_data
pause(0.25);
sym = 1/sqrt(num_bins)*fft(signal(1+(num_bins+cp)*(m-1):num_bins*m+cp*(m-1)));

[cfo_r(m) ,sfo_r(m)] = estimate_residual_cfo_sfo(sym,h);
h = correct_residual_cfo_sfo(h,cfo_r(m),sfo_r(m));

subplot(1,2,1);hold on;plot(sym./h_f,'.b');
subplot(1,2,2);hold on;plot(sym./h,'.r');
end

saveas(k,'../Results/Result_Cons_Phase_Track.fig','fig');
save ../Results/Result_Phase_Tracking.mat sfo_r cfo_r


end
