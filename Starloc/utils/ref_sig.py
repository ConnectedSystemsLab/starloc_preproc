import numpy as np
from scipy.signal import find_peaks
from read_raw_data import read_dat_file
import matplotlib.pyplot as plt

def get_reference_signal_indexes(file_path, center_freq_rx, sample_rate, tx_freq, num_read_samples, nfft=2**15, start_from=None):
    """
    Get the start and stop index of reference siganl. If the start_from is specified, 
    the function will start looking for the reference signal from the start_from index.
    
    :param file_path: path to the file from (can be any one of rx0, rx1, rx2)
    :param center_freq_rx: center frequency of the rx
    :param sample_rate: sample rate of the data
    :param tx_freq: transmit frequency of reference signal. This is used to look for the power in a specifc frequency bin in the fft spectrum
    :param num_read_samples: number of samples to read at each time step
    :param nfft: number of FFT bins
    :param start_from: start index of the signal file to start looking for the reference signal

    :return: start and stop index of the reference signal
    """
    # Load the signal from the file
    start_index = None
    stop_index = None
    no_sig_count = 0
    num_read_samples = int(nfft)
    
    if start_from is None:
        idx = 0
    else:
        idx = int(start_from)

    # bin to look at for the tx freq
    tx_bin = round(((tx_freq-center_freq_rx) / (sample_rate / nfft))/2)
    print("tx_bin: ", tx_bin)
    while True:
        # read the signal from the file
        sig_seg = read_dat_file(file_path, num_read_samples, idx)
        if len(sig_seg) < num_read_samples:
            break
        # calc the fft
        sig_fft = np.fft.fft(sig_seg)
        # calc the power spectral density
        psd = np.abs(sig_fft) ** 2
        # find mean of the psd
        mean_psd = np.mean(psd)
        if psd[tx_bin] > mean_psd * 20: # TODO: this is the thresh hold for the power in the tx_bin. might want this to be an argunment
            if start_index is None:
                start_index = idx
            else:
                stop_index = idx
        else:
            if stop_index is not None and start_index is not None:
                no_sig_count = no_sig_count + 1
                if no_sig_count > 2:
                    break   
        idx += num_read_samples

        # plot psd for debugging.
        # plt.cla() 
        # plt.plot(psd)
        # plt.pause(0.05)
    # plt.show()

    return start_index, stop_index