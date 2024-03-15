from hmac import new
from math import inf
from telnetlib import DO
from tracemalloc import stop
from scipy import io as sio
from scipy.optimize import linear_sum_assignment
import numpy as np
import matplotlib.pyplot as plt
from turtle import st
from skyfield.api import load, wgs84
from numpy import array2string
from datetime import datetime, timedelta
import os
from scipy import io as sio
import pytz
from utils.ephemeris import EphemerisLoader
from tqdm import tqdm

class DopplerTrack(object):
    num_tracks = 0
    def __init__(self, point) -> None:
        self.track_id = DopplerTrack.num_tracks
        DopplerTrack.num_tracks += 1
        self.track_points = np.array([point])
        self.slope = None
        self.intercept = None

    def update(self, point) -> None:
        # add peak to the track_points if there are elements in peak
        self.track_points = np.concatenate((self.track_points, np.array([point])), axis=0)
        self.slope, self.intercept = np.polyfit(self.track_points[:, 0], self.track_points[:, 1], 1)
        # self.linear_model.fit(np.array([self.track_points[:, 0]]), np.array([self.track_points[:, 1]]))
    
    def fit_err(self, point):
        if np.size(self.track_points, 0) < 6:
            return inf
        pred = self.slope * point[0] + self.intercept
        return np.abs(pred - point[1])

def connect_doppler(date):
    peak_file_path = date + "/peaks.mat"
    track_dicts = []
    for lnb_idx in range(3):
        peak_array = sio.loadmat(peak_file_path)['peak_array_'+str(lnb_idx)]

        is_empty = True
        time = 0
        step = 0.5
        tmp = np.mean(peak_array, axis=0)
        fbin_hardware = np.argmax(np.mean(peak_array, axis=0))
        for i in range(np.shape(peak_array)[0]):
            t_i = time+step * i
            point_t_i = peak_array[i, :]
            none_zeros_freq_bin = [idx for idx, val in enumerate(point_t_i) if val != 0 and idx != fbin_hardware]
            if len(none_zeros_freq_bin) == 0:
                continue
            # add the freq_bin by 1 since index starts from 0 in Python
            for idx, val in enumerate(none_zeros_freq_bin):
                none_zeros_freq_bin[idx] += 1
            
            arr_t_i = np.vstack((t_i * np.ones(len(none_zeros_freq_bin)), none_zeros_freq_bin)).T
            if is_empty:
                point_array = arr_t_i
                is_empty = False
            else:
                point_array = np.concatenate((point_array, arr_t_i), axis=0)

        # plot the discrete points
        plt.plot(point_array[:, 0], point_array[:, 1], '.')
        # plt.show()

        curr_tracks = []
        all_tracks = []
        for i in range(np.size(point_array, 0)):
            cur_point = point_array[i, :]

            if len(curr_tracks) == 0:
                # create new tracks for the first point
                trk = DopplerTrack(cur_point)
                curr_tracks.append(trk)
            else:
                # search the existing tracks which the new point might belong to
                if_assign_to_existing_track = False
                potential_trk = []
                for trk in curr_tracks:
                    last_point_in_trk = trk.track_points[-1, :]
                    last_point_t = last_point_in_trk[0]
                    last_point_f = last_point_in_trk[1]
                    # if the new point is close enough
                    if (cur_point[1] <= last_point_f) and ((cur_point[0] <= last_point_t + 10 and cur_point[1] >= last_point_f - 5)):
                        # trk.update(cur_point)
                        if_assign_to_existing_track = True
                        potential_trk.append(trk)
                        # break
                if if_assign_to_existing_track:
                    last_point_t = [val.track_points[-1, :][0] for idx, val in enumerate(potential_trk)]
                    trk_most_probable = potential_trk[np.argmax(last_point_t)]
                    trk_most_probable.update(cur_point)
                else:
                    trk = DopplerTrack(cur_point)
                    curr_tracks.append(trk)

        track_dict = {}
        for track in curr_tracks:
            track_dict["track_"+str(track.track_id)] = track.track_points
            # print(track.track_id, ":", track.track_points, "\n")

        for track in curr_tracks:
            col = (np.random.random(), np.random.random(), np.random.random())
            # plt.scatter(track.track_points[:, 0], track.track_points[:, 1], marker='.', color=col)
            plt.plot(track.track_points[:, 0], track.track_points[:, 1], color=col)
        plt.title("Doppler Track for lnb-"+str(lnb_idx))
        plt.show()
        track_dicts.append(track_dict)
    return track_dicts

