from cProfile import label
from skyfield.api import load, wgs84
from datetime import datetime
import numpy as np
import matplotlib.pyplot as plt
import geopandas as gpd
import scipy.io as sio
import pytz
import copy
from scipy.optimize import minimize
from shapely.geometry import Point

## funcs for distance optimization 
def point_to_line_dist(x, y, m, c):
    # find the distance of point x,y from the line y = mx + c
    p2l_dist = np.abs(m*x - y + c)/np.sqrt(m**2 + 1)
    return p2l_dist

def sum_dist(point, sattrajs_coeffs):
    # find the distance of point x,y from the line y = mx + c
    x = point[0]
    y = point[1]
    dist = 0
    for line in sattrajs_coeffs:
        dist += point_to_line_dist(x, y, line[0], line[1])
    return dist

def get_observed_phase_diff_params(mat_file_path):
    dopp_track_dict = sio.loadmat(mat_file_path)['dopp_track_dict']
    sat_num = dopp_track_dict.shape[1]
    get_observed_phase_diff_params = []
    for sat_idx in range(sat_num):
        # time for tracked tones
        dopp_track = dopp_track_dict[0, sat_idx]
        t_repeat = dopp_track[:, 0].real
        t_sat_start, t_sat_end = t_repeat[0].real, t_repeat[-1].real
        del_phi_repeat_01 = np.unwrap(np.angle(dopp_track[:, 2])-np.angle(dopp_track[:, 3]))
        del_phi_repeat_12 = np.unwrap(np.angle(dopp_track[:, 3])-np.angle(dopp_track[:, 4]))
        param_01 = np.polyfit(t_repeat, del_phi_repeat_01, 1)
        param_12 = np.polyfit(t_repeat, del_phi_repeat_12, 1)
        get_observed_phase_diff_params.append([param_01, param_12])
    return np.array(get_observed_phase_diff_params)

