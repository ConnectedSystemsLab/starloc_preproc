clear all; close all; clc;
addpath ../Tool_Functions/;

% load file
mon = 9; day = 8; hr = 12; minu = 5;
sample_rate = 100e6;
center_freq = 11.575e9;
IQ_Sample_file = get_file_name(mon, day, hr, minu, center_freq, sample_rate);

%% pss detect
% [pss_begin_idx] = frame_detect_pss(IQ_Sample_file, sample_rate, 1);
% CHOOSE
% load pss_begin_idx_1.mat;
load pss_begin_idx_1.mat;
T_f = 1/750;
N_f = T_f*sample_rate;
frame_num = length(pss_begin_idx);

%% coarse doppler compensation
[f_d, t_d] = deal(zeros(frame_num, 1));
for idx = 1:frame_num
    t_d(idx) = (pss_begin_idx(idx)-pss_begin_idx(1))/sample_rate;
    recv = read_complex_binary2(IQ_Sample_file, N_f, pss_begin_idx(idx));

    % CHOOSE
    % recv = recv.*exp(j*2*pi*(-85e3+2e3-3.8e3+500)*[0:N_f-1]'/100e6);
    recv = recv.*exp(j*2*pi*(-71e3)*[0:N_f-1]'/100e6);

    recv = my_resample_2(recv, 240e6, sample_rate);
    % recv = recv.*exp(j*2*pi*3.442606170145867e+03*([0:length(recv)-1]'/240e6+t_d(idx)).^2);
    % dopp_rate_wipe = chirp([0:length(recv)-1]'/240e6,3.442606170145867e+03*t_d(idx),(length(recv)-1)/240e6,3.442606170145867e+03*(t_d(idx)+(length(recv)-1)/240e6),'complex');
    % recv = recv.*dopp_rate_wipe;
    n_fft = 2^24;
    recv_fft = fftshift(fft(recv.*exp(j*2*pi*(234375/2)*[0:length(recv)-1]'/240e6), n_fft));
    freq = linspace(-120e6, 120e6, n_fft);
    recv_fft_ = recv_fft(abs(freq)<200e3);
    freq_ = freq(abs(freq)<200e3);
    [~, max_idx] = max(abs(recv_fft_));

    % CHOOSE
    % f_d(idx) = freq_(max_idx)-43.67e3*2;
    f_d(idx) = freq_(max_idx);
end
[dopp_rate, dopp_init] = least_square(t_d, f_d);

%% SSS channel estimation
SSS = get_sss(1024);
sss = ifft(SSS);
SSS_resamp = SSS;
% 1:214 & 812:1024
SSS_resamp(215:811) = 0;

% {4-QAM, QPSK, 16-QAM} -> {1, 2, 3}
% [data_bits] = deal(zeros(396, 300, frame_num));
% modulation = zeros(300, frame_num);
mod_list = ["4-QAM", "QPSK", "16-QAM"];

for idx = 11:frame_num
    t_f = (pss_begin_idx(idx)-pss_begin_idx(1))/sample_rate;
    recv = read_complex_binary2(IQ_Sample_file, N_f, pss_begin_idx(idx));

    % CHOOSE
    % recv = recv.*exp(j*2*pi*(-85e3+2e3-3.8e3+500)*[0:N_f-1]'/100e6);
    recv = recv.*exp(j*2*pi*(-71e3)*[0:N_f-1]'/100e6);

    recv = my_resample_2(recv, 240e6, sample_rate);
    
    % CHOOSE
    % dopp_rate_wipe = chirp([0:length(recv)-1]'/240e6,3.442606170145867e+03*t_f,(length(recv)-1)/240e6,3.442606170145867e+03*(t_f+(length(recv)-1)/240e6),'complex');
    % recv = recv.*dopp_rate_wipe;

    n_fft = 2^24;
    recv_fft = fftshift(fft(recv.*exp(j*2*pi*(234375/2)*[0:length(recv)-1]'/240e6), n_fft));
    freq = linspace(-120e6, 120e6, n_fft);
    recv_fft_ = recv_fft(abs(freq)<200e3);
    freq_ = freq(abs(freq)<200e3);
    [~, max_idx] = max(abs(recv_fft_));

    % CHOOSE
    % f_d = freq_(max_idx)-43.67e3*2;
    f_d = freq_(max_idx)-1.84e3;

    recv = recv.*exp(j*2*pi*(-f_d)*[0:length(recv)-1]'/240e6);
    sss_upsamp = recv(1057+20:2112+20);
    sss_upsamp = sss_upsamp(33:end);    % remove cp
    H = fft(sss_upsamp)./SSS;
    H([1 2 1023 1024])=0;
    plot(abs(ifft(H)));

    for idx_f = 3:302
        % continue
        frame_upsamp = recv(1+1056*(idx_f-1)+20:1056*idx_f+20);
        frame_upsamp = frame_upsamp(33:end);
        symbols = fft(frame_upsamp)./H;
        symbols_good = [symbols(3:200);symbols(825:end-2)];
        
        [decode_data_qam_4, err_qam_4] = QAM_4_hard_decision(symbols_good);
        [decode_data_qpsk, err_qpsk] = QPSK_hard_decision(symbols_good);

        if min(err_qpsk, err_qam_4) < .45
            if err_qpsk < err_qam_4
                modulation(idx_f-2, idx) = 2;
                data_bits(:, idx_f-2, idx) = decode_data_qpsk;
            else
                modulation(idx_f-2, idx) = 1;
                data_bits(:, idx_f-2, idx) = decode_data_qam_4;
            end
        else
            modulation(idx_f-2, idx) = 3;
            data_bits(:, idx_f-2, idx) = -1;
        end

        scatter(real(symbols_good), imag(symbols_good));
        xlim([-2.5 2.5]); ylim([-2.5 2.5]);
        title("Frame "+num2str(idx)+"-"+mod_list(modulation(idx_f-2, idx)));pause(.1);
    end
    % H = fft(a2(10:436))./SSS_resamp;
end

%% modulation visualization

num_4_QAM = sum(modulation==1);
num_QPSK = sum(modulation==2);
num_16_QAM = sum(modulation==3);

% stem(num_16_QAM); 
bar([num_4_QAM;num_QPSK;num_16_QAM]'/300);
% xlim([50 70]);
legend("4-QAM", "QPSK", "16-QAM");
xlabel("Frame index"); ylabel("Percentage of modulation type"); title("Sat #2"); grid on;

%% 
fr = 15;
stem(modulation(:, fr)); legend("\{1,2,3\}->\{4-QAM, QPSK, 16-QAM\}")
xlabel("Symbol index"); ylabel("Modulation Type"); title("Sat #2 Frame "+num2str(fr)); grid on;