def doppler_sim(date, path, fc, t_start, t_stop, t_step):
    min_ele = 70 # degrees
    satellites = load.tle_file(path) # either use path to tle or directly fetch latest tle from the url
    print("number of Starlink satellites loaded " + str(len(satellites)))
    open_satfile_list = []
    siebel_lat, siebel_lon = (+40.11389690596162, -88.22484814695467)
    siebel = wgs84.latlon(siebel_lat, siebel_lon) 
    farm_lat, farm_lon = (+40.072969193609126, -88.20958051030674)
    farm = wgs84.latlon(farm_lat, farm_lon, elevation_m=218)
    # gs =  siebel
    gs = farm

    # convert from timestamp to datetime
    # add five hours to convert from CST to UTC
    t_start += 6*3600
    t_stop += 6*3600
    d_1 = datetime.fromtimestamp(t_start)
    t_start = datetime(d_1.year, d_1.month, d_1.day, d_1.hour, d_1.minute, d_1.second, tzinfo=pytz.UTC)

    d_2 = datetime.fromtimestamp(t_stop)
    t_stop = datetime(d_2.year, d_2.month, d_2.day, d_2.hour, d_2.minute, d_2.second, tzinfo=pytz.UTC)


    sat_dopp_dict = {}
    sat_cnt = 0
    for satellite in satellites:
        sat_cnt += 1
        name = satellite.name
        # print sat_cnt and its name
        print(sat_cnt,name)
        is_visible, t_list, dopp, az, el, _ = calc_doppler(satellite, gs, t_start, t_stop, 1/t_step, fc, min_ele)
        if is_visible:
            sat_dopp_dict[name] = np.vstack((dopp, az, el))

    return sat_dopp_dict, t_list

# Calculate doppler shift given satellite, ground station, start time, stop time, sampling frequency, and carrier frequency
def calc_doppler(sat, gs, start_time, stop_time, fs, fc=11.325e9, min_ele=60):
    c = 299792458
    ts = load.timescale()
    t = ts.utc(start_time)
    duration = stop_time-start_time
    n_list = np.arange(0, fs*duration.total_seconds() + 1, 1).astype(int)
    
    doppler_shift = np.empty(len(n_list))
    azimuth = np.empty(len(n_list))
    elevation = np.empty(len(n_list))
    range_ = np.empty(len(n_list))

    sat_ele_max = -inf
    for n in n_list:
        dist = (sat-gs).at(t)
        t = ts.utc(t.utc_datetime()+timedelta(milliseconds=1000/fs))
        alt, az, distance = dist.altaz() 
        if alt.degrees > sat_ele_max:
            sat_ele_max = alt.degrees
        _, _, the_range, _, _, range_rate = dist.frame_latlon_and_rates(gs)
        doppler_shift[n] = -fc*range_rate.km_per_s*1000/c
        if alt.degrees < min_ele-10:
            doppler_shift[n] = np.nan
        azimuth[n] = az.degrees
        elevation[n] = alt.degrees
        range_[n] = the_range.m
        
    t_list = n_list/fs
    is_visible = sat_ele_max > min_ele

    return is_visible, t_list, doppler_shift, azimuth, elevation, range_

