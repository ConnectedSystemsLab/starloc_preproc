function [sig_fft, f] = fft_avg(sig, bw, n_fft)
% length(sig) = multiple of n_fft

l = length(sig);
if mod(l, n_fft) ~= 0
    error('length of signal should be multiple of fft points\n');
end

f = linspace(-bw/2, bw/2, n_fft);
signal_reshape = reshape(sig, [n_fft l/n_fft]);
signal_reshape_fft = fftshift(fft(signal_reshape, n_fft))/sqrt(n_fft);
sig_fft = mean(signal_reshape_fft, 2);

end