function [res, dopp_param, t] = central_tone_tracking(...
    IQ_Sample_file, pss_begin_idx, sample_rate, if_visual, num_tones)
% input
% - file path
% - frame begin index
% - sample rate
% - if_visual: 1 if want to plot the figures
% output
% - tone_list: the doppler estimation based on central tones
% - dopp_param: fit the tone_list in the form of k*t+b
%   dopp_param = [k;b]
% - t: time sequence

f_hardware = -4550;

% downsample & 1-st track
T_f = 1/750;
central_bw = 1.024e6;
F_spacing = 234375;
T_avg = 1;

n_fft = 1024;
t_fft = n_fft/central_bw;
% num_read_samples = t_fft*sample_rate;
num_read_samples = T_avg*sample_rate;
sig_len = T_avg*central_bw;
freq_bin = central_bw/n_fft;
tone_spacing = round(44e3/freq_bin);

idx = pss_begin_idx(1);
num_dopps = ceil((pss_begin_idx(end)-pss_begin_idx(1))/num_read_samples);
tone_list = zeros(num_dopps, num_tones);
tone_idx = 0;
thresh = 0;
tt = [];
f_d = [];

while idx <= pss_begin_idx(end)
    sig = read_complex_binary2(IQ_Sample_file, num_read_samples, idx);
    if length(sig) ~= num_read_samples
        break;
    end
    % tmp = [tmp; resample(sig, 1e6, sample_rate)];
    % sig = sig.*exp(j*2*pi*F_spacing/2*[0:num_read_samples-1]'/sample_rate);
    sig = resample(sig, central_bw, sample_rate);
    [sig_fft_abs, f] = fft_avg(sig, central_bw, n_fft, f_hardware);
    % sig_fft = fftshift(fft(sig, n_fft))/n_fft;
    % sig_fft_abs = abs(sig_fft);
    f = linspace(-central_bw/2, central_bw/2, n_fft)';
    
    % remove hardware peak
    sig_fft_abs(abs(f-300)<12*freq_bin) = mean(sig_fft_abs);
    
    % find peaks
    [pks,locs] = findpeaks(sig_fft_abs, ...
        'MinPeakDistance', tone_spacing*0.9, ...
        'NPeaks', 9, ...
        'MinPeakHeight', thresh);

    % sum_max = 0; 
    % for f_idx = 1:n_fft-(num_tones-1)*tone_spacing
    %     s = sum(sig_fft_abs(f_idx+[0:num_tones-1]*tone_spacing));
    %     if s > sum_max
    %         f_tone_begin = f(f_idx+[0:num_tones-1]*tone_spacing);
    %         sum_max = s;
    %     end
    % end
    % tone_idx = tone_idx+1;
    % tone_list(tone_idx, :) = f_tone_begin;
    
    t_now = idx/sample_rate;
    idx = idx+num_read_samples;
    % if t_now < 70
    %     continue;
    % end
    f_d = [f_d;f(locs)];
    tt = [tt;repmat(t_now, [length(locs) 1])];

    if if_visual
        % for visualize & debug
        % figure(10);
        plot(f, sig_fft_abs);
        xlim([f(1) f(end)]);
        title(round(t_now));
        ylim([0 10])
        % plot(f(locs), pks, 'r*');
        % xline(f_tone_begin);    
        pause(.1);
    end
end
if if_visual
    figure; hold on;
    t = [0:num_read_samples:(num_dopps-1)*num_read_samples]/sample_rate;
    for idx = 1:num_tones
        plot(t, tone_list(:, idx));
    end
end

% 2-nd tracking using linear regression
t = [0:num_read_samples:(num_dopps-1)*num_read_samples]'/sample_rate;
% linear function: yi = ki*t+bi
[k, b] = deal(zeros(num_tones, 1));
for idx = 1:num_tones
    [k(idx), b(idx)] = least_square(t, tone_list(:,idx));
end
% algorithm 1
for idx = 1:num_tones
    for t_idx = 1:num_dopps
        t_ = t(t_idx);
        dop = tone_list(t_idx, idx);
        [~, nearest_tone_idx] = min(abs(dop-k*t_-b));
        if nearest_tone_idx ~= idx
            % adjust the regression
            tone_list(t_idx, :) = tone_list(t_idx, :)...
                -tone_spacing*freq_bin*(nearest_tone_idx-idx);
            for ii = 1:num_tones
                [k(ii), b(ii)] = least_square(t, tone_list(:,ii));
            end
        end
    end
end
res = mean(tone_list, 2);
if num_tones == 11
    res = res+44e3;
end
[k, b] = least_square(t, res);
dopp_param = [k;b];

% result verification
if if_visual
    figure; hold on;
    t = [0:num_read_samples:(num_dopps-1)*num_read_samples]/sample_rate;
    for idx = 1:num_tones
        plot(t, tone_list(:, idx));
    end
    plot(t, res);
    title('Tracked central tone');
    xlabel('t/s');
    ylabel('f_d/Hz');
end

% stft = spectrogram(tmp, hanning(n_fft), 0, n_fft, central_bw, 'centered');
% mesh(abs(stft));

end

