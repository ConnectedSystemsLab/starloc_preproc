%% load data

load data_bits_1.mat;
% % data symbol = N*M*F
% % N = subcarrier # = 396
% % M = symbol # = 300
% % F = frame # = 200
% load data_bits_2.mat;
% data symbol = N*M*F
% N = subcarrier # = 396
% M = symbol # = 300
% F = frame # = 28
[N, M, F] = size(data_bits);

% the first 9 symbols share the same modulation (QPSK)
first_nine_symbol = data_bits(:, 1:9, :);

for symb_idx = 1:9
    one_symbol = squeeze(first_nine_symbol(:, symb_idx, :));
    is_odd_sc = zeros(N, 1);
    % confirm whether one subcarrier is odd or even
    for sc_idx = 1:N
        one_sc = one_symbol(sc_idx, :);
        num_odd = sum(mod(one_sc, 2) == 1);
        if num_odd > M/2
            is_odd_sc(sc_idx) = 1;
        end
    end
    % calculate the mean of one subcarrier across different frames
    symb_mean = mean(one_symbol, 2);
    find(abs(symb_mean-round(symb_mean))<.05 & (mod(round(symb_mean), 2) == is_odd_sc))
end