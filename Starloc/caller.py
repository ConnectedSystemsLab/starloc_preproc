from utils.center_tone import get_centertoneidx
from utils.center_tone import get_centertone_tracks

def call_centertone_idx():
    path = '/home/ishani/LeoPNT/USRP_data/1_21/time_23_5_freq_11_325G_bw_2.0M_1705900406.6641364_inrx0.dat'
    sample_rate = 2e6
    start_idx = int(131400000)
    num_samples_per_step = int(0.014*sample_rate)
    print(num_samples_per_step)
    thresh_multiplier = 3
    center_tone_idx = get_centertoneidx(path, start_idx, num_samples_per_step, sample_rate, thresh_multiplier, nfft=num_samples_per_step)
def read_pickle(file_path):
    import pickle
    with open(file_path, 'rb') as f:
        data = pickle.load(f)
        print(data)
    return 0

def check_ref():
    import numpy as np
    import matplotlib
    matplotlib.use('TkAgg') 
    from matplotlib import pyplot as plt

    from read_raw_data import read_dat_file

    path0 = '/home/ishani/LeoPNT/USRP_data/1_23/time_14_1_freq_11_325G_bw_2.0M_1706062245.5353017_inrx0.dat'
    path1 = '/home/ishani/LeoPNT/USRP_data/1_23/time_14_1_freq_11_325G_bw_2.0M_1706062245.5353017_inrx1.dat'
    path2 = '/home/ishani/LeoPNT/USRP_data/1_23/time_14_1_freq_11_325G_bw_2.0M_1706062245.5353017_inrx2.dat'

    iq0 = read_dat_file(path0, None, 0)
    iq1 = read_dat_file(path1, None, 0)
    iq2 = read_dat_file(path2, None, 0)
    # take mean of every 1000 samples
    div, _ = divmod(len(iq0),2e6)
    iq0 = iq0[0:int(div*2e6)]
    iq1 = iq1[0:int(div*2e6)]
    iq2 = iq2[0:int(div*2e6)]
    iq0_mean = np.mean(iq0.reshape(-1, int(2e6)), axis=1)
    iq1_mean = np.mean(iq1.reshape(-1, int(2e6)), axis=1)
    iq2_mean = np.mean(iq2.reshape(-1, int(2e6)), axis=1)

    # plot interactive plot

    plt.plot(np.angle(iq0[1000000:int(2e6*10)]/iq1[1000000:int(2e6*10)]))
    plt.show()

    return 0

if __name__ == "__main__":
    # call_centertone_idx()
    get_centertone_tracks('./center_tone_dict.pkl', [150, 180, 580, 640],  [180, 230, 640, 690], 2e6)
