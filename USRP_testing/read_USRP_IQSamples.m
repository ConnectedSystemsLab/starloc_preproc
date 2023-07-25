clear all;
addpath ../functions/

IQ_Sample_file = '/home/ishani/LeoPNT/USRP_data/capture_2023_07_24_bw-100_center-1_825_time-15_27.dat'

% save_to_folder = '/Users/ishani/UIUC/Research/LeoSat/Positioning/codebase/USRP_testing/spectrograms';
% sub_folder_name = split(IQ_Sample_file, '/');
% sub_folder_name = split(sub_folder_name(end), '.');
% sub_folder_name = sub_folder_name{1};
% 
% dirs = {save_to_folder, sub_folder_name}
% for k = 1 :length (dirs)
%   Thisdir = fullfile(dirs{1:k})
%   mkdir(Thisdir)
% end

sample_rate = 100e6;
center_freq = 1.825e9;
bw = sample_rate;
num_samples = 8192;
idx = 0;
spectrogram_num = 0
signal = [];
f = fopen(IQ_Sample_file, 'rb');

while(1)
    % values = fread(f, [num_samples*2 1], 'float');
    % a = values(1:2:end) + values(2:2:end)*i;
    % signal = [signal; a];
    [a, is_end] = read_complex_binary_gnu_file(IQ_Sample_file, num_samples, idx*num_samples);
%     a = bandpass(a,[1 0.4e6],sample_rate);
    signal = [signal; a];
    if (is_end == 1)
        break
    end
    idx = idx + 1;
    if (mod(idx,100)==0)
        %create spectrogram
        spec = figure;
        spectrogram(signal, num_samples, 0, num_samples, sample_rate, 'centered');
        caxis([-180 -20])
        %save spectrogram figure & close it
        % savefig(spec, join([save_to_folder, '/', sub_folder_name, '/', num2str(spectrogram_num), '.fig'], ''));
        pause(0.5)
% 
%         waitforbuttonpress();
        close(spec);
        signal = [];
        spectrogram_num = spectrogram_num + 1;
    end
    
%     psd = ((1/(sample_rate*num_samples)) * abs(fft(a-mean(a))).^2);
% %     psd = psd(1:num_samples/2+1);
%     psd(2:end-1) = 2*psd(2:end-1);
%     psd = fftshift(pow2db(psd));
%     plot(psd);
%     ylim([-140, -60]);
%     xlim([3000,5000]);
%     pause(0.1)
end

%%
for i = 0:1:20
    fig = openfig(join(['/Users/ishani/UIUC/Research/LeoSat/Positioning/codebase/USRP_testing/spectrograms', '/IQSamples_02_12_23_16_39_5mhz/', num2str(i),'.fig'], ''))
    x0=100;
    y0=100;
    width=1400;
    height=800
    set(fig,'position',[x0,y0,width,height])
%     waitforbuttonpress();
%     close all;
end

%%
t = 0:1/1e3:10;
fo = -200;
f1 = 300;

y = chirp(t,fo,t(end),f1,'linear',0,'complex');
