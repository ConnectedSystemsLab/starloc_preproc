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

%% first nine symbols
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

%% common symbols in one frame
frame_idx = 107;
data = data_bits(:, :, frame_idx);
mo = modulation(:, frame_idx);
m = 0;
for symb_idx = 50:300
    one_symbol = data(:, symb_idx);
    if one_symbol(1) == -1
        continue;
    end
    for jj = symb_idx+1:300
        tt = sum(one_symbol==data(:, jj))/N;
        if tt > m
            m = tt;
        end
    end
end

%% common symbols across different frames
mean(modulation, 2);
last_symbol = squeeze(data_bits(:,end,:));
last_but_one_sym = squeeze(data_bits(:,end-1,:));
[CSS, f_1] = mode(last_symbol, 2);
[CM1SS, f_2] = mode(last_but_one_sym, 2);
mean(f_1)/200
mean(f_2)/200
% m = 0; n = 0;
% for frame_idx = 1:200
%     last_symbol_one_fr = data_bits(:, end, frame_idx);
%     last_symbol_but_one_fr = data_bits(:, end-1, frame_idx);
%     m = m+mean(CSS==last_symbol_one_fr);
%     n = n+mean(CM1SS==last_symbol_but_one_fr);
% end
% m = m/200
% n = n/200