def get_candidate_locs(start_time, time_arr, tle_path, search_dist_bound=150, fig_pointer=None):
    ts = load.timescale()
    satellites = load.tle_file(tle_path)
    time_arr = np.array(time_arr)
    sat_visible_time_arr = ts.utc(start_time.year, start_time.month, start_time.day, 
                            start_time.hour, start_time.minute, start_time.second+start_time.microsecond/1e6+time_arr)
    gs_superset = []
    sat_superset = []
    for time in sat_visible_time_arr:
        gs = []
        sat_ = []
        for sat in satellites:
            geocentric = sat.at(time)
            lat, lon = wgs84.latlon_of(geocentric)
            #only consider locations in in USA
            if lat.degrees > 24.396308 and lat.degrees < 49.384358 and lon.degrees > -125.0 and lon.degrees < -66.93457: # setting boundaries for USA
                gs.append([lat.degrees, lon.degrees])
                sat_.append(sat)
        gs_superset.append(gs)
        sat_superset.append(sat_)

    
    ## Forming Candidate Location Clusters
    ## =============================================================================
    # start with the first set of ground stations and satellites obtained at the first time in time_arr
    gs_subset_ = gs_superset[0]
    sat_set_0 = sat_superset[0]
    # these points will form initial group
    gs_groups = [[[gs_subset_[i][0], gs_subset_[i][1]]] for i in range(len(gs_subset_))]
    sat_groups = [[sat_set_0[i]] for i in range(len(sat_set_0))]

    ## from each subset, only append points at 150km distance to the centroid of each group at each step
    for subset_idx,gs_subset in enumerate(gs_superset[1:]):
        gs_subset = np.array(gs_subset)
        # print('GS Subset:', gs_subset.shape)
        gs_groups_ = copy.deepcopy(gs_groups)
        for i,group in enumerate(gs_groups):
            # get distance of each point in a group from the current group centroid
            group = np.array(group)
            group_curr_centroid = np.mean(group, axis=0) #centroid of elements in group
            # print('group_curr_centroid:', group_curr_centroid.shape)
            lat1 = np.deg2rad(group_curr_centroid[0])
            lon1 = np.deg2rad(group_curr_centroid[1])
            lat2 = np.deg2rad(gs_subset[:,0])
            lon2 = np.deg2rad(gs_subset[:,1])
            dist = np.arccos(np.sin(lat1)*np.sin(lat2)+np.cos(lat1)*np.cos(lat2)*np.cos(lon2-lon1))*6371
            # print('Dist:', dist.shape)
            # get the minimum distance
            min_dist, min_dist_idx = np.min(dist), np.argmin(dist)
            # print('Min Dist:', min_dist, "Point", point, "Coordinates:", gs_subset[min_dist_idx])
            # if the minimum distance is less than 100 km, add the point to the current centroid, else add the point as a new centroid
            if min_dist < search_dist_bound:
                gs_groups_[i].append([gs_subset[min_dist_idx][0], gs_subset[min_dist_idx][1]])
                sat_groups[i].append(sat_superset[subset_idx+1][min_dist_idx])
            else:
                gs_groups_.append([[gs_subset[min_dist_idx][0], gs_subset[min_dist_idx][1]]])
                sat_groups.append([sat_superset[subset_idx+1][min_dist_idx]])

        gs_groups = copy.deepcopy(gs_groups_)
    print('Initial number of candidate location clusters:', len(gs_groups))

    ## Removing clusters that are not possible and plotting the candidate location clusters
    ## =============================================================================
    world = gpd.read_file(gpd.datasets.get_path('naturalearth_lowres'))
    if fig_pointer is None:
        fig, ax = plt.subplots(1, 1, figsize=(10, 6))
    else:
        fig, ax = fig_pointer[0], fig_pointer[1]
    world.plot(ax=ax)
    # only show USA
    ax.set_xlim([-125.0, -66.93457])
    ax.set_ylim([24.396308, 49.384358])
    color = ['red', 'blue', 'grey', 'yellow', 'orange', 'purple', 'pink', 'black']

    possible_groups = 0 
    remove_set = []  
    coarse_gs = []
    for i,sets in enumerate(gs_groups): # sets == group/cluster 
        # get sets that are not possible because they do not see satellites at all times in time_arr
        if len(sets) < len(time_arr):
            remove_set.append(i)
            continue
        # print(i, 'Sets:', len(sets))
        possible_groups += 1
        sets = np.array(sets)
        ax.scatter(sets[:,1], sets[:,0], c=color[int(i%len(color))], s=5)
        # also plot the centroid
        centroid = np.mean(sets, axis=0)
        coarse_gs.append(centroid) # This is the array of possible coarse locations of ground receiver
        ax.scatter(centroid[1], centroid[0], c='purple', marker='x', s=10)

    print('Possible:', possible_groups)
    # finally remove the sets that are not possible
    gs_groups = [gs_groups[i] for i in range(len(gs_groups)) if i not in remove_set]
    sat_groups = [sat_groups[i] for i in range(len(sat_groups)) if i not in remove_set]

    ## Plotting satellite trajectory lines for sats in each group. 
    ##Also, finding the point on earth that minimizes the distance to the satellite trajectory lines
    for gp_idx,group in enumerate(sat_groups):
        lines_coeffs = []
        sats_name_arr = []
        for i,sat in enumerate(group):
            sats_name_arr.append(sat.name)
            # get satellite subpoints around 10 seconds of the time of highest elevation at 0.1 sec steps
            time_of_highest_elevation = sat_visible_time_arr[i].utc_datetime()
            span = np.arange(-5, 5, 0.1)
            single_sat_time_arr = ts.utc(time_of_highest_elevation.year, time_of_highest_elevation.month, time_of_highest_elevation.day, 
                time_of_highest_elevation.hour, time_of_highest_elevation.minute, time_of_highest_elevation.second+time_of_highest_elevation.microsecond/1e6+span)
            subpoints = wgs84.latlon_of(sat.at(single_sat_time_arr))
            x = subpoints[1].degrees # longitudes
            y = subpoints[0].degrees # latitudes
            # plt.plot(x, y, '--', color='black')
            plt.text(x[-1], y[-1], sat.name, fontsize=5, color='black')
            # polyfit line to x,y
            sat_traj_line = np.polyfit(x, y, 1)
            # print('Satellite Trajectory Line slope:', sat_traj_line[0], "Intercept:", sat_traj_line[1])
            # find a point on earth that minimizes the distance to the satellite trajectory lines
            lines_coeffs.append(sat_traj_line)

        #minimize distance to the trajectroy lines
        init_point = np.mean(gs_groups[gp_idx], axis=0)
        res = minimize(sum_dist, [init_point[1]-1, init_point[0]-1], args=(lines_coeffs), method = 'Nelder-Mead')
        print("Centroid of group ", gp_idx, ":", coarse_gs[gp_idx])
        print('Point that minimizes distance to each satellite trajectory :', res.x[1], res.x[0])
        
        #plot the point
        ax.scatter(res.x[0], res.x[1], c='yellow', marker='x', s=10)
        print('sats in group:', sats_name_arr)
        print("=====================================================================")

    return gs_groups, coarse_gs, sat_groups
        
