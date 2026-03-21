import numpy as np
from skyfield.api import load, wgs84
from datetime import datetime, timedelta
import os
import pytz
from tqdm import tqdm

"""
TLE propagation module to get expected Doppler shift of all satellites visible from a ground station.
"""
 
def faster_doppler_sim(tle_path, fc, t_start, t_stop, t_step, ground_station=None, min_ele=70):
    min_ele = min_ele # degrees
    
    satellites = load.tle_file(tle_path) # either use path to tle or directly fetch latest tle from the url
    print("Number of Starlink satellites loaded " + str(len(satellites)))
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
    for t in tqdm(timestep_list, desc="Calculating Doppler per timestep"):
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
