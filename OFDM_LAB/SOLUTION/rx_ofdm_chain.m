function [ bits_data ] = rx_ofdm_chain(rx_signal)

if ~isrow(rx_signal)
    rx_signal = transpose(rx_signal);
end

load ../Mat_Files/Parameters.mat

bits_data = [];

% Use this variable to help you set the data subcarriers from pilot
% subcarriers from unused subcarriers
subcarrier_config = ones(1,num_bins);
subcarrier_config(convert_bin_index_normal_to_fft(gaurd_bins,num_bins)) = 0;
subcarrier_config(convert_bin_index_normal_to_fft(pilots,num_bins)) = 3; 

% Use this variable to keep track at which sample you are in packet
current_index = 1;

%% PACKET DETECTION

packet_start =packet_detection(rx_signal(current_index:end));
current_index = packet_start + 4*num_bins;

% figure(1)
% hold on
% plot(current_index,0.04,'-r*')
% plot(abs(rx_signal))
% hold off

%% CFO ESTIMATION AND CORRECTION

cfo = estimate_cfo(rx_signal(current_index:current_index+num_bins-1),rx_signal(current_index+num_bins:current_index+num_bins+num_bins-1),fs);
rx_signal(current_index:end)= correct_cfo(rx_signal(current_index:end),cfo,fs);
current_index = current_index + 2*num_bins;

%% CHANNEL ESTIMATION

h = estimate_channel(rx_signal(current_index:current_index+num_bins-1),rx_signal(current_index+num_bins:current_index+2*num_bins-1));
current_index = current_index + 2*num_bins+cp;

%% DECODING
for m = 1:1:num_syms_data

    symt = rx_signal(current_index:current_index+num_bins-1);
    symf = (1/sqrt(num_bins))*fft(symt);
    [r_cfo , r_sfo] = estimate_residual_cfo_sfo(symf, h);
    h = correct_residual_cfo_sfo(h, r_cfo , r_sfo);
    symf = correct_channel(symf,h); 
    %figure(1);plot(symf,'.');ylim([-1 1]);
    bits = symf(subcarrier_config==1) < 0;
    bits_data = [bits_data, fftshift(bits)];
    current_index = current_index + num_bins+cp;

        
    figure(1);    
    plot(real(symf),imag(symf),'*')
    hold on;
    xlim([-1.2,+1.2])
    ylim([-1.2,+1.2])
    title(sprintf('symbol %d',m));
    pause(0.002);

end

close all
    
end