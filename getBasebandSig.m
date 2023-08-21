function [x, t] = getBasebandSig()
% generate time-domain baseband transmit signal

% get parameters
setParam;
x = zeros((N_sf+1)*N_sym*N_f, 1);   % time domain signal
% frequency domain

% the probability that a frame contains data
binary_set=[0 1];
Prob = [duty_ratio 1-duty_ratio];
is_null = false;

% avoid unnecessary computation:
% if computed, then do not compute again
pss_seq = nan;

for frame = 1:N_f
    % is_null = randsrc(1, 1, [binary_set ; Prob]);
    is_null = ~is_null;
    if is_null
        continue;
    end
    % frame structure
    % frequency domain symbols (dim-1: symbol; dim-2: subcarrier)
    X = zeros(N_sf, N); 

    % X(1,:) = PSS
    % "PSS was found to lack any discernible constellation structure when
    % viewed in the frequency domain"

    % X(2,:) = SSS
    % "SSS was found to be a standard OFDM symbol, with 4QAM modulation"
    X(2,:) = getSSS(N);

    % X(301,:) = CM1SS
    % "CM1SS is found to contain some information symbols that are constant from
    % frame to frame."
    X(301,:) = qammod(randi([0 3], 1, N), 4)/sqrt(2);

    % X(302,:) = CSS
    % "the CSS's constellation clusters form a box aligned with the horizontal
    % and vertical axes"
    X(302,:) = qammod(randi([0 3], 1, N), 4)/sqrt(2);

    % X(3:301,:) = data symbols
    X(3:300,:) = pskmod(randi([0 3], N_sfd, N), 4);
    % gutter
    X(:, [1 2 N-1 N]) = 0;

    % time domain
    x_slice = zeros((N_sf+1)*N_sym, 1);
    for idx = 1:302
        if idx == 1
            if isnan(pss_seq)
                x_slice(1:N_sym) = getPSS(N_g, N, N_sym);
                pss_seq = x_slice(1:N_sym);
            else
                x_slice(1:N_sym) = pss_seq;
            end
            continue;
        else
            tmp = zeros(T_sym*F_s, 1);
            tmp(N_g+1:end) = sqrt(N)*ifft(X(idx, :).');
            tmp(1:N_g) = tmp(end-N_g+1:end);
            x_slice((idx-1)*N_sym+1:idx*N_sym) = tmp;
        end
    end
    x((frame-1)*(N_sf+1)*N_sym+1:frame*(N_sf+1)*N_sym) = x_slice;
end
t = [1:(N_sf+1)*N_sym*N_f]'/F_s;
end

function X = getSSS(N)
% this function computes frequency domain SSS sequence
% q_sss bits ->frequency domain SSS

X = zeros(N, 1);
q_sss = ...
     ['BD 565D 5064 E9B3 A949 58F2 8624 DED5 6094 6199 F5B4 0F0E 4FB5' ...
    'EFCB 473B 4C24 B2D1 E0BD 01A6 A04D 5017 DE91 A8EC C0DA 09EB FE57' ...
    'F9F1 B44C 532F 161C 583A 4249 0A5C 09F2 A117 F9A2 8F9B 2FD5 47A7' ...
    '4C44 BABB 4BE8 5DA6 A62B 1235 E2AD 084C 0018 0142 A8F7 F357 DEC4' ...
    'F313 16BC 58FA 4049 09A3 FCA7 F88E 4219 02B6 A258 0AE8 0308 03F6' ...
    '5809 DB34 7F59 0DBC 46F0 10EB E3A2 5C06 0D74 429F C46B DF9B 6371' ...
    '9279 798D 232C 5ABA 2741 22FF 66AD 7E44 9F44 CB40 C49C 24A1 E262' ...
    '9F5B FE82 CE53 1FDC 34F8 C64A 43A9 63F4 0D5B 71BD E6FB 2F13 492D' ...
    '6F2E 8544 B21D 4497 22C6 3518 0342 CD00 26A1 E7F7 E80E 91B1 75E8' ...
    '52F9 1976 7E5A F9B6 E909 AF36 2F52 18E2 B908 DC00 5803'];
hex_nums = strsplit(q_sss);
for idx = 1:length(hex_nums)
    if idx ~= length(hex_nums)
        hex_str = hex_nums{length(hex_nums)+1-idx};
        X_tmp = zeros(8, 1);
        for ii = 1:4
            digit = hex_str(5-ii);
            dec_num = hex2dec(digit);
            X_tmp(ii*2) = floor(dec_num/4);
            X_tmp(ii*2-1) = dec_num - 4*X_tmp(ii*2);
        end
        X(3+(idx-1)*8:2+idx*8) = X_tmp;
    else
        X(1019:1022) = [1 3 3 2]';
    end
end
X = exp(1j*X*pi/2);
X(1:2) = 0;
X(1023:1024) = 0;
end

function x = getPSS(N_g, N, N_sym)
% this function computes time domain PSS sequence
% q_pss bits -> time domain PSS

q_pss = 'C1B5 D191 024D 3DC3 F8EC 52FA A16F 3958';
hex_nums = strsplit(q_pss);
bin_nums = '';
% bin_nums = zeros(1, 128);
for idx = 1:length(hex_nums)
    bin_nums = [bin_nums dec2bin(hex2dec(hex_nums{idx}), 16)];
end

x = zeros(N_sym, 1);
for idx = 1:N_g+N
    k = idx-N_g-1; 
    theta = -1/4;
    if k < N/8
        theta = theta+1;
    end
    sum_b = 0;
    for l = 0:mod(k, N/8)
%         b_l = 2*mod(str2num(bin_nums(end-l)), 2)-1;
        b_l = 2*mod(str2double(bin_nums(end-l)), 2)-1;
        sum_b = sum_b+b_l;
    end
    theta = theta-1/2*sum_b;
    p = exp(1j*pi*theta);

%     x(N_g+1:end) = x(N_g+1:end)+p*sinc(-k-N_g+[1:N]');
    x(N_g+1:end) = x(N_g+1:end)+p*((-k-N_g+[1:N]')==0);
end
x(1:N_g) = x(end-N_g+1:end);

end