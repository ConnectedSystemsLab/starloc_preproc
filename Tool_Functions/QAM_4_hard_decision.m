function [info, d] = QAM_4_hard_decision(points)
num = length(points);
info = zeros(num, 1);
d = 0;
for idx = 1:num
    re = real(points(idx));
    im = imag(points(idx));
    if re > 0 && im > 0
        info(idx) = 0;
        d = d+abs(points(idx)-(1+j)/sqrt(2));
    elseif re < 0 && im > 0
        info(idx) = 1;
        d = d+abs(points(idx)-(-1+j)/sqrt(2));
    elseif re > 0 && im < 0
        info(idx) = 3;
        d = d+abs(points(idx)-(1-j)/sqrt(2));
    else
        info(idx) = 2;
        d = d+abs(points(idx)-(-1-j)/sqrt(2));
    end
end
d = d/num;
end

