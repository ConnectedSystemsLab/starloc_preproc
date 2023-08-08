function [x, p_] = get_pss()
% this function computes time domain PSS sequence
% q_pss bits -> time domain PSS

N_g =32;
N = 1024;
N_sym = N_g+N;

q_pss = 'C1B5 D191 024D 3DC3 F8EC 52FA A16F 3958';
hex_nums = strsplit(q_pss);
bin_nums = '';
% bin_nums = zeros(1, 128);
for idx = 1:length(hex_nums)
    bin_nums = [bin_nums dec2bin(hex2dec(hex_nums{idx}), 16)];
end

x = zeros(N_sym, 1);
p_ = zeros(N_sym, 1);
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
    p_(idx) = p;
end
x(1:N_g) = x(end-N_g+1:end);

end