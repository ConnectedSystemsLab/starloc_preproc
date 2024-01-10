%%
date_ = "1_8";
addpath ../;
addpath ../Tool_Functions/;
% fprintf(date+"/info.mat")
% configure date manually
load(date_+"/info.mat");

%% main
% sample_rate = 2e6;
IQ_Sample_file_1 = strrep(IQ_Sample_file_0,'rx0','rx1');
IQ_Sample_file_2 = strrep(IQ_Sample_file_0,'rx0','rx2');

[peak_array_0, time_array, central_bw, n_fft] = tone_track(IQ_Sample_file_0, sample_rate, loc_sig_idx, 0);

[peak_array_1, time_array, central_bw, n_fft] = tone_track(IQ_Sample_file_1, sample_rate, loc_sig_idx, 0);

[peak_array_2, time_array, central_bw, n_fft] = tone_track(IQ_Sample_file_2, sample_rate, loc_sig_idx, 0);

save(date_+"/peaks.mat", "peak_array_0", "peak_array_1", "peak_array_2", "time_array", "central_bw", "n_fft");
fprintf("results saved to "+date_+"/peaks.mat\n");

%% center tone track function
function [peak_array, time_array, central_bw, n_fft] = tone_track(IQ_Sample_file, sample_rate, noise_idx, if_visual)
% Do central tone tracking, specify idx with idx where noise starts
addpath ../Tool_Functions/;
central_bw = 1.024e6;
T_avg = 1;
n_fft = 2^10;
t_fft = n_fft/central_bw;
num_read_samples = T_avg*sample_rate; %t_fft*sample_rate;

idx = noise_idx;
fig = figure;
% time = num_read_samples/sample_rate;
time = 0;
move_by = num_read_samples/2;
time_array = [];
peak_array = [];
while 1
    sig = read_complex_binary2(IQ_Sample_file, num_read_samples, idx);
    if length(sig) ~= num_read_samples
        fprintf("breaking\n");
        close(fig);
        break;
    end
    
    sig = resample(sig, central_bw, sample_rate);
    [sig_fft_abs, f] = fft_avg(sig, central_bw, n_fft, 1);
    [max, midx] = maxk(sig_fft_abs, 20); % find 10 peaks - 9 tones and 1 constant hardware induced
    mean_sig_amp = mean(sig_fft_abs);
    peaks = [];
    peaks_idx = [];
    for i=1:1:length(max)
        if max(i) > mean(sig_fft_abs)+2*std(sig_fft_abs) 
            if i>1 && any((abs(midx(i)-midx(1:i-1)) < 5))
                continue
            end
            peaks = [peaks max(i)];
            peaks_idx = [peaks_idx midx(i)];
        end
    end
    peak_subarray = zeros(1, n_fft);
    peak_subarray(peaks_idx) = peaks;
    time_array = [time_array; time];
    peak_array = [peak_array; peak_subarray];
    
%     alpha = 2.5;
%     opts = {'Window', gausswin(n_fft,alpha), 'FFTLength', n_fft};
%     stft(sig, sample_rate, opts{:});
%     plot((abs(fftshift(fft(sig)./sqrt(num_read_samples)))));
%     ylim([0,0.05]);
    if if_visual
        scatter(peaks_idx, 20*log10(peaks), 'filled');
        xlim([0,length(sig_fft_abs)])
        hold on;
        plot(20*log10(sig_fft_abs));
        ylim([20,40])
        title(join([num2str(time), " ",num2str(peak2rms(sig_fft_abs))]));
        pause(0.1);
        clf;
    end
    idx = idx+move_by;
    time = time+move_by/sample_rate
end
end