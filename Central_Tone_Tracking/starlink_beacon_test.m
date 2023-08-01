
sample_rate = 10e6;
channel_center = 11.325e9;
center_freq = channel_center-9.75e9;
center_freq_ = num2str(center_freq/1e9);
bw = sample_rate;
mon = 7;
day = 31;
hr = 20;
minu = 34;

IQ_Sample_file = "/home/jidazhang/Desktop/data/8_1/"+ ...
    "time_14_10_freq_1_575G_bw_10M.dat";
    % "freq_"+center_freq_(1)+"_"+center_freq_(3:end)+ "G"+ ...
    % "_bw_"+num2str(round(bw/1e6))+"M"+"_time_"+ ...
    % num2str(mon)+"_"+num2str(day)+"_"+num2str(hr)+"_"+num2str(minu)+ ...
    % ".dat";
    

num_samples = 1000;
idx = 1;
agg_frames = 1000;
n_fft = 1024*2;
t = 0:1:num_samples-1;
t = t';
signal = [];
sig_fft = zeros(n_fft, 1);
power = [];
f = fopen(IQ_Sample_file, 'rb');

%% 
while (1)

    values = fread(f, [num_samples*2 1], 'float');
    if isempty(values)
        break;
    end
    sig = values(1:2:end) + values(2:2:end)*i;
    % signal = [signal; sig];
    sig_fft = sig_fft + fftshift(fft(sig, n_fft));

    idx = idx + 1;
    if mod(idx, agg_frames) == 0

        sig_fft = sig_fft / agg_frames;
        sig_fft_abs = abs(sig_fft);
        % idx 
        if 10*log10(max(sig_fft_abs)) > -9
            freq = linspace(-bw/2, bw/2, n_fft);
            plot(freq, 10*log10(abs(sig_fft)));
            sig_fft = zeros(n_fft, 1);
            pause(0.5);
        else
            sig_fft = zeros(n_fft, 1);
            continue;
        end
%         subplot(2,1,1)
%         x_axis = (idx-agg_frames)*num_samples:1:(idx)*num_samples-1;
%         freq = linspace(-bw/2, bw/2, n_fft);
% 
%         plot(freq, 10*log10(abs(sig_fft)));
%         ylim([-30 0]);
%         ylabel('abs(fft(y)) (dB)')
%         subplot(2,1,2)
%         plot(10*log10(abs(signal)))
%         title(num2str(idx))
%         ylabel('abs(y) (dB)')
%         ylim([-50, 0])
% %         subplot(1,3,3)
% %         spectrogram(signal, num_samples, 0, num_samples, sample_rate, 'centered');
% %         caxis([-180 -20])
%         pause(0.2);
%         signal = [];
%         sig_fft = zeros(n_fft, 1);
    end

end