function [dopp_recover, res] = orbit_estimate(t, dopp_observe, F_c)
% this function recovers the continuous doppler curve as well as the most likely 
% orbital parameters from the discontinuous observed doppler curve
% input: the time vector; the observed doppler; the carrier frequency
% output: recovered doppler curve;
%         a row vector "res"
%         res(1) = estimated orbit altitude
%         res(2) = estimated orbit inclination angle (in degree)
%         res(3) = estimated time when passing the maximum elevation
%         res(4) = estimated maximum elevation 
%         res(5) = a constant frequency bias

inclination_list = [53 70 43 97.65];
h_min = 400e3; h_max = 590e3; h_step = 10e3;
ele_min = 60; ele_step = .2; ele_max = 90;
% dopp_max = 250e3; dopp_min = -250e3;
% f_spacing = 44e3;
loss_min = inf;

if isrow(t)
    t = t';
end
is_nan_idx = isnan(dopp_observe);
dopp_observe_ = dopp_observe(~is_nan_idx);

for i_idx = 1:length(inclination_list)
    i_hat = inclination_list(i_idx);
    i_hat
    for h_hat = h_min:h_step:h_max
        for t_0_hat = t(1):.5:round(t(end))
            for theta_hat = ele_min:ele_step:ele_max
                dopp_estimate = doppler_curve_2(t,h_hat,i_hat,t_0_hat,theta_hat,0,F_c);
                dopp_estimate = dopp_estimate(~is_nan_idx);
                bias = -mean(dopp_estimate)+mean(dopp_observe_);
                dopp_estimate = dopp_estimate+bias;
                loss = sum((dopp_estimate-dopp_observe_).^2);
                if loss < loss_min
                    loss_min = loss;
                    res = [h_hat i_hat t_0_hat theta_hat bias];
                end
            end
        end
    end
end

dopp_recover = doppler_curve_2(t,res(1),res(2),res(3),res(4),res(5),F_c);
end

