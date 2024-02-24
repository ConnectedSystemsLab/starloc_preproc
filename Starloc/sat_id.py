from math import inf
from telnetlib import DO
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

def aoa_sim_1_sat(date, path, sat_id, t_start, t_stop, t_step):
    satellites = load.tle_file(path) # either use path to tle or directly fetch latest tle from the url
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

    for satellite in satellites:
        name = satellite.name
        if name == sat_id:
            _, t_list, _, az, el, range_ = calc_doppler(satellite, gs, t_start, t_stop, 1/t_step)
            return t_list, az, el, range_