def get_candidate_locs_jida(start_time, time_arr, is_middle_arr, tle_path, search_dist_bound=150, fig_pointer=None):
    # this makes sure every single possible cluster can be found
    world = gpd.read_file(gpd.datasets.get_path('naturalearth_lowres'))
    us_boundary = world[world['iso_a3'] == 'USA']

    ts = load.timescale()
    satellites = load.tle_file(tle_path)
    time_arr = np.array(time_arr)
    sat_visible_time_arr = ts.utc(start_time.year, start_time.month, start_time.day, start_time.hour, start_time.minute, start_time.second+start_time.microsecond/1e6+time_arr)
    gs_superset = []
    sat_superset = []
    for time in sat_visible_time_arr:
        gs = []
        sat_ = []
        for sat in satellites:
            geocentric = sat.at(time)
            lat, lon = wgs84.latlon_of(geocentric)
            #only consider locations in in USA
            # if lat.degrees > 24.396308 and lat.degrees < 49.384358 and lon.degrees > -125.0 and lon.degrees < -66.93457: # setting boundaries for USA
            point = Point(lon.degrees, lat.degrees)
            if point.within(us_boundary.geometry.iloc[0]):
                gs.append([lat.degrees, lon.degrees])
                # sat_.append(sat.name)
                sat_.append(sat)
        gs_superset.append(gs)
        sat_superset.append(sat_)
    
    num_periods = len(sat_visible_time_arr)
    len_list = [len(gs_superset[i]) for i in range(num_periods)]
    # start with the first set of ground stations and satellites obtained at the first time in time_arr
    group_mat = np.zeros((len_list[0], 1))
    for i in range(len_list[0]):
        group_mat[i, 0] = i
    group_mat = group_mat.astype(int)

    for subset_idx, len_subset in enumerate(len_list[1:]):
        cur_super_set = np.array(gs_superset[1+subset_idx])
        cur_group_len = np.size(group_mat, 1)
        cur_group_num = np.size(group_mat, 0)
        group_mat_ = np.array([]).reshape(0, cur_group_len+1)
        for i in range(len_subset):
            lat2 = np.deg2rad(cur_super_set[i, 0])
            lon2 = np.deg2rad(cur_super_set[i, 1])
            
            # search for all previous points in the group, find the maximum distance of the new point from all of the previous points
            dist = np.zeros(cur_group_num)
            for j in range(cur_group_len):
                superset_j = np.array(gs_superset[j])
                lat1 = np.deg2rad(superset_j[group_mat[:, j].astype(int), 0])
                lon1 = np.deg2rad(superset_j[group_mat[:, j].astype(int), 1])
                dist = np.maximum(dist, np.arccos(np.sin(lat1)*np.sin(lat2)+np.cos(lat1)*np.cos(lat2)*np.cos(lon2-lon1))*6371)
            prev_row_idxs = np.where(dist < search_dist_bound)[0]
            for prev_row in prev_row_idxs:
                group_mat_ = np.vstack((group_mat_, np.hstack((group_mat[prev_row], i))))
        
        group_mat = group_mat_.astype(int)

    print('Initial number of candidate location clusters:', np.size(group_mat, 0))

    if fig_pointer is None:
        fig, ax = plt.subplots(1, 1, figsize=(10, 6))
    else:
        fig, ax = fig_pointer[0], fig_pointer[1]
    world.plot(ax=ax)
    # only show USA
    ax.set_xlim([-125.0, -66.93457])
    ax.set_ylim([24.396308, 49.384358])
    color = ['red', 'blue', 'grey', 'yellow', 'orange', 'purple', 'pink', 'black']

    gs_groups = []
    sat_groups = []
    # coarse_gs = []
    for i in range(np.size(group_mat, 0)):
        gs_group = []
        sat_group = []
        for j in range(np.size(group_mat, 1)):
            gs_group.append(gs_superset[j][group_mat[i, j]])
            sat_group.append(sat_superset[j][group_mat[i, j]])
        gs_groups.append(gs_group)
        sat_groups.append(sat_group)
        gs_group = np.array(gs_group)
        # ax.scatter(gs_group[:,1], gs_group[:,0], c=color[int(i%len(color))], s=5)
        # centroid = np.mean(gs_group, axis=0)
        # coarse_gs.append(centroid)
        # ax.scatter(centroid[1], centroid[0], c='purple', marker='x', s=10)

    # check using intersection
    num_possible = 0
    is_possible = np.zeros(np.size(group_mat, 0))
    coarse_gs = []
    for gp_idx, group in enumerate(sat_groups):
        # check whether there's repeated satellites, if so, continue
        if len(group) != len(set(group)):
            continue
        coeff_mat = np.array([]).reshape(0, 2)
        coeff_vec = np.array([]).reshape(0, 1)
        for i, sat in enumerate(group):
            if not is_middle_arr[i]:
                continue
            # get satellite subpoints around 10 seconds of the time of highest elevation at 0.1 sec steps
            time_of_highest_elevation = sat_visible_time_arr[i].utc_datetime()
            span = np.arange(-1, 1, 0.2)
            single_sat_time_arr = ts.utc(time_of_highest_elevation.year, time_of_highest_elevation.month, time_of_highest_elevation.day, 
                time_of_highest_elevation.hour, time_of_highest_elevation.minute, time_of_highest_elevation.second+time_of_highest_elevation.microsecond/1e6+span)
            subpoints = wgs84.latlon_of(sat.at(single_sat_time_arr))
            x = subpoints[1].degrees # longitudes
            y = subpoints[0].degrees # latitudes
            sat_traj_line = np.polyfit(x, y, 1)
            # index where span = 0
            idx = len(span) // 2
            k_i_ = sat_traj_line[0]
            k_i = -1/k_i_
            m_i = y[idx] - k_i*x[idx]
            coeff_mat = np.vstack((coeff_mat, np.array([k_i, -1])))
            coeff_vec = np.vstack((coeff_vec, np.array([-m_i])))
        x_star = np.linalg.inv(coeff_mat.T@coeff_mat)@coeff_mat.T@coeff_vec
        # calculate the error
        error = np.linalg.norm(coeff_mat@x_star - coeff_vec)
        if error / np.sum(is_middle_arr) < .3:
            num_possible += 1
            is_possible[gp_idx] = 1
            coarse_gs.append(np.array([x_star[1][0], x_star[0][0]]))
            ax.scatter(x_star[0][0], x_star[1][0], c='purple', marker='x', s=20)
            for_plotting = x_star
    ax.scatter(for_plotting[0][0], for_plotting[1][0], c='purple', marker='x', s=20, label='Candidate Locations')

    print('Possible:', num_possible)
    sat_groups = [sat_groups[i] for i in range(np.size(group_mat, 0)) if is_possible[i]]
    gs_groups = [gs_groups[i] for i in range(np.size(group_mat, 0)) if is_possible[i]]
    
    ## Plotting satellite trajectory lines for sats in each group. 
    ##Also, finding the point on earth that minimizes the distance to the satellite trajectory lines
    for gp_idx, group in enumerate(sat_groups):
        lines_coeffs = []
        sats_name_arr = []
        for i,sat in enumerate(group):
            sats_name_arr.append(sat.name)
            # get satellite subpoints around 10 seconds of the time of highest elevation at 0.1 sec steps
            time_of_highest_elevation = sat_visible_time_arr[i].utc_datetime()
            span = np.arange(-5, 5, 0.1)
            single_sat_time_arr = ts.utc(time_of_highest_elevation.year, time_of_highest_elevation.month, time_of_highest_elevation.day, 
                time_of_highest_elevation.hour, time_of_highest_elevation.minute, time_of_highest_elevation.second+time_of_highest_elevation.microsecond/1e6+span)
            subpoints = wgs84.latlon_of(sat.at(single_sat_time_arr))
            x = subpoints[1].degrees # longitudes
            y = subpoints[0].degrees # latitudes
            # plt.plot(x, y, '--', color='black')
            # plt.text(x[-1], y[-1], sat.name, fontsize=5, color='black')
            # polyfit line to x,y
            sat_traj_line = np.polyfit(x, y, 1)
            # print('Satellite Trajectory Line slope:', sat_traj_line[0], "Intercept:", sat_traj_line[1])
            # find a point on earth that minimizes the distance to the satellite trajectory lines
            lines_coeffs.append(sat_traj_line)

        #minimize distance to the trajectroy lines
        # init_point = np.mean(gs_groups[gp_idx], axis=0)
        # res = minimize(sum_dist, [init_point[1]-1, init_point[0]-1], args=(lines_coeffs), method = 'Nelder-Mead')
        print("Centroid of group ", gp_idx, ":", coarse_gs[gp_idx])
        # print('Point that minimizes distance to each satellite trajectory :', res.x[1], res.x[0])
        
        #plot the point
        # ax.scatter(res.x[0], res.x[1], c='yellow', marker='x', s=10)
        print('sats in group:', sats_name_arr)
        print("=====================================================================")

    return gs_groups, coarse_gs, sat_groups
            

