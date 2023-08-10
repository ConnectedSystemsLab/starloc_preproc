%% read trace file
addpath ../Tool_Functions/;

sample_rate = 100e6;
channel_center = 11.575e9;
center_freq = channel_center-9.75e9;
center_freq_ = num2str(center_freq/1e9);
bw = sample_rate;
mon = 8;
day = 1;
hr = 15;
minu = 2;

num_samples = 1e6;
idx = 1;
agg_frames = 20;
signal = zeros(agg_frames*num_samples, 1);
power = [];

IQ_Sample_file = "/home/jidazhang/Desktop/data/8_1/"+ ...
    "time_14_59_freq_11_575G_bw_100.0M.dat";
f = fopen(IQ_Sample_file, 'rb');

sig_dsamp = [];
cnt = 0;
%% 
while(1)
    idx = idx + 1;
    values = fread(f, [num_samples*2 1], 'float');
    if idx <= 3000
        continue;   % 4570
    end
    if isempty(values)
        break;
    end
    
    if cnt == 80
        break;
    end
    idx_mod = mod(idx, agg_frames);
    sig_cplx = values(1:2:end) + values(2:2:end)*1j;
    if idx_mod ~= 0
        signal((idx_mod-1)*num_samples+1:idx_mod*num_samples) = sig_cplx;
    else
        signal((agg_frames-1)*num_samples+1:end) = sig_cplx;
        sig_dsamp = [sig_dsamp; resample(signal, 1.024e6, 100e6)];
        cnt = cnt + 1;
        x_corr = xcorr(signal);
        subplot(3,1,1)
        plot(mag2dB(abs(x_corr)/length(x_corr)));
        % ylim([0,0.005])
        % xlim([length(x_corr)/2-500 length(x_corr)/2+500])
        subplot(3,1,2)
        freq = linspace(-bw/2, bw/2, num_samples);
        signal_reshape = reshape(signal, [num_samples agg_frames]);
        signal_reshape_fft = fftshift(fft(signal_reshape))/num_samples;
        plot(freq, mag2dB(abs(mean(signal_reshape_fft, 2))));
        % ylim([0,0.05])
        subplot(3,1,3)
        plot(mag2db(abs(signal)))
        title(num2str(idx))
        % ylim([0,0.1])
%         subplot(1,3,3)
%         spectrogram(signal, num_samples, 0, num_samples, sample_rate, 'centered');
%         caxis([-180 -20])
        pause(0.5);
    end
%     power = [power mean(abs(a))];

    
%         plot frequency plot if the average power of the signal in current frame is >= 0.5
%         mean overall
%     plot(abs(fft(a)));
%     pause(0.1)
    
    
%     plot spectrogram  
    
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