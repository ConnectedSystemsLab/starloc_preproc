% sym_decode.m: a script that decodes the data symbols from a .dat file
% run path: Channel_Estimation/

clear all; close all; clc;
addpath ../Tool_Functions/;

% load file
mon = 9; day = 21; hr = 17; minu = 11; sec = 31;
sample_rate = 100e6;
center_freq = 11.325e9;
% IQ_Sample_file = get_file_name(mon, day, hr, minu, center_freq, sample_rate);
IQ_Sample_file = get_file_name_new(mon, day, hr, minu, sec, center_freq, sample_rate);

%% pss detect

% CHOOSE one from three
% pss_begin_idx is the begin index of detected frames
% [pss_begin_idx] = frame_detect_pss(IQ_Sample_file, sample_rate, 0);
% load pss_begin_idx_1.mat;
% load pss_begin_idx_2.mat;
load pss_begin_idx_3.mat;

T_f = 1/750;                        % time of a frame (s)
N_f = T_f*sample_rate;              % # of samples in a frame
frame_num = length(pss_begin_idx);  % # of detected frames

%% doppler estimation based on central tone
% in this section, the doppler (plus CFO) of every frame is estimated based 
% on the central beacon with the assumption that one of them should be at
% F/2+center_freq (ref: signal structure paper from Todd)
F = 234375;

% t_d is the time in second of one frame, the time of first frame is 0
% f_d is the doppler at time t_d
[f_d, t_d] = deal(zeros(frame_num, 1));

for idx = 1:frame_num
    t_d(idx) = (pss_begin_idx(idx)-pss_begin_idx(1))/sample_rate;
    recv = read_complex_binary2(IQ_Sample_file, N_f, pss_begin_idx(idx));

    recv = my_resample_2(recv, 240e6, sample_rate);
    n_fft = 2^24;
    recv_fft = fftshift(fft(recv, n_fft));
    freq = linspace(-120e6, 120e6, n_fft);
    recv_fft_ = recv_fft(abs(freq)<200e3);
    freq_ = freq(abs(freq)<200e3);
    [~, max_idx] = max(abs(recv_fft_));

    % CHOOSE
    % f_d(idx) = freq_(max_idx)-43.67e3*2+F/2;
    f_d(idx) = freq_(max_idx)+F/2;
end
[dopp_rate, dopp_init] = least_square(t_d, f_d);

%% doppler estimation based on PSS
% in this section, the doppler (plus CFO) of every frame is estimated based 
% on the 7 (8-1) repeated subsequences of PSS, but it's not accurate enough
F = 234375;

[angs] = deal(zeros(frame_num, 1));
% t_d is the time in second of one frame, the time of first frame is 0
% f_d is the doppler at time t_d
for idx = 1:frame_num
    t_d(idx) = (pss_begin_idx(idx)-pss_begin_idx(1))/sample_rate;
    recv = read_complex_binary2(IQ_Sample_file, N_f, pss_begin_idx(idx));
    recv = my_resample_2(recv, 240e6, sample_rate);
    recv = recv(33:end);        % remove CP
    sub_idxs = 128*[1:7]';
    sub_seq = zeros(7, 128);
    for ii = 1:7
        sub_seq(ii, :) = recv(sub_idxs(ii)+1:sub_idxs(ii)+128);
    end
    % calculate subseq_{i+1}/subseq_{i}
    for ii = 1:6
        ratio(ii) = conj(sub_seq(ii+1,:))*sub_seq(ii,:).';
    end
    % average the angle of 6 ratios
    angs(idx) = mean(angle(ratio));
    plot(angle(ratio)); ylim([-pi pi]);
end
f_d = -(240e6/(2*pi*128))*angs;
[dopp_rate, dopp_init] = least_square(t_d, f_d);

%% SSS channel estimation
SSS = get_sss(1024);        % freq domain SSS

% {4-QAM, QPSK, 16-QAM} -> {1, 2, 3}
[data_bits] = deal(zeros(396, 300, frame_num));
% modulation = zeros(300, frame_num);
mod_list = ["4-QAM", "QPSK", "16-QAM"];

for idx = 1:frame_num
    t_f = (pss_begin_idx(idx)-pss_begin_idx(1))/sample_rate;
    recv = read_complex_binary2(IQ_Sample_file, N_f, pss_begin_idx(idx));

    recv = my_resample_2(recv, 240e6, sample_rate);

    % CHOOSE
    % f_d = t_f*dopp_rate+dopp_init;
    % f_d = t_f*dopp_rate+dopp_init-1.84e3;
    f_d = t_f*dopp_rate+dopp_init-1.5e3;

    recv = recv.*exp(j*2*pi*(-f_d)*[0:length(recv)-1]'/240e6);
    sss_upsamp = recv(1057+20:2112+20);
    sss_upsamp = sss_upsamp(33:end);    % remove cp
    H = fft(sss_upsamp)./SSS;
    H([1 2 1023 1024]) = 0;
    
    css_upsamp = recv(1+1056*(302-1)+20:1056*302+20);
    css_upsamp = css_upsamp(33:end);    % remove cp
    CSS = fft(css_upsamp);
    CSS = [CSS(3:200);CSS(825:end-2)];
    H_ = CSS./get_CSS();
    H_good = [H(3:200);H(825:end-2)];
    % tmp = tmp+fftshift(angle(H_./H_good));
    % plot(fftshift(angle(H_./H_good)));pause(.1)

    for idx_f = 3:302

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
        
        % constellation point visulization, comment if don't want to
        % plot(abs(ifft(H)));
        scatter(real(symbols_good), imag(symbols_good));
        xlim([-2.5 2.5]); ylim([-2.5 2.5]);
        title("Frame "+num2str(idx)+"-"+mod_list(modulation(idx_f-2, idx)));pause(.1);
    end
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