def get_phase_diff_params_allsatsingroups(coarse_gs, satdictlist_for_each_gs, time_arr, orientation_dict=None, receiver_param_dict=None):
    # calc phase diff 01, 02, 12 for each satellite in each gs group

    if receiver_param_dict is not None:
        r = receiver_param_dict['r']
        d = receiver_param_dict['d']
        fc = receiver_param_dict['fc']
        lam = 3e8/fc
    else:   
        r = 1e10
        d = 13.25e-2
        fc = 11.325e9
        lam = 3e8/fc

    if orientation_dict is not None:
        alpha = orientation_dict['alpha']
        beta = orientation_dict['beta']
        gamma = orientation_dict['gamma']
    else:
        alpha = 0.1
        beta = 0.23
        gamma = 1.2

    phasediffdict_for_each_gs = [{} for i in range(len(coarse_gs))]
    phase_diff_param = [{} for i in range(len(coarse_gs))]

    for gs_idx,gs in enumerate(coarse_gs):
        for t_idx,time in enumerate(time_arr):
            print('GS', gs_idx, 'Time', time)
            phasediffdict_for_each_gs[gs_idx][time] = {}
            phase_diff_param[gs_idx][time] = {}
            
            for sat in satdictlist_for_each_gs[gs_idx][time]:
                print('GS', coarse_gs[gs_idx], 'Time', time, 'Sat:', sat)
                # print('Sat Dopp Dict:', len(satdictlist_for_each_gs[gs_idx][time]))
                dopp = satdictlist_for_each_gs[gs_idx][time][sat][0]
                az_gt = satdictlist_for_each_gs[gs_idx][time][sat][1]
                el_gt = satdictlist_for_each_gs[gs_idx][time][sat][2]
                
                sat_loc_3d = r*np.array([np.cos(np.deg2rad(el_gt))*np.sin(np.deg2rad(az_gt)), 
                                        np.cos(np.deg2rad(el_gt))*np.cos(np.deg2rad(az_gt)), 
                                        np.sin(np.deg2rad(el_gt))])
                
                loc_1 = np.array([[0, 0, 0]]).T
                loc_0 = np.array([[0, -d, 0]]).T
                loc_2 = np.array([[d, 0, 0]]).T

                alpha = 0.1
                R_alpha = np.array([[np.cos(np.deg2rad(alpha)), -np.sin(np.deg2rad(alpha)), 0],
                                    [np.sin(np.deg2rad(alpha)), np.cos(np.deg2rad(alpha)), 0],
                                    [0, 0, 1]])
                beta = 0.23
                R_beta = np.array([[np.cos(np.deg2rad(beta)), 0, np.sin(np.deg2rad(beta))],
                                    [0, 1, 0],
                                    [-np.sin(np.deg2rad(beta)), 0, np.cos(np.deg2rad(beta))]])
                gamma = 1.2
                R_gamma = np.array([[1, 0, 0],
                                    [0, np.cos(np.deg2rad(gamma)), -np.sin(np.deg2rad(gamma))],
                                    [0, np.sin(np.deg2rad(gamma)), np.cos(np.deg2rad(gamma))]])

                R = R_alpha@R_beta@R_gamma
                range_1 = np.linalg.norm((sat_loc_3d-(R@loc_1)).T, axis=1)
                range_0 = np.linalg.norm((sat_loc_3d-(R@loc_0)).T, axis=1)
                range_2 = np.linalg.norm((sat_loc_3d-(R@loc_2)).T, axis=1)
                del_phi_01_gt = -(range_0-range_1)/lam*2*np.pi
                del_phi_02_gt = -(range_0-range_2)/lam*2*np.pi
                del_phi_12_gt = -(range_1-range_2)/lam*2*np.pi
                phasediffdict_for_each_gs[gs_idx][time][sat] = [del_phi_01_gt, del_phi_02_gt, del_phi_12_gt]
                x = np.arange(0,len(del_phi_01_gt))
                m_01, c_01 = np.polyfit(x, del_phi_01_gt, 1)
                m_12, c_12 = np.polyfit(x, del_phi_12_gt, 1)
                phase_diff_param[gs_idx][time][sat] = [[m_01, c_01], [m_12, c_12]]
                    
    return phasediffdict_for_each_gs, phase_diff_param

