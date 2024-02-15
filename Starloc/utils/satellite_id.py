import re
import numpy as np
import scipy.io as sio
import os

class SatelliteID:
    def __init__(self, sim_dopp_tracks_matfile, combined_centertone_tracks_matfile, file_path, sample_rate=None):
        """
        :param sim_dopp_track_matfile: str - path to the mat file containing the simulated dopp track
        :param combined_centertone_track_matfile: str - path to the mat file containing the combined centertone track
        :param file_path: str - path to therx file to get the date and time of capture to infer results folder
        :param sample_rate: float - sample rate of the signal
        """

        self.sim_tracks = sio.loadmat(sim_dopp_tracks_matfile)
        # remove the first 3 keys from the dictionary
        self.sim_tracks.pop('__header__')
        self.sim_tracks.pop('__version__')
        self.sim_tracks.pop('__globals__')

        self.combined_centertone_tracks = sio.loadmat(combined_centertone_tracks_matfile)
        # remove the first 3 keys from the dictionary
        self.combined_centertone_tracks.pop('__header__')
        self.combined_centertone_tracks.pop('__version__')
        self.combined_centertone_tracks.pop('__globals__')

        print("simulation track: ", self.sim_tracks.keys())
        print("centertone track: ", self.combined_centertone_tracks.keys())

        self.capture_date = file_path.split('/')[-2]
        self.capture_time = file_path.split('/')[-1].split('_')[2]
        self.result_folder = os.path.join(os.getcwd(), 'results', self.capture_date, self.capture_time, 'satellite_id')
        # make folder if it does not exist
        if not os.path.exists(self.result_folder):
            os.makedirs(self.result_folder)
        print("Results related to satellite ID in: ", self.result_folder)
    
    def get_clean_combined_centertone_tracks(self, sample_rate, nfft_centertone, out_file=None):
        """
        The combined centertone track may have multiple frequency bins associated with the same time step. This function averages out the frequency and returns time, frequency list for each satellite. 
        :param centertone_track_matfile: str - path to the mat file containing the centertone track
        :param out_file: str - path to the output file. 
        :return: dict - dictionary containing the clean combined centertone track for all the satellites
        """
        freq = np.linspace(-sample_rate/2, sample_rate/2, nfft_centertone)
        self.clean_combined_centertone_tracks = {}

        for sat in self.combined_centertone_tracks:
            # create independent copy of self.combined_centertone_tracks[sat]
            
            track = self.combined_centertone_tracks[sat].copy()
            f_bin = np.int32(np.real((track[:, 2])))
            f = freq[f_bin]
            track[:,2] = f
            t = np.unique(track[:, 0])
            clean_track = np.zeros((len(t), 2))
            for i, time in enumerate(t):
                idx = np.where(track[:, 0] == time)
                clean_track[i, 0] = time
                clean_track[i, 1] = np.mean(track[idx, 2])
            self.clean_combined_centertone_tracks[sat] = clean_track
        if out_file is None:
            out_file = os.path.join(self.result_folder, 'clean_combined_centertone_tracks.mat')
        sio.savemat(out_file, self.clean_combined_centertone_tracks)
        print("Clean combined centertone tracks saved at: ", out_file)

        return self.clean_combined_centertone_tracks
    
    def match_simtrack_centertonetrack(self, combined_centertone_tracks=None, out_file=None):
        """
        Get the satellite ID by matching the simulated dopp track with the clean combined centertone track
        :param out_file: str - path to the output file. 
        :return: dict - observed satellite number: <STARLINK ID>
        """
        if not hasattr(self, 'clean_combined_centertone_tracks'):
            if combined_centertone_tracks is None:
                raise ValueError("Combined centertone tracks not provided")
            else:
                self.clean_combined_centertone_tracks = combined_centertone_tracks

        self.matched_satellite_id = {}
        self.possible_satellite_id = {}

        for sat in self.clean_combined_centertone_tracks:
            # get the satellite track
            track = self.clean_combined_centertone_tracks[sat]
            # get track start and end time
            track_start_time = track[0, 0] #relative to the start time of the capture
            track_end_time = track[-1, 0] #relative to the start time of the capture
            # from simulated tracks, get the tracks that exist within the start and end time of the centertone track
            min_variance = np.inf
            for sim_sat in self.sim_tracks:
                sim_track = self.sim_tracks[sim_sat]
                print(track_start_time, track_end_time)
                # check if start and end time of the centertone track is within the time of the sim track
                idx = np.where((sim_track[:, 1] >= track_start_time) & (sim_track[:, 1] <= track_end_time))
                if len(idx[0]) > 1: 
                    # if sim_sat has a sim_track during the time of the observed centertone track, 
                    # fit a 1 degree polynomial to the sim track. 
                    polynomial_coeff_sim_track = np.polyfit(sim_track[min(idx[0]):max(idx[0]), 1], sim_track[min(idx[0]):max(idx[0]), 2], 2)
                    # get the frequencies expected at the time of the centertone track if the sim track corresponds to the observed centertone track
                    expected_freq = np.polyval(polynomial_coeff_sim_track, track[:,0])
                    # calculate variance of difference between expected and observed frequency
                    variance = np.var(track[:, 1]-expected_freq)
                    # append the satellite id to the possible_satellite_id dictionary
                    if sat in self.possible_satellite_id:
                        self.possible_satellite_id[sat].append([sim_sat, 'variance:'+str(variance)])
                    else:
                        self.possible_satellite_id[sat] = [[sim_sat, 'variance: '+str(variance)]]
                    if variance < min_variance:
                        min_variance = variance
                        self.matched_satellite_id[sat] = sim_sat

        if out_file is None:
            out_file = os.path.join(self.result_folder, 'matched_satellite_id.mat')
        sio.savemat(out_file, self.matched_satellite_id)
        print("Matched satellite id saved at: ", out_file)

        return self.possible_satellite_id, self.matched_satellite_id