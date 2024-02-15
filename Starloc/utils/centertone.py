from calendar import c
import time
from numpy import *
from read_raw_data import read_dat_file
from matplotlib import pyplot as plt
import os

class CenterTone:
    def __init__(self, file_path, sample_rate):
        # filepath can be any of the rx files. Other rx files will be obtained automatically.
        if 'rx0' in file_path:
            self.rx0_filepath = file_path
            self.rx1_filepath = file_path.replace('rx0', 'rx1')
            self.rx2_filepath = file_path.replace('rx0', 'rx2')
        elif 'rx1' in file_path:
            self.rx0_filepath = file_path.replace('rx1', 'rx0')
            self.rx1_filepath = file_path
            self.rx2_filepath = file_path.replace('rx1', 'rx2')
        elif 'rx2' in file_path:
            self.rx0_filepath = file_path.replace('rx2', 'rx0')
            self.rx1_filepath = file_path.replace('rx2', 'rx1')
            self.rx2_filepath = file_path
        else:
            print("Invalid file path. Please provide a valid file path.")

        self.capture_date = file_path.split('/')[-2]
        self.capture_time = file_path.split('/')[-1].split('_')[2]
        self.sample_rate = sample_rate
        self.result_folder = os.path.join(os.getcwd(), 'results', self.capture_date, self.capture_time, 'centertone')
        # make folder if it does not exist
        if not os.path.exists(self.result_folder):
            os.makedirs(self.result_folder)
            print("Results related to center tone in: ", self.result_folder)
        

    def get_centertoneidxs(self, num_samples_per_step, ref_sig_idxs, start_idx=None, stop_idx=None, nfft=None, thresh_multiplier=3, out_file=None):
        """
        Get the index of the center tones (at every time step) in the FFT spectrum where the center tone is common in all the rx files
        
        : param num_samples_per_step: number of samples to read at each time step
        : param sample_rate: sample rate of the file data
        : param ref_sig_idxs: list of start and stop indexs of the reference signal
        : param start_idx: index at which to start reading the file
        : param stop_idx: index at which to stop reading the file
        : param nfft: number of FFT bins
        : param thresh_multiplier: threshold multiplier for detecting center tones
        : param out_file: file to save the center tone index

        : return: array with the following columns: chunk index, center tone index, center tone value in rx0, center tone value in rx1, center tone value in rx2
        """
        self.num_samples_per_step = num_samples_per_step
        self.start_idx = start_idx
        self.stop_idx = stop_idx
        self.nfft = nfft
        self.centertone_idx_file = out_file

        if self.start_idx is None:
            self.start_idx = 0
        if self.stop_idx is None:
            self.stop_idx = -1
        if self.nfft is None:
            self.nfft = self.num_samples_per_step
        if self.centertone_idx_file is None:
            self.centertone_idx_file = 'centertone_idx.pkl'
        
        curr_idx = self.start_idx # number of samples read so far
        ref_sig_idxs = array(ref_sig_idxs) 
        # fig, ax = plt.subplots()
        # print(curr_idx, curr_idx-start_idx)
        start_time = time.time()
        res = {}
        self.centertone_arr = array([])
        curr_ref_sig_idx = 0
        while True:
            # omit index if it is in ref_sig_idxs
            if curr_idx >= ref_sig_idxs[curr_ref_sig_idx][0] and curr_idx <= ref_sig_idxs[curr_ref_sig_idx][1]:
                # print("Omitting index", curr_idx)
                if len(ref_sig_idxs) == curr_ref_sig_idx+1:
                    break
                else:
                    curr_idx = int(ref_sig_idxs[curr_ref_sig_idx][1]+1)
                    curr_ref_sig_idx += 1
                    continue
            # read num_samples_per_step from each file
            iq = [read_dat_file(self.rx0_filepath, count=num_samples_per_step, start_index=curr_idx), 
                  read_dat_file(self.rx1_filepath, count=num_samples_per_step, start_index=curr_idx), 
                  read_dat_file(self.rx2_filepath, count=num_samples_per_step, start_index=curr_idx)]
            
            if len(iq[0]) < num_samples_per_step or len(iq[1]) < num_samples_per_step or len(iq[2]) < num_samples_per_step:
                break

            # take fft of iq samples and apply fftshift
            fft_iq = [fft.fftshift(fft.fft(iq[0])), fft.fftshift(fft.fft(iq[1])), fft.fftshift(fft.fft(iq[2]))]
            # take absolute value of fft
            fft_abs_iq = [abs(fft_iq[0]), abs(fft_iq[1]), abs(fft_iq[2])]

            # find mean of fft_abs_iq0, fft_abs_iq1 and fft_abs_iq2
            fft_abs_iq_mean = [mean(fft_abs_iq[0]), mean(fft_abs_iq[1]), mean(fft_abs_iq[2])]

            # find indexes of peaks in fft_abs_iq0, fft_abs_iq1 and fft_abs_iq2
            fft_abs_iq_peaks = [where(fft_abs_iq[0] > thresh_multiplier*fft_abs_iq_mean[0]), 
                                where(fft_abs_iq[1] > thresh_multiplier*fft_abs_iq_mean[1]), 
                                where(fft_abs_iq[2] > thresh_multiplier*fft_abs_iq_mean[2])]
            # print(fft_abs_iq_peaks[0], "\n", fft_abs_iq_peaks[1], "\n", fft_abs_iq_peaks[2], "\n")

            # finr the intersection of peak arrays
            common_elements = intersect1d(intersect1d(fft_abs_iq_peaks[0], fft_abs_iq_peaks[1]), fft_abs_iq_peaks[2])
            if len(common_elements) > 0:    
                t = (curr_idx+self.num_samples_per_step/2)/self.sample_rate
                # add common elements to result array
                res[str(curr_idx)] = {"t":t, "com_idx":common_elements, "iq0_fft":fft_iq[0][common_elements], 
                                      "iq1_fft":fft_iq[1][common_elements], "iq2_fft":fft_iq[2][common_elements]}
                for element in common_elements:
                    if self.centertone_arr.size == 0:
                        self.centertone_arr = array([t, curr_idx, element, fft_iq[0][element], fft_iq[1][element], fft_iq[2][element]])
                    else:
                        self.centertone_arr = vstack((self.centertone_arr, [t, curr_idx, element, fft_iq[0][element], fft_iq[1][element], fft_iq[2][element]]))

            curr_idx += num_samples_per_step

        # save results to a file
        import pickle
        with open(os.path.join(self.result_folder, self.centertone_idx_file), 'wb') as f:
            pickle.dump(res, f)
            print("File saved at", os.path.join(self.result_folder, self.centertone_idx_file))
        # also save this as mat file
        import scipy.io
        scipy.io.savemat(os.path.join(self.result_folder, self.centertone_idx_file.split('.')[0]+'.mat'), {'center_tone_arr': self.centertone_arr})
        
        # also save this as mat file
        print("read all samples in", time.time()-start_time, "seconds")
        
        return self.centertone_arr
    
            
    def remove_nonsatellite_centertones(self, remove_freq_arr, centertone_arr=None, out_file=None):
        """
        Remove detected center tones that are not from the satellite

        :param remove_freq_arr: array of frequency bins to remove. This should be a 2D array with each row containing the start and stop index of the frequency to remove
        :param out_file: file to save the center tone index .mat file

        : return: center tone tracks
        """
        if not hasattr(self, 'centertone_arr'):
            if centertone_arr is not None:
                self.centertone_arr = centertone_arr
            else:
                print("Please provide centertone_arr or call get_centertoneidxs() first.")
                return
        print(self.centertone_arr.shape)
        if out_file is None:
            out_file = 'center_tone_idx_clean.mat'
        
        self.centertone_arr_clean = array([])
        omit_row = False
        for row in self.centertone_arr:
            for freq_rng in remove_freq_arr:
                if row[2] >= freq_rng[0] and row[2] <= freq_rng[1]:
                    omit_row = True
                    break
            if not omit_row:
                if self.centertone_arr_clean.size == 0:
                    self.centertone_arr_clean = row
                else:
                    self.centertone_arr_clean = vstack((self.centertone_arr_clean, row))
            omit_row = False

        # save array to file
        import scipy.io
        scipy.io.savemat(os.path.join(self.result_folder, out_file), {'centertone_arr_clean': self.centertone_arr_clean})
        print("clean", self.centertone_arr_clean.shape)
        return self.centertone_arr_clean
    

    def get_centertone_tracks(self, start_index_arr, stop_index_arr, centertone_arr_clean=None, nfft=2**15, freqbin_thresh=20, time_thresh=3, out_file=None):
        """
        Get the center tone tracks from the center tone dictionary
        
        :param start_index_arr: array of start index of center tones of each satellite
        :param stop_index_arr: array of stop index of center tones of each satellite
        :param centertone_arr_clean: array of center tones to use. This should be a 2D array with each row containing the time, chunk index, frequency bin, rx0, rx1, rx2
        :param nfft: number of FFT bins used to get the center tones
        :param freqbin_thresh: threshold for frequency bin difference to assign a center tone to a track
        :param time_thresh: threshold for time difference to assign a center tone to a track
        :param out_file: file to save the center tone index .mat file

        :return: center tone tracks for each satellite (should ideally be 9 for each satellite),  combined track for each satellite)
        """

        # check if self.centertone_arr_clean exists
        if hasattr(self, 'centertone_arr_clean'):
            centertone_arr_clean = self.centertone_arr_clean
        else:
            if centertone_arr_clean is not None:
                self.centertone_arr_clean = centertone_arr_clean
            else:
                print("Please provide centertone_arr_clean or call remove_nonsatellite_centertones() first.")
                return
        if not hasattr(self, 'nfft'):
            self.nfft = nfft
            print("WARNING: nfft is set to ", self.nfft, ". This is used to get frequency bin width.")

        # first separate out center tones based on start and stop periods
        self.centertone_separated_dict = {} # get centertones belonging to each start and stop period/satellite
        for i in range(len(start_index_arr)):
            if str(i) not in self.centertone_separated_dict:
                self.centertone_separated_dict[str(i)] = []
            start_period = start_index_arr[i]
            stop_period = stop_index_arr[i]
            for row in centertone_arr_clean:
                if row[0] >= start_period and row[0] <= stop_period:
                    self.centertone_separated_dict[str(i)].append(row)
        # now that we have an idea of center tones belonging to each satellite, we can track the center tones
        # for each centertone within a start and stop period, create a separate track. If there are 9 centertones, there should ideally be 9 tracks
        centertone_tracks_dict = {}
        centertone_combined_track_dict = {}
        for sat_num in range(len(start_index_arr)):
            sat_centertone_points = self.centertone_separated_dict[str(sat_num)]
            # print("Sat ", sat_num,"point are:", points,"\n\n")
            num_points = len(sat_centertone_points)
            # print("Sat: ", sat_num, "num points:", num_points, points)
            # assign each point to a track
            tone_tracks = {}
            for point in sat_centertone_points:
                time = point[0]
                freq_bin = point[2]
                assigned = False
                for track in tone_tracks:
                    curr_track = tone_tracks[track]
                    if abs(curr_track[-1][2] - freq_bin) < freqbin_thresh and abs(curr_track[-1][0] - time) < time_thresh:
                        tone_tracks[track]= vstack((curr_track, [point]))
                        assigned = True
                        break
                if not assigned:
                    tone_tracks[len(tone_tracks)] = array([point])

            # find the track with the most points
            max_duration = 0
            max_track = None
            for track in tone_tracks:
                duration = tone_tracks[track][-1,0] - tone_tracks[track][0,0]
                if duration > max_duration:
                    max_duration = duration
                    max_track = tone_tracks[track]
            
            # fit a 1 degree polynomial to the track since at the highest elevation of satellite, the doppler shift is linear
            max_track_polynomial_coeff = polyfit(max_track[:, 0], max_track[:, 2], 1)
            bin_freq_width = self.sample_rate/self.nfft
            centertone_bin_spacing = round(44e3/bin_freq_width) # 44kHz is the spacing between center tones in the OFDM signal gutter
            possible_spacings = centertone_bin_spacing*arange(-8, 9) # possible spacings between center tones
            # Create a combined track with all the center tones. This is done by associating points from other tracks to the main track.
            combined_track = array([])
            for track in tone_tracks:
                for pnt in tone_tracks[track]:
                    # check if the point is close to the combined track after subtracking the possitble centertone spacings
                    track_pnt_time = pnt[0]
                    track_pnt_freq = pnt[2]
                    possible_biases = polyval(max_track_polynomial_coeff, track_pnt_time) + possible_spacings
                    freq_distance = abs(possible_biases-track_pnt_freq)
                    # get min distance and index    
                    idx, min_freq_distance = argmin(freq_distance), min(freq_distance)
                    if min_freq_distance < freqbin_thresh/2: 
                        bias = [0, 0, possible_spacings[idx], 0, 0, 0]
                        if combined_track.size == 0:
                            combined_track = pnt - bias
                        else:
                            combined_track = vstack((combined_track, pnt-bias))

            centertone_combined_track_dict[str(sat_num)] = combined_track
            # fit a 2 degree polynomial to the combined track
            combined_track_polynomial_coeff = polyfit(combined_track[:, 0], combined_track[:, 2], 2)
            # recalculate the points in sat_centertone_points that should be assigned to this satellite
            for point in sat_centertone_points:
                time = point[0]
                freq_bin = point[2]
                possible_biases = polyval(combined_track_polynomial_coeff, time) + possible_spacings
                freq_distance = abs(possible_biases-freq_bin)
                # get min distance
                min_freq_distance = min(freq_distance)
                if min_freq_distance < freqbin_thresh/2:
                    if centertone_tracks_dict.get(str(sat_num)) is None:
                        centertone_tracks_dict[str(sat_num)] = array([point])
                    else:
                        centertone_tracks_dict[str(sat_num)] = vstack((centertone_tracks_dict[str(sat_num)], point))

        # save array to file
        if out_file is None:
            out_file = 'sat_centertone_tracks.mat'
        import scipy.io
        scipy.io.savemat(os.path.join(self.result_folder, out_file), centertone_tracks_dict)
        scipy.io.savemat(os.path.join(self.result_folder, out_file.split('.')[0]+'_combined.mat'), centertone_combined_track_dict)
        print("centertone_tracks saved at", os.path.join(self.result_folder, out_file))
        print("centertone_combined_track saved at", os.path.join(self.result_folder, out_file.split('.')[0]+'_combined.mat'))
        return centertone_tracks_dict, centertone_combined_track_dict


    



