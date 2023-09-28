function [CSS] = get_CSS()

load CSS.mat;   % {0,1,2,3}
CSS = exp(j*(pi/2*CSS+pi/4));
end

