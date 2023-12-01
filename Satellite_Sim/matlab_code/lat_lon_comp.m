TLE = "../../AoA_Sim/tles/11_5/STARLINK-5718.tle";
t = datetime(2023,11,5,0,0,0) + hours(5);
sc = satelliteScenario(t,t,1);
sat = satellite(sc, TLE);
lat = +40.11389690596162;
lon = -88.22484814695467;
gs = groundStation(sc, "Latitude", lat, "Longitude", lon);
[az, el, ~] = aer(gs, sat);
[grid_x, grid_y, loss] = generate_loss_func(sat, sc, az, el);
surf(grid_x, grid_y, loss)
% save "loss_fig.mat" grid_x grid_y loss;

function [X, Y, loss] = generate_loss_func(sat, sc, az_gt, el_gt)
% lat = [-90:5:90]';
% lon = [-180:10:180]';
lat = linspace(38, 42, 40);
lon = linspace(-90, -86, 40);
[X, Y] = meshgrid(lat, lon);
loss = zeros(length(X), length(Y));
for ii = 1:length(X)
    for jj = 1:length(Y)
        la_ = lat(ii);
        lo_ = lon(jj);
        gs = groundStation(sc, "Latitude", la_, "Longitude", lo_);
        [az_, el_, ~] = aer(gs, sat);
        loss(ii, jj) = norm([az_ el_]-[az_gt el_gt]);
    end
end
end