% gen chirp


t = 0:1/5e6:10;
fo = 750000;
f1 = 1750000;

y = chirp(t,fo,t(end),f1,'linear',0,'complex');
% y = ((1j*sin(f1*t)+1j*sin(fo*t)+cos(f1*t)+cos(fo*t)));
% y = y/max(abs(y))*0.5;
%y = 1j*sin(f1*t)+1j*sin(f1*t)+cos(f1*t)+cos(f1*t);
%y = (rand(length(t),1)-0.5)+1j*(rand(length(t),1)-0.5);

a = write_complex_binary2(y, '/Users/ishani/UIUC/Research/LeoSat/Positioning/codebase/USRP_testing/chirp.dat');