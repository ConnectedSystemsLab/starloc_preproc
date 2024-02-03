from os import read
from random import sample
import time
from numpy import *
from read_raw_data import read_dat_file
from matplotlib import pyplot as plt
import matplotlib.animation as animation

def get_centertoneidx(file_path, start_idx, num_samples_per_step, sample_rate, thresh_multiplier=3, nfft=None, out_file=None):
    """
    Get the index of the center tones (at every time step) in the FFT spectrum
    :param file_path: path to the file from rx0. rx1 and rx2 are obtained by replacing rx0 with rx1 and rx2 in the file path
    :param start_idx: start index of the signal
    :param num_samples_per_step: number of samples to read at each time step
    :param sample_rate: sample rate of the file data
    :param nfft: number of FFT bins
    :return: index of the center tone
    """
    res = {}
    if nfft is None:
        nfft = num_samples_per_step
    # Read the file
    f0 = file_path
    f1 = f0.replace('rx0', 'rx1')
    f2 = f0.replace('rx0', 'rx2')

    curr_idx = start_idx # number of samples read so far
    # fig, ax = plt.subplots()
    # print(curr_idx, curr_idx-start_idx)
    start_time = time.time()
    while True:
        # read num_samples_per_step from each file
        #TODO: convert all this to an array instead of having multiple variables with same name
        iq0 = read_dat_file(f0, count=num_samples_per_step, start_index=curr_idx)
        iq1 = read_dat_file(f1, count=num_samples_per_step, start_index=curr_idx)
        iq2 = read_dat_file(f2, count=num_samples_per_step, start_index=curr_idx)
        if len(iq0) < num_samples_per_step or len(iq1) < num_samples_per_step or len(iq2) < num_samples_per_step:
            break
        # take fft of iq samples and apply fftshift
        fft_iq0 = fft.fftshift(fft.fft(iq0))
        fft_iq1 = fft.fftshift(fft.fft(iq1))
        fft_iq2 = fft.fftshift(fft.fft(iq2))
        # take absolute value of fft
        fft_abs_iq0 = abs(fft_iq0)
        fft_abs_iq1 = abs(fft_iq1)
        fft_abs_iq2 = abs(fft_iq2)
        # find mean of fft_abs_iq0, fft_abs_iq1 and fft_abs_iq2
        fft_abs_iq0_mean = mean(fft_abs_iq0)
        fft_abs_iq1_mean = mean(fft_abs_iq1)
        fft_abs_iq2_mean = mean(fft_abs_iq2)
        # find indexes of peaks in fft_abs_iq0, fft_abs_iq1 and fft_abs_iq2
        fft_abs_iq0_peaks = where(fft_abs_iq0 > thresh_multiplier*fft_abs_iq0_mean)
        fft_abs_iq1_peaks = where(fft_abs_iq1 > thresh_multiplier*fft_abs_iq1_mean)
        fft_abs_iq2_peaks = where(fft_abs_iq2 > thresh_multiplier*fft_abs_iq2_mean)
        # print(fft_abs_iq0_peaks, "\n", fft_abs_iq1_peaks, "\n", fft_abs_iq2_peaks, "\n")

        # finr the intersection of peak arrays
        common_elements = intersect1d(intersect1d(fft_abs_iq0_peaks, fft_abs_iq1_peaks), fft_abs_iq2_peaks)
        if len(common_elements) > 0:    
            t = (curr_idx-num_samples_per_step/2)/sample_rate
            # add common elements to result array
            res[str(curr_idx)] = {"t":t, "com_idx":common_elements, "iq0_fft":fft_iq0[common_elements], "iq1_fft":fft_iq1[common_elements], "iq2_fft":fft_iq2[common_elements]}
            # TODO: also append to array so it can be saved as mat file
        # ax.plot(iq0_fft_abs)
        # ax.plot(iq1_fft_abs)
        # ax.plot(iq2_fft_abs)
        # plt.pause(0.0001)
        # plt.cla()
        curr_idx += num_samples_per_step
        # print(curr_idx, curr_idx-start_idx, iq0_fft_abs)
    # plt.show()
    # save res to a file
    import pickle
    if out_file is not None:
        # check if folder exists
        import os
        if not os.path.exists(os.path.dirname(out_file)):
            os.makedirs(os.path.dirname(out_file))
        with open(out_file, 'wb') as f:
            pickle.dump(res, f)
            print("File saved as", out_file)
            #TODO also save this as mat file
    else:
        with open('center_tone_dict.pkl', 'wb') as f:
            pickle.dump(res, f)
            print("File saved as center_tone_dict.pkl")
            #TODO also save this as mat file
    # also save this as mat file
    print("read all samples in", time.time()-start_time, "seconds")
    
    return 0

def get_centertone_tracks(center_tone_dict, start_index_arr, stop_index_arr, sample_rate, out_file=None):
    """
    Get the center tone tracks from the center tone dictionary
    :param center_tone_dict: dictionary with center tones at each time step
    :param start_periods_arr: array of start index of center tones
    :param stop_periods_arr: array of stop index of center tones
    :return: center tone tracks
    """
    import pickle
    # read center_tone_dict from file
    with open(center_tone_dict, 'rb') as f:
        center_tone_dict = pickle.load(f)
    # print(center_tone_dict)
    # first separate out center tones based on start and stop periods
    center_tone_tracks = {} # holds all center tones between each start and stop periods
    for i in range(len(start_index_arr)):
        if str(i) not in center_tone_tracks:
            center_tone_tracks[str(i)] = []
        start_period = start_index_arr[i]
        stop_period = stop_index_arr[i]
        for key in center_tone_dict:
            if float(center_tone_dict[key]['t']) >= start_period and float(center_tone_dict[key]['t']) <= stop_period: # inclusive of start and stop periods
                #convert center_tone_dict[key] to array
                for k in range(len(center_tone_dict[key]['com_idx'])):
                    center_tone_arr = [center_tone_dict[key]['t'], center_tone_dict[key]['com_idx'][k], center_tone_dict[key]['iq0_fft'][k], center_tone_dict[key]['iq1_fft'][k], center_tone_dict[key]['iq2_fft'][k]]
                    # Append the value to the list
                    center_tone_tracks[str(i)].append(center_tone_arr)
    
    # now that we have an idea of center tones at each time step, we can track the center tones
    # for each centertone within a start and stop period, create a separate track. If there are 9 centertones, there should ideally be 9 tracks
    dopp_track_dict = {}
    for sat_num in range(len(start_index_arr)):
        points = center_tone_tracks[str(sat_num)]
        # print("Sat ", sat_num,"point are:", points,"\n\n")
        num_points = len(points)
        print("Sat: ", sat_num, "num points:", num_points)
        # assign each point to a track
        tone_tracks = {}
        for point in points:
            time = points[0]
            freq_bin = points[1]