def find_best_coarse_gs(coarse_gs, time_arr, satdictlist_for_each_gs, phase_diff_param, observed_phase_diff_param):
    min_param_diff_pertime_each_gs = [[] for i in range(len(coarse_gs))]
    min_param_diff_sat_pertime_each_gs = [[] for i in range(len(coarse_gs))]
    for gs_idx,gs in enumerate(coarse_gs):
        for t_idx,time in enumerate(time_arr):
            min_param_diff = np.inf
            min_param_diff_sat = ''
            for sat in satdictlist_for_each_gs[gs_idx][time]:
                m_01, c_01 = phase_diff_param[gs_idx][time][sat][0]
                m_12, c_12 = phase_diff_param[gs_idx][time][sat][1]
                m_01_obs, c_01_obs = observed_phase_diff_param[t_idx][0]
                m_12_obs, c_12_obs = observed_phase_diff_param[t_idx][1]
                param_diff = np.abs(m_01-m_01_obs)+np.abs(m_12-m_12_obs)
                if param_diff < min_param_diff:
                    min_param_diff = param_diff
                    min_param_diff_sat = sat
            if min_param_diff_sat == '':
                print('No satellite found for GS:', gs, ' at Time:', time)
            min_param_diff_pertime_each_gs[gs_idx].append(min_param_diff)
            min_param_diff_sat_pertime_each_gs[gs_idx].append(min_param_diff_sat)

    min_param_diff_pertime_each_gs = np.array(min_param_diff_pertime_each_gs)
    min, argmin = np.min(np.sum(min_param_diff_pertime_each_gs, axis=1)), np.argmin(np.sum(min_param_diff_pertime_each_gs, axis=1))
    best_coarse_gs_candidate = coarse_gs[argmin]
    best_coarse_gs_candidate_idx = argmin
    print("Best GS:", best_coarse_gs_candidate, "Min Param Diff:", min)
    print("=====================================================================")
    print("All other GS centroids and their respective min param diff:\n")
    for gs_idx in range(len(coarse_gs)):
        print(coarse_gs[gs_idx], np.sum(min_param_diff_pertime_each_gs, axis=1)[gs_idx])

    return best_coarse_gs_candidate, best_coarse_gs_candidate_idx, min_param_diff_pertime_each_gs, min_param_diff_sat_pertime_each_gs