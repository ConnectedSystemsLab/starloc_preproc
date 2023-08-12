function [res] = phase_avg(phase_set)
% calculate the average value of a set of phase
% ref: https://vicrucann.github.io/tutorials/phase-average/

x = sum(cos(phase_set));
y = sum(sin(phase_set));
res = atan2(y, x);

end

