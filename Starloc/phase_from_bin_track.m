addpath ../Tool_Functions/;
% change this to the date you want to process
% date_ = "6Mar2024_04_19/";
% check if date_ is defined
if ~exist('date_','var')
    fprintf("Please define the date_ folder \n");
    return;
end
% check if date_ end with '/'
if date_(end) ~= '/'
    date_ = date_+"/";
end
load(date_+"info.mat");
%% file
f_0 = IQ_Sample_file_0;
f_1 = strrep(f_0,'rx0','rx1');
f_2 = strrep(f_0,'rx0','rx2');
num_read_samples = 14e-3*sample_rate;
f = linspace(-sample_rate/2, sample_rate/2, num_read_samples);

%% track doppler
res = [];
start_idx = 1;
thresh = 3.5;%5; % for synthetic data 3.5; % for real data
if_visual = 0;
buffer = 0.1 * 2e6; % number of samples to add before and after the reference signal when looking for center tones
% t_end = 60; % seconds
while start_idx < t_end*sample_rate
    sig_0 = read_complex_binary2(f_0, num_read_samples, start_idx);
    sig_1 = read_complex_binary2(f_1, num_read_samples, start_idx);
    sig_2 = read_complex_binary2(f_2, num_read_samples, start_idx);
    % check whether current time is in the reference signal, if so, skip
        % if synthetic in date_, the reference signal is not available so skip this step
    if ~contains(date_,'synthetic')
        later_than_begin = start_idx >= ref_sig_idx(:,1)-buffer;
        ealier_than_end = start_idx <= ref_sig_idx(:,2)+buffer;
        if find(later_than_begin & ealier_than_end)
            start_idx = start_idx+num_read_samples/2;
            continue;
        end
    end

    sig_0_fft = fftshift(fft(sig_0));
    sig_1_fft = fftshift(fft(sig_1));
    sig_2_fft = fftshift(fft(sig_2));
    sig_0_fft_abs = abs(sig_0_fft);
    sig_1_fft_abs = abs(sig_1_fft);
    sig_2_fft_abs = abs(sig_2_fft);

    pw_avg_0 = mean(sig_0_fft_abs);
    pw_avg_1 = mean(sig_1_fft_abs);
    pw_avg_2 = mean(sig_2_fft_abs);
    idx_0 = sig_0_fft_abs>thresh*pw_avg_0;
    idx_1 = sig_1_fft_abs>thresh*pw_avg_1;
    idx_2 = sig_2_fft_abs>thresh*pw_avg_2;
    % if length(find(idx_0)) > 300 || length(find(idx_1)) > 300 || length(find(idx_2)) > 300
    %     continue;
    % end
    idx_com = intersect(intersect(find(idx_0), find(idx_1)), find(idx_2));
    t = (start_idx+num_read_samples/2)/sample_rate;
    for ii = 1:length(idx_com)
        idx_com_ii = idx_com(ii);
        res = [res ; [t idx_com_ii sig_0_fft(idx_com_ii) sig_1_fft(idx_com_ii) sig_2_fft(idx_com_ii)]];
    end
    if if_visual
        subplot(2,1,1); hold on; title(num2str(t));
        plot(f,sig_0_fft_abs); scatter(f(idx_com),sig_0_fft_abs(idx_com)); xlim([-600e3 600e3]); ylim([0 10*pw_avg_0]);
        subplot(2,1,2); hold on;
        plot(f,sig_1_fft_abs); scatter(f(idx_com),sig_1_fft_abs(idx_com)); xlim([-600e3 600e3]); ylim([0 10*pw_avg_1]);
        pause(.01);
        clf;
    end
    start_idx = start_idx+num_read_samples/2;
end
save(date_+'res.mat','res');
fprintf("Centertone detection and tracking: done, result saved in "+date_+'res.mat, total %d points\n', size(res,1));
