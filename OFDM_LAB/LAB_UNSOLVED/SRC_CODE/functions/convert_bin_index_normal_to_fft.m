function [fft_bin_index] = convert_bin_index_normal_to_fft(normal_bin_index,num_bins)

if(mod(num_bins,2)==0)
   normal_to_fft = [1+(num_bins/2):num_bins,1:(num_bins/2)];
   fft_bin_index = normal_to_fft(1+num_bins/2+normal_bin_index);
else
   normal_to_fft = [1+((num_bins-1)/2):num_bins,1:((num_bins-1)/2)];
   fft_bin_index = normal_to_fft(1+(num_bins-1)/2+normal_bin_index); 
end

end