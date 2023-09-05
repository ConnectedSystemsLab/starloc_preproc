function [doppler, t] = doppler_calculation(sats, gs, F_c, duration, sampletime)
tic;
c = physconst("Lightspeed");

[az, el, ~] = aer(gs, sats);
elevation = el';
minElevation = gs.MinElevationAngle;
% visible_num = sum(elevation>=minElevation, 2);
visible_idx = elevation>minElevation;

[~, satV] = states(sats, "CoordinateFrame", "geographic");
dir = zeros(3, size(el, 2), size(el, 1));
dir(1, :, :) = (cosd(el).*cosd(az))';
dir(2, :, :) = (cosd(el).*sind(az))';
dir(3, :, :) = (-sind(el))';
doppler = -squeeze(dot(satV, dir, 1))*F_c/c;
doppler(~visible_idx) = nan;
t = linspace(0, duration/60, round(duration/sampletime)+1);

fprintf('simulation done, %d mins used\n', round(toc/60));
end

