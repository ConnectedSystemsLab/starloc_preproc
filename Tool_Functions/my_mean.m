function [y] = my_mean(x, N)
% taking the mean value for x for every N points

l_1 = length(x);
l_2 = floor(l_1/N);
y = NaN(l_2, 1);
for idx = 1:l_2
    x_window = x((idx-1)*N+1:idx*N);
    cnt = 0; sum = 0;
    for ii = 1:N
        if isnan(x_window(ii))
            continue;
        end
        cnt = cnt+1;
        sum = sum+x_window(ii);
    end
    if cnt == 0
        continue;
    end
    y(idx) = sum/cnt;
end

