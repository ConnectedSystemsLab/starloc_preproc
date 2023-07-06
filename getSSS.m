function X = getSSS(N)
% qsss->frequency domain SSS
X = zeros(N, 1);
% text = fileread("sss.txt");
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
X = exp(j*X*pi/2);
X(1:2) = 0;
X(1023:1024) = 0;
end

