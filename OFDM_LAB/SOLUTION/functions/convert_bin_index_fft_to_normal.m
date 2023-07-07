function [normal_bin_index] = convert_bin_index_fft_to_normal(fft_bin_index,num_bins)

if(mod(num_bins,2)==0)
    fft_to_normal = [0:(num_bins/2-1),-(num_bins/2):-1];
else
    fft_to_normal = [0:((num_bins-1)/2),-((num_bins-1)/2):-1];
end

normal_bin_index = fft_to_normal(fft_bin_index);

end