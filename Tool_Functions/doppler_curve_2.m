function [doppler] = doppler_curve_2(t, h, inclination, t_0, el_max, b, F_c)

c = physconst("Lightspeed");
r_E = 6378e3;
omega_E = 7.2921150e-5;
G = 6.6743e-11;
M = 5.9722e24;

r = r_E+h;
omega_F = sqrt(G*M/r^3)-omega_E*cosd(inclination);
psi = omega_F*(t-t_0);

doppler = r_E*r*sin(psi)*cos(acos(r_E/r*cosd(el_max))-deg2rad(el_max))*omega_F;
doppler = doppler ./ sqrt(r_E^2+r^2-2*r_E*r*cos(psi)*cos(acos(r_E/r*cosd(el_max))-deg2rad(el_max)));
doppler = -F_c/c*doppler;

doppler = doppler+b;

end