def calc_doppler_eph(zip_folder_path, sat_id, gs, start_time, stop_time, fs, fc=11.325e9, min_ele=60):
    '''
    param: zip_folder_path: path to the folder containing the ephemeris files
    param: sat_id: satellite id
    param: gs: ground station object
    param: start_time: timestamp of the start time
    param: stop_time: timestamp of the stop time
    param: fs: sample rate
    param: fc: carrier frequency
    param: min_ele: minimum elevation angle
    '''
    eph = EphemerisLoader(zip_folder_path)
    eph_file_path = eph.find_one_sat(sat_id)

    duration = stop_time - start_time
    n_list = np.arange(0, fs*duration + 1, 1).astype(int)
    azimuth = np.empty(len(n_list))
    elevation = np.empty(len(n_list))
    range_ = np.empty(len(n_list))

    ts = load.timescale()
    d_1 = datetime.utcfromtimestamp(start_time)
    t_start = datetime(d_1.year, d_1.month, d_1.day, d_1.hour, d_1.minute, d_1.second, d_1.microsecond, tzinfo=pytz.UTC)
    t = ts.utc(t_start)

    sat_ele_max = -inf
    for n in n_list:
        time = start_time + n/fs
        pos, vel = eph.get_sat_position_velocity_at_t(eph_file_path, time)
        skyfield_pos = eph.convert_sat_position_velocity_to_skyfieldformat(pos, vel, t)

        dist = skyfield_pos - gs.at(t)
        alt, az, the_range = dist.altaz()
        azimuth[n] = az.degrees
        elevation[n] = alt.degrees
        range_[n] = the_range.m
        t = ts.utc(t.utc_datetime()+timedelta(milliseconds=1000/fs))
        
    t_list = n_list/fs
    is_visible = sat_ele_max > min_ele
    doppler_shift = None

    return is_visible, t_list, doppler_shift, azimuth, elevation, range_
 
def faster_doppler_sim(date, path, fc, t_start, t_stop, t_step, ground_station=None, min_ele=70):
    min_ele = min_ele # degrees
    
    satellites = load.tle_file(path) # either use path to tle or directly fetch latest tle from the url
    print("number of Starlink satellites loaded " + str(len(satellites)))
    open_satfile_list = []
    siebel_lat, siebel_lon = (+40.11389690596162, -88.22484814695467)
    siebel = wgs84.latlon(siebel_lat, siebel_lon) 
    farm_lat, farm_lon = (+40.072969193609126, -88.20958051030674)
    farm = wgs84.latlon(farm_lat, farm_lon, elevation_m=218)
    # gs =  siebel
    if ground_station is None:
        gs = farm 
    else:
        new_gs = wgs84.latlon(ground_station[0], ground_station[1])
        gs = new_gs

    ts = load.timescale()
    start_time_utc = datetime.fromtimestamp(t_start, tz=pytz.utc)
    duration = t_stop - t_start
    print("Duration in secs: ", duration)

    seconds_step_list = np.arange(start_time_utc.second, # seconds list begins from the second of the start time
                                  (start_time_utc.second+start_time_utc.microsecond*1e-6)+duration, 
                                  t_step) 
    timestep_list = ts.utc(start_time_utc.year, start_time_utc.month, start_time_utc.day, # skyfield utc time list
                           start_time_utc.hour, start_time_utc.minute, seconds_step_list)
    
    t_list = seconds_step_list-start_time_utc.second # seconds list relative to start time

    # first get satellites that are visible
    visible_sats = []
    for t in timestep_list:
        for satellite in satellites:
            dist = (satellite-gs).at(t)
            alt, az, distance = dist.altaz()
            if alt.degrees > min_ele and satellite not in visible_sats:
                visible_sats.append(satellite)
    print("Number of visible satellites: ", len(visible_sats))

    sat_dopp_dict = get_dopp_dict(fc, min_ele, gs, timestep_list, visible_sats)

    return sat_dopp_dict, t_list

