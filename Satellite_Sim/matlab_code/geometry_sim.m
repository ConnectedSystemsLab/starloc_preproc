c = 3e8;
f = 1e9;
lambda = c/f;
d = lambda/2;
fs = 1.01e3;
t = [0:1/fs:1-1/fs]';

ant_0 = [0 0 0];
ant_1 = [d 0 0];
ant_2 = [0 d 0];
az = 60;
el = 30;
R_0 = 5e5;
target = [R_0*cosd(el)*cosd(az) R_0*cosd(el)*sind(az) R_0*sind(el)];
R_1 = norm(target-ant_1);
R_2 = norm(target-ant_2);

% del_phi_1 = -(R_0-R_1)/lambda*2*pi;
% del_phi_2 = -(R_0-R_2)/lambda*2*pi;
target_proj = [R_0*cosd(el)*cosd(az) R_0*cosd(el)*sind(az) 0];
d_0 = norm(target_proj-ant_0);
d_1 = norm(target_proj-ant_1);
d_2 = norm(target_proj-ant_2);

%%
y_0 = exp(j*2*pi*f*(t-R_0/c));
y_1 = exp(j*2*pi*f*(t-R_1/c));
y_2 = exp(j*2*pi*f*(t-R_2/c));
del_phi_1 = angle(y_0./y_1)+1e-5;
del_phi_2 = angle(y_0./y_2)+1e-5;
plot(del_phi_1); ylim([-pi pi]);
del_phi_1_theory = -(R_0-R_1)/lambda*2*pi;
phi = atan2d(-del_phi_2, -del_phi_1);
mean(phi)
% theta = acosd(-del_phi_1*lambda/(2*pi*d*cosd(az)))