function sig = get_signal_piece(file_path, start_idx, end_idx)
% sig = datafile(start_idx:end_idx)

f = fopen(file_path, 'rb');
is_end = false;
num_samples = 1e6;
read_idx = 0;
sig = zeros(end_idx-start_idx+1, 1);
find_end = false;

while ~is_end && ~find_end
    [sig_read, is_end] = fread_complex(f, num_samples);
    read_idx = read_idx+1;
    idx_1 = (read_idx-1)*num_samples+1;
    idx_2 = read_idx*num_samples;

    if start_idx >= idx_1 && start_idx <= idx_2
        if end_idx >= idx_1 && end_idx <= idx_2
            sig = sig_read(mod(start_idx, num_samples) : mod(end_idx, num_samples));
            find_end = true;
        else
            sig_read_tmp = sig_read(mod(start_idx, num_samples):end);
            sig(1:length(sig_read_tmp)) = sig_read_tmp;
            sig_idx = length(sig_read_tmp)+1;
            while ~is_end && ~find_end
                [sig_read, is_end] = fread_complex(f, num_samples);
                read_idx = read_idx+1;
                idx_2 = read_idx*num_samples;
                if idx_2 > end_idx
                    find_end = true;
                    sig(sig_idx:end) = sig_read(1:mod(end_idx, num_samples));
                else
                    sig(sig_idx:sig_idx+num_samples-1) = sig_read;
                    sig_idx = sig_idx+num_samples;
                end
            end
        end
    end
end

if find_end == false
    error('index out of range');
end
end