def get_dopp_dict(fc, min_ele, gs, timestep_list, visible_sats):
    c = 299792458
    sat_dopp_dict = {}
    for t in timestep_list:
        for satellite in visible_sats:
            name = satellite.name
            dist = (satellite-gs).at(t)
            alt, az, distance = dist.altaz()
            if alt.degrees > min_ele-10: # for a satellite that is visible, we want to record its doppler shift for longer time so id-matching does not fail
                # calculate doppler shift
                _, _, the_range, _, _, range_rate = dist.frame_latlon_and_rates(gs)
                doppler_shift = -fc*range_rate.km_per_s*1000/c
            else:
                doppler_shift = np.nan
            if name in sat_dopp_dict:
                sat_dopp_dict[name] = np.vstack((sat_dopp_dict[name], [doppler_shift, az.degrees, alt.degrees]))
            else:
                sat_dopp_dict[name] = np.array([doppler_shift, az.degrees, alt.degrees])

    # making sat_dopp_dict compatible with format required for phase_from_bin.m
    for key in sat_dopp_dict:
        sat_dopp_dict[key] = sat_dopp_dict[key].T
    return sat_dopp_dict

def aoa_sim_1_sat(date, path, sat_id, t_start, t_stop, t_step):
    satellites = load.tle_file(path) # either use path to tle or directly fetch latest tle from the url
    siebel_lat, siebel_lon = (+40.11389690596162, -88.22484814695467)
    siebel = wgs84.latlon(siebel_lat, siebel_lon) 
    farm_lat, farm_lon = (+40.072969193609126, -88.20958051030674)
    farm = wgs84.latlon(farm_lat, farm_lon, elevation_m=218)
    # gs =  siebel
    farm_imu = wgs84.latlon(+40.07216262817384, -88.20952606201173, elevation_m=182.69)
    # gs = farm_imu
    gs = wgs84.latlon(+39.93383521, -88.25903011, elevation_m=182.69)

    # convert from timestamp to datetime
    d_1 = datetime.utcfromtimestamp(t_start)
    t_start = datetime(d_1.year, d_1.month, d_1.day, d_1.hour, d_1.minute, d_1.second, d_1.microsecond, tzinfo=pytz.UTC)

    d_2 = datetime.utcfromtimestamp(t_stop)
    t_stop = datetime(d_2.year, d_2.month, d_2.day, d_2.hour, d_2.minute, d_2.second, d_2.microsecond, tzinfo=pytz.UTC)

    for satellite in satellites:
        name = satellite.name
        if name == sat_id:
            _, t_list, _, az, el, range_ = calc_doppler(satellite, gs, t_start, t_stop, 1/t_step)
            return t_list, az, el, range_

def dopp_sim_1_sat(date, path, sat_id, t_start, t_stop, t_step, lat, lon, elevation):
    satellites = load.tle_file(path)
    gs = wgs84.latlon(lat, lon, elevation_m=elevation)

    # convert from timestamp to datetime
    d_1 = datetime.utcfromtimestamp(t_start)
    t_start = datetime(d_1.year, d_1.month, d_1.day, d_1.hour, d_1.minute, d_1.second, d_1.microsecond, tzinfo=pytz.UTC)

    d_2 = datetime.utcfromtimestamp(t_stop)
    t_stop = datetime(d_2.year, d_2.month, d_2.day, d_2.hour, d_2.minute, d_2.second, d_2.microsecond, tzinfo=pytz.UTC)

    for satellite in satellites:
        name = satellite.name
        if name == sat_id:
            _, t_list, dopp, azimuth, elevation, the_range = calc_doppler(satellite, gs, t_start, t_stop, 1/t_step)
            return t_list, dopp, azimuth, elevation, the_range

