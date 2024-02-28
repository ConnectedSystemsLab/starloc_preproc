import numpy as np
from skyfield.api import load, wgs84
from datetime import datetime, timedelta
from scipy import io as sio
import pytz
import os

c = 299792458  # speed of light in m/s
class Simulation:
    def __init__(self, file_path, simulation_config, satellite_config, receiver_config=None):
        """
        Initialize the simulation with start time from the file path and other specified parameters
        :param file_path: str - path to rx capture file. Used to get time of capture, destination for output files, etc.
        :param receiver_config: dict - configuration of the receiver. Location of receiver (lat, lon), center frequency, sample rate, antenna spacing.
        :param satellite_config: dict - configuration of the satellite. TLE file path, minimum elevation in degrees.
        :param simulation_config: dict - configuration of the simulation. UTC start time, duration in seconds and time step in seconds.
        """
        self.file_path = file_path
        if receiver_config is None:
            print("Receiver config not specified. Using default values")
            receiver_config = {
                "latlon": (40.07219365016506, -88.20949512342561),
                "elevation":213.81,
                "center_frequency": 11.325e9,
                "sample_rate": 2e6,
                "antenna_spacing": 13.25e-2,
                "placement": {"lnb0": (0,-1), "lnb1": (0,0), "lnb2": (1,0)}            
                }
        
        self.start_ts_utc = simulation_config["start_time"]
        self.duration = simulation_config["duration"]
        self.t_step = simulation_config["time_step"]

        self.satellites = load.tle_file(satellite_config["tle_file"])
        print("number of Starlink satellites loaded " + str(len(self.satellites)))
        self.min_sat_ele = satellite_config["min_elevation"] # in degrees

        self.receiver = receiver_config

        self.capture_date = file_path.split('/')[-2]
        self.capture_time = file_path.split('/')[-1].split('_')[2]
        self.result_folder = os.path.join(os.getcwd(), 'results', self.capture_date, self.capture_time, 'simulation_output')
        if not os.path.exists(self.result_folder):
            os.makedirs(self.result_folder)
        print("Results related to simulation in: ", self.result_folder)

    def get_dopp_tracks(self, out_file=None):
        """
        Get the doppler shift tracks for all the satellites in the TLE file
        :param out_file: str - path to the output file. 
        :return: dict - dictionary containing the doppler shift tracks for all the satellites
        """

        gs = wgs84.latlon(self.receiver["latlon"][0], self.receiver["latlon"][1], elevation_m=self.receiver["elevation"])
        ts = load.timescale()
        start_time_utc = datetime.fromtimestamp(self.start_ts_utc, tz=pytz.utc)
        seconds_step_list = np.arange(start_time_utc.second, (start_time_utc.second+start_time_utc.microsecond*1e-6)+self.duration, self.t_step)
        timestep_list = ts.utc(start_time_utc.year, start_time_utc.month, start_time_utc.day, start_time_utc.hour, start_time_utc.minute, seconds_step_list)
        self.sat_dopp_tracks_dict = {}

        for t_idx,t in enumerate(timestep_list):
            print("Current step: ", t.utc_datetime())    
            for satellite in self.satellites:
                name = satellite.name.replace('-', '_').replace(' ', '')
                # print("Satellite: ", name)
                dist = (satellite-gs).at(t)
                # get satellite elevation
                alt, az, distance = dist.altaz()
                # if satellite is visible (elevation > min_elevation)
                if alt.degrees >= self.min_sat_ele:
                    # calculate doppler shift
                    _, _, the_range, _, _, range_rate = dist.frame_latlon_and_rates(gs)
                    doppler_shift = -self.receiver["center_frequency"]*range_rate.km_per_s*1000/c
                    # if satellite name exists in sat_dopp_tracks_dict, append [time, dopp, az, ele] to the array for satellite name
                    if name in self.sat_dopp_tracks_dict:
                        self.sat_dopp_tracks_dict[name] = np.vstack((self.sat_dopp_tracks_dict[name], [t.utc_datetime().timestamp(), t_idx*self.t_step, doppler_shift, alt.degrees, az.degrees]))
                    else:
                        self.sat_dopp_tracks_dict[name] = np.array([t.utc_datetime().timestamp(), t_idx*self.t_step, doppler_shift, alt.degrees, az.degrees])
            # print(self.sat_dopp_tracks_dict)

        if out_file is None:
            out_file = os.path.join(self.result_folder, "sim_dopp_tracks.mat")
            print("Output file not specified. Saving results to: ", out_file)
            sio.savemat(out_file, self.sat_dopp_tracks_dict)

        else:
            print("Saving results to: ", os.path.join(self.result_folder, out_file))
            sio.savemat(os.path.join(self.result_folder, out_file), self.sat_dopp_tracks_dict)

        return self.sat_dopp_tracks_dict