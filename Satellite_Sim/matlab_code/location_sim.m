lat = linspace(39,42,11)';
lon = linspace(-89,-86,11)';
minElevation = 60;
dopp = [];
for idx = 1:11
    gs = groundStation(sc, "Name", "1", "Latitude", lat(idx), ...
    "Longitude", lon(idx), "MinElevationAngle", minElevation);
    [az, el, ~] = aer(gs, sat);
    elevation = el';
    visible_num = sum(elevation>=minElevation, 2);
    visible_idx = elevation>minElevation;
    
    [~, satV] = states(sat, "CoordinateFrame", "geographic");
    dir = zeros(3, size(el, 2), size(el, 1));
    dir(1, :, :) = (cosd(el).*cosd(az))';
    dir(2, :, :) = (cosd(el).*sind(az))';
    dir(3, :, :) = (-sind(el))';
    doppler = -squeeze(dot(satV, dir, 1))*F_c/c;
    doppler(~visible_idx) = nan;
    dopp = [dopp; doppler];
    
    % fprintf('simulation done, %d mins used\n', round(toc/60));
    clear satV; clear dir;
end

figure; hold on;
for idx = 1:11
plot(dopp(idx,:))
end