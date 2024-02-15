from turtle import color


def call_imu_data():
    from utils.imu_data import IMUData
    imu = IMUData('/home/ishani/LeoPNT/USRP_data/2_5/imu_20240206004850.txt') # creates an instance of IMUData
    imu_data = imu.read_imu_data() # reads all imu data from the file. More details in utils/imu_data.py 
    attitude = imu.get_attitude() # use the get_attitude() method to get the yaw pitch and roll data
    import numpy as np  
    mean_attuitude = [np.mean(attitude[0]), np.mean(attitude[1]), np.mean(attitude[2])]
    print(mean_attuitude)
    time = imu.get_utctimestamp() # use the get_utctimestamp() method to get the timestamp data

    latlong = imu.get_latlonalt()
    import matplotlib.pyplot as plt
    plt.plot(attitude[0], label='roll')
    plt.plot(attitude[1], label='pitch')
    plt.plot(attitude[2], label='yaw')
    plt.legend(loc='upper right')
    plt.savefig('attitude.png')

def call_calibration():
    from utils.calibration import CalibrationSignal
    filepath ='/home/ishani/LeoPNT/USRP_data/2_3/utctime_3Feb2024_22:03:48_freq_11_325G_bw_2.0M_ts_1706997828.7235794_inrx0.dat'
    center_freq_rx = 11.325e9
    tx_freq = 11.3251e9
    sample_rate = 2e6
    cal = CalibrationSignal(filepath, center_freq_rx, tx_freq, sample_rate) # creates an instance of CalibrationSignal. More details in utils/calibration.py 
    ref_sig_idx = cal.get_all_refsigidx(ref_sig_thresh=20) # use the get_all_refsigidx() method to get the start and stop index of the reference signal
    return ref_sig_idx

def call_centertone():
    import matplotlib.pyplot as plt
    ref_sig_idxs = call_calibration()
    print(ref_sig_idxs)
    from utils.centertone import CenterTone
    filepath ='/home/ishani/LeoPNT/USRP_data/2_3/utctime_3Feb2024_22:03:48_freq_11_325G_bw_2.0M_ts_1706997828.7235794_inrx0.dat'
    centertone_instance = CenterTone(filepath) # creates an instance of CenterTone. More details in utils/centertone.py
    idx = centertone_instance.get_centertoneidxs(2**15, 2e6, ref_sig_idxs) # use the get_centertoneidx() method to get the start and stop index of the center
    for i in range(len(idx)):
        # print(idx[i])
        plt.plot(idx[i][0], int(idx[i][2]), 'o', color='blue')
    plt.savefig('centertone.png')
    print(idx)

def call_all_functions():
    from utils.calibration import CalibrationSignal

    filepath ='/home/ishani/LeoPNT/USRP_data/2_3/utctime_3Feb2024_22:03:48_freq_11_325G_bw_2.0M_ts_1706997828.7235794_inrx0.dat'

    center_freq_rx = 11.325e9
    tx_freq = 11.3251e9
    sample_rate = 2e6
    cal = CalibrationSignal(filepath, center_freq_rx, tx_freq, sample_rate) # creates an instance of CalibrationSignal. More details in utils/calibration.py 
    ref_sig_idx = cal.get_all_refsigidx(ref_sig_thresh=20) 



    from utils.centertone import CenterTone
    import numpy as np
    import matplotlib.pyplot as plt

    centertone_instance = CenterTone(filepath, sample_rate=2e6) # creates an instance of CenterTone. More details in utils/centertone.py
    idx = centertone_instance.get_centertoneidxs(num_samples_per_step=2**15, ref_sig_idx, thresh_multiplier=3) # use the get_centertoneidx() method to get the start and stop index of the center
    for i in range(len(idx)):
        # print(idx[i])
        plt.plot(idx[i][0], int(idx[i][2]), 'o', color='blue')



    omit_freq = [[0, 1e4], [2e4, 4e4], [1.14e4, 1.16e4], [1.4730e4, 1.4754e4], [1.4944e4, 1.4946e4], [1.5860e4, 1.5910e4], [1.6380e4, 1.6530e4], [1.7729e4, 1.8339e4]]
    idx_clean = centertone_instance.remove_nonsatellite_centertones(omit_freq) # use the omit_freq() method to remove the unwanted frequency ranges
    print(idx_clean)
    plt.cla()
    for i in range(len(idx_clean)):
        # print(idx_clean[i])
        plt.plot(idx_clean[i][0], int(idx_clean[i][2]), 'o', color='red')


    
    period_starts = [5, 58, 155, 205, 390, 450]
    period_ends = [25, 97, 183, 230, 430, 500]
    # load idx_clean from .mat
    import scipy.io
    from utils.centertone import CenterTone
    idx_clean = scipy.io.loadmat('/home/ishani/LeoPNT/starlink_ofdm/Starloc/results/2_3/22:03:48/center_tone/center_tone_idx_clean.mat')
    # get values from first key
    idx_clean = idx_clean['centertone_arr_clean']
    # plot the center tones
    import numpy as np
    import matplotlib.pyplot as plt
    # plt.figure()
    # for i in range(len(idx_clean)):
    #     plt.plot(idx_clean[i][0], int(idx_clean[i][2]), 'o', color='red')
    filepath ='/home/ishani/LeoPNT/USRP_data/2_3/utctime_3Feb2024_22:03:48_freq_11_325G_bw_2.0M_ts_1706997828.7235794_inrx0.dat'
    centertone_instance = CenterTone(filepath, sample_rate=2e6) # creates an instance of CenterTone. More details in utils/centertone.py
    tracks, combined_tracks = centertone_instance.get_centertone_tracks(period_starts, period_ends, centertone_arr_clean=idx_clean) # use the get_centertone_tracks() method to get the tracks of the center tones
    plt.figure()
    for sat in tracks.keys():
        plt.plot(tracks[sat][:, 0], tracks[sat][:, 2], 'o', label=sat)
    plt.legend(loc='upper right')
    plt.xlabel('Sample time (s)')
    plt.ylabel('Frequency (Hz)')
    plt.title('Center tone tracks')
    plt.show()

    #plot combined tracks
    plt.figure()
    for sat in combined_tracks.keys():
        plt.plot(combined_tracks[sat][:, 0], combined_tracks[sat][:, 2], 'o', label=sat)
    
if __name__ == "__main__":

    # call_imu_data()
    
    call_centertone()
