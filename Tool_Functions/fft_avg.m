function [sig_fft, f] = fft_avg(sig, bw, n_fft, f_hardware)
% calculates the average spectrum power
% length(sig) = multiple of n_fft

l = length(sig);
if mod(l, n_fft) ~= 0
    % error('length of signal should be multiple of fft points');
    sig = sig(1:end-mod(l, n_fft));
    l = length(sig);
end

f = linspace(-bw/2, bw/2, n_fft);
f_bin = f(2)-f(1);
signal_reshape = reshape(sig, [n_fft l/n_fft]);
signal_reshape_fft = fftshift(fft(signal_reshape, n_fft, 1), 1);
sig_fft = mean(abs(signal_reshape_fft).^2, 2);
% sig_fft(abs(f-f_hardware)<2*f_bin) = mean(sig_fft(abs(f-f_hardware)<2*f_bin));

end