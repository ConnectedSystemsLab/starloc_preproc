addpath Tool_Functions/

T = (64/15)*1e-6;
t = linspace(0,T,1024)';
Fs = 240e6;
% fd = 200e3;
pss = get_pss();
pss_local = pss(33:end);
for fd = 1e3:1e3:200e3
    figure(1);
    pss_recv =  pss_local.* exp(j*2*pi*fd*t);
    plot(abs(xcorr(pss_local, pss_recv)));
    ylim([0 1024])
    pause(.1)
end
