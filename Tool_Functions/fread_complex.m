function [y, is_end] = fread_complex(f, num_points)
% read complex data points from a .dat file

val = fread(f, [num_points*2 1], 'float');
y = val(1:2:end) + val(2:2:end)*1j;
is_end = isempty(val);
if is_end
    fclose(f);
end
end