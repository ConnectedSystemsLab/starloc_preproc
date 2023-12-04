# Functions for satellite localization simulation
from skyfield.api import load, wgs84, Topos
import numpy as np
from datetime import datetime, timedelta
from scipy.optimize import minimize
from tqdm import tqdm
from matplotlib import pyplot as plt

# constans
c = 299792458 # speed of light in m/s
R = 6378e3 # radius of earth in m

# generate received signal Method 1: r_i(t) = r_i(t-t_delay)
def gen_rx_signal(sat, gs, start_time, stop_time, fs, fc, f):
    
    ts = load.timescale()
    # get start time as ts.utc
    t = ts.utc(start_time)
    duration = stop_time-start_time
    n_list = np.arange(0, fs*duration.total_seconds(), 1).astype(int)
    num_antennas = len(gs)

    # received_sig and d are 2-D matrix, row index means different lnb and column index means different time steps
    # received_sig_i = received_sig[i-1, :], for i = 1, 2, ... 
    received_sig = np.zeros((num_antennas, len(n_list)), dtype=np.complex64)
    dis = np.empty((num_antennas, len(n_list)))
    elevation, azimuth = np.empty(len(n_list)), np.empty(len(n_list))

    for n in tqdm(n_list):
        dist = (sat-gs[0]).at(t)
        el, az, distance = dist.altaz()
        elevation[n], azimuth[n] = el.degrees, az.degrees
        for m in range(num_antennas):

            gs_m = gs[m]
            dist = (sat-gs_m).at(t)
            _, _, the_range, _, _, range_rate = dist.frame_latlon_and_rates(gs_m)
            doppler_shift = (fc)*range_rate.km_per_s*1000/c

            received_sig[m, n] = np.exp(1j*2*np.pi*(f)*n/fs)*np.exp(-1j*2*np.pi*(f+fc)*the_range.km/c*1000.0)
            dis[m, n] = the_range.km
            
        # increment t which is ts.utc by 1000/fs milliseconds
        t = ts.utc(t.utc_datetime()+timedelta(milliseconds=1000/fs))

    return received_sig, elevation, azimuth, n_list/fs

# generate received signal Method 2
def gen_rx_signal_2(sat, gs, start_time, stop_time, fs, fc, f):
    
    ts = load.timescale()
    # get start time as ts.utc
    t = ts.utc(start_time)
    duration = stop_time-start_time
    n_list = np.arange(0, fs*duration.total_seconds(), 1).astype(int)
    num_antennas = len(gs)

    # received_sig and d are 2-D matrix, row index means different lnb and column index means different time steps
    # received_sig_i = received_sig[i-1, :], for i = 1, 2, ... 
    received_sig = np.zeros((num_antennas, len(n_list)), dtype=np.complex64)
    dis = np.empty((num_antennas, len(n_list)))
    elevation, azimuth = np.empty(len(n_list)), np.empty(len(n_list))

    for n in tqdm(n_list):
        dist = (sat-gs[0]).at(t)
        _, _, the_range_0, _, _, _ = dist.frame_latlon_and_rates(gs[0])
        el, az, distance = dist.altaz()
        elevation[n], azimuth[n] = el.degrees, az.degrees
        for m in range(num_antennas):

            gs_m = gs[m]
            t_sent = ts.utc(t.utc_datetime()-timedelta(seconds=the_range_0.m/c))
            dist = (sat-gs_m).at(t_sent)
            _, _, the_range, _, _, range_rate = dist.frame_latlon_and_rates(gs_m)

            received_sig[m, n] = np.exp(1j*2*np.pi*(f)*n/fs)*np.exp(-1j*2*np.pi*(f+fc)*the_range.km/c*1000.0)
            dis[m, n] = the_range.km
            
        # increment t which is ts.utc by 1000/fs milliseconds
        t = ts.utc(t.utc_datetime()+timedelta(milliseconds=1000/fs))

    return received_sig, elevation, azimuth, n_list/fs

# generate received signal Method 3: time delayed version
def gen_rx_signal_3(sat, gs, start_time, stop_time, fs, fc, f):
    ts = load.timescale()
    # get start time as ts.utc
    t = ts.utc(start_time)
    duration = stop_time-start_time
    n_list = np.arange(0, fs*duration.total_seconds(), 1).astype(int)
    num_antennas = len(gs)

    # received_sig and d are 2-D matrix, row index means different lnb and column index means different time steps
    # received_sig_i = received_sig[i-1, :], for i = 1, 2, ... 
    received_sig = np.zeros((num_antennas, len(n_list)), dtype=np.complex64)
    dis = np.empty((num_antennas, len(n_list)))
    elevation, azimuth = np.empty(len(n_list)), np.empty(len(n_list))
    
    for n in tqdm(n_list):
        dist = (sat-gs[0]).at(t)
        el, az, distance = dist.altaz()
        elevation[n], azimuth[n] = el.degrees, az.degrees
        for m in range(num_antennas):
            gs_m = gs[m]
            dist = (sat-gs_m).at(t)
            _, _, the_range, _, _, range_rate = dist.frame_latlon_and_rates(gs_m)
            dis[m, n] = the_range.m
        t = ts.utc(t.utc_datetime()+timedelta(milliseconds=1000/fs))
    for m in range(num_antennas):
        received_sig[m, :] = np.exp(1j*2*np.pi*(f)*n_list/fs)*np.exp(-1j*2*np.pi*(f+fc)*(dis[m, :]-dis[0, :])/c)

    return received_sig, elevation, azimuth, n_list/fs

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

# calculate 2-D AoA based on formula
# - input: 
# delta_phi_1 : phase difference between rx0 & rx1, in radians
# d_1 : antenna spacing between rx0 & rx1, in meters
# lam : wavelength, in meters
# - output:
# az : azimuth angle, in degrees
# el : elevation angle, in degrees
def calc_aoa_formula(delta_phi_1, delta_phi_2, d_1, d_2, lam):
    phi = np.arctan2(-1 * delta_phi_2 / d_2, -1 * delta_phi_1 / d_1)
    phi = np.mod(phi, 2*np.pi)
    az = 2*np.pi - phi
    el = np.arccos(-delta_phi_1*lam/(2*np.pi*d_1*np.cos(az)))
    az, el = np.rad2deg(az), np.rad2deg(el)

    return az, el

def visual_loc_result(estimated_longitude, estimated_latitude, lon, lat):
    # draw a 2d scatter figure with the estimated latitude and longitude
    # plt.rcParams['figure.dpi'] = 200
    plt.plot(estimated_longitude, estimated_latitude, '.', label='estimated')
    # plt.plot(lon, lat, 'ro', label='ground truth')
    plt.xlabel('longitude (deg)')
    plt.ylabel('latitude (deg)')
    # plt.xlim(lon-0.1, lon+0.1)
    # plt.ylim(lat-0.1, lat+0.1)
    # plt.legend()
    # plt.show()

    distance = calc_distance(np.mean(estimated_latitude), np.mean(estimated_longitude), lat, lon)
    print(f'Localization Error = {distance:.2f} meters')

# add AWGN to a signal
def add_awgn(signal, snr_dB):
    signal_power = np.mean(np.abs(signal) ** 2)
    snr = 10 ** (snr_dB / 10)
    noise_power = signal_power / (2 * snr)
    noise = np.sqrt(noise_power) * (np.random.randn(len(signal)) + 1j * np.random.randn(len(signal)))
    noisy_signal = signal + noise
    return noisy_signal