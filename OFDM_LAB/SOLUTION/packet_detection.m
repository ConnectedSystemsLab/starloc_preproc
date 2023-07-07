function [ packet_start_index ] = packet_detection(rx_signal)

load ../Mat_Files/Parameters.mat 

% Dc removal filter
alpha = 0.975; 
rx_signal = filter([1 -1], [1 -alpha], rx_signal);

threshold=6;

window_size = 4*num_bins;

max_ratio = -Inf;

for j = 1:numel(rx_signal)-2*window_size+1
   ratio = 1/((sum(abs(rx_signal(j:j+window_size-1)).^2))/sum(abs(rx_signal(j+window_size:j+2*window_size-1)).^2)); 
    if ratio > max_ratio
        packet_start_index = j+window_size;
        max_ratio = ratio;
    end
    ratio_all(j+window_size) = ratio;
end

% figure
% hold on
% plot(abs(rx_signal))
% plot(0.5*ratio_all/max(ratio_all))
% plot(packet_start_index,0.4,'*')

if(max_ratio < threshold)
    packet_start_index = -1;
    return;
end
packet_start_index = packet_start_index + floor((3/4)*cp);

end