function [res, dopp_param, t] = central_tone_tracking_blind(...
    IQ_Sample_file, sample_rate, if_visual, num_tones)
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

f_hardware = 28952;

% downsample & 1-st track
central_bw = 1.024e6;
F_spacing = 234375;
T_avg = 1;

n_fft = 10240;
t_fft = n_fft/central_bw;
sig_len = T_avg*central_bw;
sig_window = [];
num_read_samples = t_fft*sample_rate;
freq_bin = central_bw/n_fft;
tone_spacing = round(44e3/freq_bin);

idx = 1;
% tone_idx = 0;
thresh = 9;
dopp_list = [];

while 1
    sig = read_complex_binary2(IQ_Sample_file, num_read_samples, idx);
    if length(sig) ~= num_read_samples
        fprintf('file end\n');
        break;
    end
    % tmp = [tmp; resample(sig, 1e6, sample_rate)];
    % sig = sig.*exp(j*2*pi*F_spacing/2*[0:num_read_samples-1]'/sample_rate);
    sig = resample(sig, central_bw, sample_rate);
    if length(sig_window)<sig_len
        sig_window = [sig_window ; sig];
        idx = idx+num_read_samples;
        if length(sig_window) == sig_len
            [sig_fft_abs, f] = fft_avg(sig_window, central_bw, n_fft, f_hardware);
        end
        continue
    else
        sig_fft_abs = sig_fft_abs - abs(fftshift(fft(sig_window(1:length(sig))))).^2 + abs(fftshift(fft(sig))).^2;
        sig_window = [sig_window(length(sig)+1:end) ; sig];
    end
    % [sig_fft_abs, f] = fft_avg(sig_window, central_bw, n_fft, f_hardware);
    
    % remove hardware peak
    sig_fft_abs(abs(f - f_hardware)<5*freq_bin) = mean(sig_fft_abs(0.1*length(sig_fft_abs):0.9*length(sig_fft_abs)));
    idx = idx+num_read_samples;
    t_now = idx/sample_rate;
    [spec_max, f_max] = max(sig_fft_abs);
    if spec_max >= thresh
        dopp_list = [dopp_list ; f_max];
    else
        dopp_list = [dopp_list ; NaN];
    end
    % if round(t_now) < 216
    %     continue;
    % end
    if mod((idx-1)/num_read_samples, 50) ~= 0
        continue;
    end
    if if_visual
        % for visualize & debug
        subplot(2,1,1);
        plot(f, sig_fft_abs);
        xlim([f(1) f(end)]);
        title("t="+num2str(round(t_now))+"s");
        ylim([0 20]); yline(thresh);
        subplot(2,1,2);
        plot(linspace(0, t_now, length(dopp_list))', dopp_list, 'LineWidth', 1);
        pause(.01);
    end
end


end

