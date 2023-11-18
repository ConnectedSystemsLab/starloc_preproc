# Functions for satellite localization simulation
from skyfield.api import load, wgs84, Topos
import numpy as np
from datetime import datetime, timedelta
from scipy.optimize import minimize

# constans
c = 299792458 # speed of light in m/s
R = 6378e3 # radius of earth in m

# Calculate doppler shift given satellite, ground station, start time, stop time, sampling frequency, and carrier frequency
def calc_doppler(sat, gs, start_time, stop_time, fs, fc):
    ts = load.timescale()
    t = ts.utc(start_time)
    duration = stop_time-start_time
    n_list = np.arange(0, fs*duration.total_seconds(), 1).astype(int)
    doppler_shift = np.empty(len(n_list))

    for n in n_list:
        dist = (sat-gs).at(t)
        _, _, the_range, _, _, range_rate = dist.frame_latlon_and_rates(gs)
        doppler_shift[n] = -fc*range_rate.km_per_s*1000/c
        t = ts.utc(t.utc_datetime()+timedelta(milliseconds=1000/fs))
    t_list = n_list/fs

    return t_list, doppler_shift

# calculate the distance between two locations on the earth
def calc_distance(lat_1, lon_1, lat_2, lon_2):
    # convert from degrees to radians
    lat_1, lat_2, lon_1, lon_2 = np.deg2rad([lat_1, lat_2, lon_1, lon_2])
    dlat, dlon = lat_2 - lat_1, lon_2 - lon_1
    a = np.sin(dlat / 2)**2 + np.cos(lat_1) * np.cos(lat_2) * np.sin(dlon / 2)**2
    c_ = 2 * np.arctan2(np.sqrt(a), np.sqrt(1 - a))
    
    return R*c_

# add AWGN to a signal
def add_awgn(signal, snr_dB):
    signal_power = np.mean(np.abs(signal) ** 2)
    snr = 10 ** (snr_dB / 10)
    noise_power = signal_power / (2 * snr)
    noise = np.sqrt(noise_power) * (np.random.randn(len(signal)) + 1j * np.random.randn(len(signal)))
    noisy_signal = signal + noise
    return noisy_signal