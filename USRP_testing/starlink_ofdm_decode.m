%% read trace file

IQ_Sample_file = '/home/ishani/LeoPNT/USRP_data/capture_2023_07_24_bw-100_center-2_22_time-15_17.dat';
% IQ_Sample_file = '/home/ishani/LeoPNT/USRP_data/IQ_Samples_06_22_23_16_12_20MHz_11950-speedtest.dat';
% IQ_Sample_file = '/home/ishani/LeoPNT/USRP_data/capture_2023_07_24_bw-100_center-1_825_time-15_27.dat';

sample_rate = 100e6;
center_freq = 1.825e9;
bw = sample_rate;
num_samples = 1024;
idx = 1;
agg_frames = 1000;
t = 0:1:num_samples-1;
t = t';
signal = [];
power = [];
f = fopen(IQ_Sample_file, 'rb');

%% 
while(1)
    
    values = fread(f, [num_samples*2 1], 'float');
    a = values(1:2:end) + values(2:2:end)*i;
    signal = [signal; a];
%     power = [power mean(abs(a))];

%     x = real(a).*cos(2*pi*center_freq*(t+idx*num_samples)*1/sample_rate)+imag(a).*sin(2*pi*center_freq*(t+idx*num_samples)*1/sample_rate);
%     power = [power mean(x.^2)];

    
%         plot frequency plot if the average power of the signal in current frame is >= 0.5
%         mean overall
%     plot(abs(fft(a)));
%     pause(0.1)
    
    
%     plot spectrogram  
    % if (is_end == 1)
    %     break
        
    % end
    
    idx = idx + 1;
    if mod(idx,agg_frames) == 0
        x_corr = xcorr(signal);
        subplot(3,1,1)
        plot(10*log10(abs(x_corr)));
        % ylim([0,0.005])
        xlim([length(x_corr)/2-500 length(x_corr)/2+500])
        subplot(3,1,2)
        x_axis = (idx-agg_frames)*num_samples:1:(idx)*num_samples-1;
        plot(abs(fftshift(fft(signal)))/num_samples)
        ylim([0,0.05])
        subplot(3,1,3)
        plot(10*log10(abs(signal)))
        title(num2str(idx))
        % ylim([0,0.1])
%         subplot(1,3,3)
%         spectrogram(signal, num_samples, 0, num_samples, sample_rate, 'centered');
%         caxis([-180 -20])
        pause(0.5);
        signal = [];
    end
    
%     if (mod(idx,10)==0)
%         %create spectrogram
%         spec = figure;
%         spectrogram(signal, num_samples, 0, num_samples, sample_rate, 'centered');
%         caxis([-180 -20])
%         pause(1)
% %         waitforbuttonpress();
%         close(spec);
%         signal = [];    
%     
%      end
    
end
    

%%
for i=2:1:length(sig) 
    sig_ = sig(i:end);
    A = padarray(sig_, [0 length(sig)-length(sig_)], 'post');
    plot(abs(sig.*conj(A)));
    ylim([0, 4e-3])
    pause(0.1);
end