def aoa_sim_1_sat_eph(date, path, sat_id, t_start, t_stop, t_step):
    satellites = load.tle_file(path) # either use path to tle or directly fetch latest tle from the url
    siebel_lat, siebel_lon = (+40.11389690596162, -88.22484814695467)
    siebel = wgs84.latlon(siebel_lat, siebel_lon) 
    farm_lat, farm_lon = (+40.072969193609126, -88.20958051030674)
    farm = wgs84.latlon(farm_lat, farm_lon, elevation_m=218)
    farm_imu = wgs84.latlon(+40.07216262817384, -88.20952606201173, elevation_m=182.69)
    gs = farm_imu

    zip_folder_path = '/home/ishani/LeoPNT/USRP_data/2_20/ephemeris'

    for satellite in satellites:
        name = satellite.name
        if name == sat_id:
            _, t_list, _, az, el, range_ = calc_doppler_eph(zip_folder_path, sat_id, gs, t_start, t_stop, 1/t_step)
            return t_list, az, el, range_

def get_phase_diff_params_allsatsingroups_jida(gs_groups, coarse_gs, sat_groups, time_arr, tle_path, yaw, pitch, roll, d, lam):
    '''
    time_arr is the time stamp
    '''
    # satellites = load.tle_file(tle_path)
    # by_name = {sat.name: sat for sat in satellites}
    group_num = len(gs_groups)
    num_period = len(gs_groups[0])
    t_step = 1 # secs
    phase_diff = []

    loc_1, loc_0, loc_2 = np.array([0,0,0]), np.array([0,-d,0]), np.array([d,0,0])
    R_yaw = np.array([[np.cos(np.deg2rad(yaw)), -np.sin(np.deg2rad(yaw)), 0], [np.sin(np.deg2rad(yaw)), np.cos(np.deg2rad(yaw)), 0], [0, 0, 1]])
    R_pitch = np.array([[np.cos(np.deg2rad(pitch)), 0, np.sin(np.deg2rad(pitch))], [0, 1, 0], [-np.sin(np.deg2rad(pitch)), 0, np.cos(np.deg2rad(pitch))]])
    R_roll = np.array([[1, 0, 0], [0, np.cos(np.deg2rad(roll)), -np.sin(np.deg2rad(roll))], [0, np.sin(np.deg2rad(roll)), np.cos(np.deg2rad(roll))]])
    R = R_yaw @ R_pitch @ R_roll
    loc_0, loc_2 = R @ loc_0, R @ loc_2

    for i in tqdm(range(group_num)):
        centroid = coarse_gs[i]
        group_i = gs_groups[i]
        sat_i = sat_groups[i]
        gs = wgs84.latlon(centroid[0], centroid[1])
        phase_diff_1_group = []
        for j in range(num_period):
            time_j = time_arr[j]
            t_start, t_end = time_j - 5, time_j + 5
            d_1 = datetime.utcfromtimestamp(t_start)
            t_start = datetime(d_1.year, d_1.month, d_1.day, d_1.hour, d_1.minute, d_1.second, d_1.microsecond, tzinfo=pytz.UTC)

            d_2 = datetime.utcfromtimestamp(t_end)
            t_end = datetime(d_2.year, d_2.month, d_2.day, d_2.hour, d_2.minute, d_2.second, d_2.microsecond, tzinfo=pytz.UTC)
            sat = sat_i[j]
            _, t_list, dopp, az, el, range_ = calc_doppler(sat, gs, t_start, t_end, t_step)

            loc_sat = np.column_stack((range_ * np.cos(np.deg2rad(el)) * np.sin(np.deg2rad(az)), range_ * np.cos(np.deg2rad(el)) * np.cos(np.deg2rad(az)), range_ * np.sin(np.deg2rad(el))))
            range_1 = np.linalg.norm(loc_sat-loc_1, axis=1)
            range_0 = np.linalg.norm(loc_sat-loc_0, axis=1)
            range_2 = np.linalg.norm(loc_sat-loc_2, axis=1)
            del_phi_01_gt = -(range_0-range_1)/lam*2*np.pi
            del_phi_12_gt = -(range_1-range_2)/lam*2*np.pi
            phase_diff_1_group.append(np.array([np.mean(np.diff(del_phi_01_gt))/t_step, np.mean(np.diff(del_phi_12_gt))/t_step]))
        phase_diff.append(phase_diff_1_group)
    return phase_diff

