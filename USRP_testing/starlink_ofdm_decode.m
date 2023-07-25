%% read trace file

IQ_Sample_file = '/Users/ishani/UIUC/Research/LeoSat/Positioning/USRP_Data/IQ_Samples_06_22_23_16_12_20MHz_11950-speedtest.dat';

sample_rate = 20e6;
center_freq = 2.2e9;
bw = sample_rate;
num_samples = 2*4096;
idx = 287;
agg_frames = 20;
t = 0:1:num_samples-1;
t = t';
signal = [];
power = [];
while(1)
    [a, is_end] = read_complex_binary2(IQ_Sample_file, num_samples, idx*num_samples);
    signal = [signal a'];
%     power = [power mean(abs(a).^2)];

%     x = real(a).*cos(2*pi*center_freq*(t+idx*num_samples)*1/sample_rate)+imag(a).*sin(2*pi*center_freq*(t+idx*num_samples)*1/sample_rate);
%     power = [power mean(x.^2)];

    
%         plot frequency plot if the average power of the signal in current frame is >= 0.5
%         mean overall
%     plot(abs(fft(a)));
%     pause(0.1)
    
    
%     plot spectrogram  
    if (is_end == 1)
        break
        
    end
    
    idx = idx + 1;
    if mod(idx,agg_frames) == 0
        x_corr = xcorr(signal,conj(signal));
        subplot(3,1,1)
        plot((abs(x_corr)));
        ylim([0,0.5])
        subplot(3,1,2)
        x_axis = (idx-agg_frames)*num_samples:1:(idx)*num_samples-1;
        plot(abs(fftshift(fft(signal)))/num_samples)
        ylim([0,0.002])
        subplot(3,1,3)
        plot(abs(signal))
        title(num2str(idx))
        ylim([0,0.1])
%         subplot(1,3,3)
%         spectrogram(signal, num_samples, 0, num_samples, sample_rate, 'centered');
%         caxis([-180 -20])
        pause(0.1);
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
