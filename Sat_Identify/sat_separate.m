addpath ../Tool_Functions/;
load dopp_list.mat;

sat_num = 9;
data_idx = find(~isnan(dopp_list));
sat_1_idx = 4094:7061;
sat_2_idx = 7062:8640;
sat_3_idx = 10059:11573;
sat_4_idx = 16066:17617;
sat_5_idx = 29659:31115;
sat_6_idx = 31142:34121;
sat_7_idx = 44601:49099;
sat_8_idx = 41113:60634;
sat_9_idx = 58108:59529;

dopp_1 = dopp_list(sat_1_idx);
dopp_2 = dopp_list(sat_2_idx);
dopp_3 = dopp_list(sat_3_idx);
dopp_3(dopp_3>54e3) = NaN;
dopp_4 = dopp_list(sat_4_idx);
dopp_5 = dopp_list(sat_5_idx);
dopp_6 = dopp_list(sat_6_idx);
dopp_7 = dopp_list(sat_7_idx);
dopp_7(dopp_7>205100) = NaN;
dopp_8 = dopp_list(sat_8_idx);
dopp_8(intersect([3476:4456], (find(dopp_8<208e3))))=NaN;
dopp_8(intersect([6553:7987], (find(dopp_8<170e3))))=NaN;
dopp_8(intersect([16900:18600], (find(dopp_8>-2500))))=NaN;
dopp_9 = dopp_list(sat_9_idx);
dopp_9(intersect([1:120], (find(dopp_9<0))))=NaN;

figure(1); hold on;
for sat_idx = 1:sat_num
    index = eval("sat_"+num2str(sat_idx)+"_idx");
    t = [index(1):index(end)]'*0.01;
    dopp = eval("dopp_"+num2str(sat_idx));
    plot(t, dopp ,LineWidth=1.5);
end

figure(2); hold on;
for sat_idx = 1:sat_num
    sat_idx
    index = eval("sat_"+num2str(sat_idx)+"_idx");
    dopp = eval("dopp_"+num2str(sat_idx));
    dopp_dsamp = my_mean(dopp, 100);
    t = [0:length(dopp_dsamp)-1]'*1+index(1)*0.01;
    dopp_recover = orbit_estimate(t, dopp_dsamp, 11.575e9);
    plot(t, dopp_recover);
end