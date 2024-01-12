import numpy as np
import matplotlib.pyplot as plt
import scipy.signal as signal
from read_raw_data import read_dat_file 

def preproc(iq0_path, sample_rate):
    iq1_path = iq0_path.replace('inrx0', 'inrx1')
    iq2_path = iq0_path.replace('inrx0', 'inrx2')
    
    is_ref = True
    len_frame = int(0.1*sample_rate)
    iq0_first_frame = read_dat_file(iq0_path, len_frame, 0)
    pw_ref = np.mean(np.abs(iq0_first_frame)**2)
    start_idx = len_frame
    ref_frame_cnt = 0

    while is_ref:
        iq0 =  read_dat_file(iq0_path, len_frame, start_idx)
        start_idx += len_frame
        ref_frame_cnt += 1
        avg_pw = np.mean(np.abs(iq0)**2)
        if avg_pw < 0.6*pw_ref:
            is_ref = False
            noise_idx = start_idx+len_frame

    ref_frame_cnt -= 5
    start_idx = len_frame
    phase_offset_01, phase_offset_02 = np.zeros(ref_frame_cnt), np.zeros(ref_frame_cnt)
    for i in range(ref_frame_cnt):
        iq0 = read_dat_file(iq0_path, len_frame, start_idx)
        iq1 = read_dat_file(iq1_path, len_frame, start_idx)
        iq2 = read_dat_file(iq2_path, len_frame, start_idx)
        start_idx += len_frame
        phase_offset_01[i] = np.mean(np.unwrap(np.angle(iq0/iq1)))
        phase_offset_02[i] = np.mean(np.unwrap(np.angle(iq0/iq2)))

    # avoid jump
    # if np.max(phase_offset_02) - np.min(phase_offset_02) > 2*np.pi:
    #     phase_offset_02[phase_offset_02 < 0] += 2*np.pi
        
    plt.plot(phase_offset_01, label='angle(iq0/iq1)')
    plt.plot(phase_offset_02, label='angle(iq0/iq2)')
    plt.title('phase offset from ref signal')
    plt.legend()
    phase_offset_01_mean = np.mean(phase_offset_01)
    phase_offset_02_mean = np.mean(phase_offset_02)
    # phase_offset_12_mean, phase_offset_02_mean
    print('The ref signal ends at index {}'.format(noise_idx))
    return noise_idx, phase_offset_01_mean, phase_offset_02_mean