def get_doppler_allsatsingroups(gs_groups, coarse_gs, sat_groups, time_arr, tle_path):
    '''
    time_arr is the time stamp
    '''
    # satellites = load.tle_file(tle_path)
    # by_name = {sat.name: sat for sat in satellites}
    group_num = len(gs_groups)
    num_period = len(gs_groups[0])
    t_step = 1 # secs
    dopp_, tt = [], []

    for i in tqdm(range(group_num)):
        centroid = coarse_gs[i]
        group_i = gs_groups[i]
        sat_i = sat_groups[i]
        gs = wgs84.latlon(centroid[0], centroid[1])
        dopp_1_group = []
        for j in range(num_period):
            time_j = time_arr[j]
            t_start, t_end = time_j - 5, time_j + 5
            d_1 = datetime.utcfromtimestamp(t_start)
            t_start = datetime(d_1.year, d_1.month, d_1.day, d_1.hour, d_1.minute, d_1.second, d_1.microsecond, tzinfo=pytz.UTC)

            d_2 = datetime.utcfromtimestamp(t_end)
            t_end = datetime(d_2.year, d_2.month, d_2.day, d_2.hour, d_2.minute, d_2.second, d_2.microsecond, tzinfo=pytz.UTC)
            sat = sat_i[j]
            _, t_list, dopp, az, el, range_ = calc_doppler(sat, gs, t_start, t_end, t_step)

            dopp_1_group.append(dopp)
        tt.append(t_list)
        dopp_.append(dopp_1_group)
    return dopp_, tt

def calc_doppler_blind_id(sat, gs_, start_time, stop_time, fs, fc=11.325e9, min_ele=60):
    c = 299792458
    ts = load.timescale()
    d_1 = datetime.utcfromtimestamp(start_time)
    start_time = datetime(d_1.year, d_1.month, d_1.day, d_1.hour, d_1.minute, d_1.second, d_1.microsecond, tzinfo=pytz.UTC)
    d_2 = datetime.utcfromtimestamp(stop_time)
    stop_time = datetime(d_2.year, d_2.month, d_2.day, d_2.hour, d_2.minute, d_2.second, d_2.microsecond, tzinfo=pytz.UTC)

    gs = wgs84.latlon(gs_[0], gs_[1])
    t = ts.utc(start_time)
    duration = stop_time-start_time
    n_list = np.arange(0, fs*duration.total_seconds() + 1, 1).astype(int)
    
    doppler_shift = np.empty(len(n_list))
    azimuth = np.empty(len(n_list))
    elevation = np.empty(len(n_list))
    range_ = np.empty(len(n_list))

    sat_ele_max = -inf
    for n in n_list:
        dist = (sat-gs).at(t)
        t = ts.utc(t.utc_datetime()+timedelta(milliseconds=1000/fs))
        alt, az, distance = dist.altaz() 
        if alt.degrees > sat_ele_max:
            sat_ele_max = alt.degrees
        _, _, the_range, _, _, range_rate = dist.frame_latlon_and_rates(gs)
        doppler_shift[n] = -fc*range_rate.km_per_s*1000/c
        if alt.degrees < min_ele-10:
            doppler_shift[n] = np.nan
        azimuth[n] = az.degrees
        elevation[n] = alt.degrees
        range_[n] = the_range.m
        
    t_list = n_list/fs
    is_visible = sat_ele_max > min_ele

    return is_visible, t_list, doppler_shift, azimuth, elevation, range_