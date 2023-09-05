function [doppler, inclination, h, t_0, el_max, b] = doppler_curve_1(gs, sat, t, F_c)

c = physconst("Lightspeed");
r_E = 6378e3;
omega_E = 7.2921150e-5;
b = 0;

sat_coordinate = states(sat);
r_ = sqrt(sum(sat_coordinate.^2, 1));
h = mean(r_-r_E);
r = mean(r_);
[~, el, ~] = aer(gs, sat);
[el_max, t_0_idx] = max(el);
t_0 = t(t_0_idx);

orbit_ele = orbitalElements(sat);
inclination = orbit_ele.Inclination;

subsat_unit_vec = sat_coordinate./r_;
unit_vec_1 = subsat_unit_vec(:, 1);
numSamp = length(t);
sampleTime = t(2)-t(1);
psi = zeros(numSamp, 1);
for idx = 1:numSamp
    psi(idx) = real(acos(dot(unit_vec_1, subsat_unit_vec(:, idx))));
    % psi(idx) = psi(idx)-(idx-1)*omega_E*cosd(inclination)*sampleTime/2;
end
psi = psi-psi(t_0_idx);

omega_s = mean(diff(psi))/sampleTime;
omega_F = omega_s-omega_E*cosd(inclination);
psi = omega_F*t;
psi = psi-psi(t_0_idx);

doppler = r_E*r*sin(psi)*cos(acos(r_E/r*cosd(el_max))-deg2rad(el_max))*omega_F;
doppler = doppler ./ sqrt(r_E^2+r^2-2*r_E*r*cos(psi)*cos(acos(r_E/r*cosd(el_max))-deg2rad(el_max)));
doppler = -F_c/c*doppler;

end