import numpy as np
from scipy.signal import find_peaks
from read_raw_data import read_dat_file
import matplotlib.pyplot as plt

class CalibrationSignal:
    """
    This class has all functions related to the calibration signal. 
    Eg. finding index of the calibration signal in the signal file, post processing of the calibration signal etc.
    """
    def __init__(self, file_path, center_freq_rx, tx_freq, sample_rate):
        self.file_path = file_path 
        self.center_freq_rx = center_freq_rx
        self.sample_rate = sample_rate
        self.tx_freq = tx_freq

    def get_refsigidx(self, nfft=2**15, num_samples_per_step=None, start_from=None, ref_sig_thresh=20):
        """
        Get the start and stop index of reference siganl. If the start_from is specified, 
        the function will start looking for the reference signal from the start_from index.
        
        :param nfft: number of FFT bins
        :param num_samples_per_step: number of samples to read at each time step. By default, it is set to nfft since np.fft.fft() crops the input length to nfft if the signal is longer than nfft. (https://numpy.org/doc/stable/reference/generated/numpy.fft.fft.html#numpy.fft.fft)
        :param start_from: start index of the signal file to start looking for the reference signal
        :param ref_sig_thresh: threshold for the power in the tx_bin. If the power in the tx_bin is greater than mean_psd*ref_sig_thresh, the signal is considered as the reference signal.
        :return: start and stop index of the reference signal
        """
        
        start_index = None
        stop_index = None
        no_sig_count = 0
        if num_samples_per_step == None: 
            num_samples_per_step = int(nfft)
        
        if start_from is None:
            idx = 0
        else:
            idx = int(start_from)

        # bin to look at for the tx freq
        tx_bin = round(((self.tx_freq-self.center_freq_rx) / (self.sample_rate / nfft))/2)
        # print("tx_bin: ", tx_bin)
        while True:
            # read the signal from the file
            sig_seg = read_dat_file(self.file_path, num_samples_per_step, idx)
            if len(sig_seg) < num_samples_per_step:
                break
            # calc the fft
            sig_fft = np.fft.fft(sig_seg)
            # calc the power spectral density
            psd = np.abs(sig_fft) ** 2
            # find mean of the psd
            mean_psd = np.mean(psd)
            if psd[tx_bin] > mean_psd * ref_sig_thresh:
                if start_index is None:
                    start_index = idx
                else:
                    stop_index = idx
            else:
                if stop_index is not None and start_index is not None:
                    no_sig_count = no_sig_count + 1
                    # break if no ref signal is found for 2 consecutive reads and the start and stop indexes have already been found
                    if no_sig_count > 2:
                        break
            idx += num_samples_per_step

            # plot psd for debugging.
            # plt.cla()
            # plt.plot(psd)
            # plt.pause(0.05)
        # plt.show()
            
        return start_index, stop_index
    
    def get_all_refsigidx(self, nfft=2**15, num_samples_per_step=None, ref_sig_thresh=20):
        """
        Get the start and stop index of all the reference signals in the file. 
        
        :param nfft: number of FFT bins
        :param num_samples_per_step: number of samples to read at each time step. By default, it is set to nfft since np.fft.fft() crops the input length to nfft if the signal is longer than nfft. (https://numpy.org/doc/stable/reference/generated/numpy.fft.fft.html#numpy.fft.fft)
        :param ref_sig_thresh: threshold for the power in the tx_bin. If the power in the tx_bin is greater than mean_psd*ref_sig_thresh, the signal is considered as the reference signal.
        :return: list of start and stop index of the reference signal
        """
        ref_sig_indexes = []
        start_idx = 0
        while True:
            start_idx, stop_idx = self.get_refsigidx(nfft, num_samples_per_step, start_idx, ref_sig_thresh)
            if start_idx is None or stop_idx is None:
                break
            ref_sig_len = (stop_idx - start_idx) / self.sample_rate
            ref_sig_indexes.append([start_idx, stop_idx, ref_sig_len])
            start_idx = stop_idx + 1e6 # skipping a few samples after stop idx to set new start_idx for finding calibration/ref sig

        return ref_sig_indexes
    
    def get_refsig_phase(self, ref_sig_idx, buffer=0.01):
        """
        Get the phase of the reference signal. 
        
        :param ref_sig_idx: start and stop index of the reference signal obtained from function get_all_refsigidx()
        :param buffer: time to discard from the reference signal to avoid the transient
        """
        num_ref_sig = len(ref_sig_idx)  # how many reference signal periods are there
        phase_ref = np.empty(num_ref_sig)
        for i in range(num_ref_sig):
            # discard the first buffer seconds of the reference signal to avoid the transient
            sig_ref_i = read_dat_file(self.file_path, int(ref_sig_idx[i][1]-ref_sig_idx[i][0]-buffer*self.sample_rate), int(ref_sig_idx[i][0]+buffer*self.sample_rate))
            # do fft and find the peak's phase
            sig_fft = np.fft.fft(sig_ref_i)
            peak_idx = np.argmax(np.abs(sig_fft))
            phase_ref[i] = np.angle(sig_fft[peak_idx])

        return phase_ref