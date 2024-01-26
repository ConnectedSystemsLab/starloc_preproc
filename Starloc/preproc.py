import numpy as np
import matplotlib.pyplot as plt
import scipy.signal as signal
from read_raw_data import read_dat_file 

def preproc(iq0_path, sample_rate):
    iq1_path = iq0_path.replace('inrx0', 'inrx1')
    iq2_path = iq0_path.replace('inrx0', 'inrx2')
    
    is_ref = True
    is_noise = False
    is_end = False
    len_frame = int(0.1*sample_rate)
    iq0_first_frame = read_dat_file(iq0_path, len_frame, 0)
    iq1_first_frame = read_dat_file(iq1_path, len_frame, 0)
    iq2_first_frame = read_dat_file(iq2_path, len_frame, 0)
    pw_ref_0 = np.mean(np.abs(iq0_first_frame)**2)
    pw_ref_1 = np.mean(np.abs(iq1_first_frame)**2)
    pw_ref_2 = np.mean(np.abs(iq2_first_frame)**2)
    start_idx = len_frame
    ref_frame_cnt = 0

    # know when does the file end
    idx = 0
    t_end = 0
    while not is_end:
        iq0 =  read_dat_file(iq0_path, len_frame, idx)
        idx += len_frame
        t_end += len_frame/sample_rate
        if np.size(iq0) == 0:
            is_end = True

    while not is_noise:
        iq0 = read_dat_file(iq0_path, len_frame, start_idx)
        iq1 = read_dat_file(iq1_path, len_frame, start_idx)
        iq2 = read_dat_file(iq2_path, len_frame, start_idx)
        start_idx += len_frame
        if is_ref:
            ref_frame_cnt += 1
        avg_pw_0 = np.mean(np.abs(iq0)**2)
        avg_pw_1 = np.mean(np.abs(iq1)**2)
        avg_pw_2 = np.mean(np.abs(iq2)**2)
        if avg_pw_0 < 0.01*pw_ref_0 and avg_pw_1 < 0.01*pw_ref_1 and avg_pw_2 < 0.01*pw_ref_2:
            is_noise = True
            noise_idx = start_idx+len_frame
        elif avg_pw_0 < 0.01*pw_ref_0 or avg_pw_1 < 0.01*pw_ref_1 or avg_pw_2 < 0.01*pw_ref_2:
            is_ref = False

    ref_frame_cnt -= 45
    start_idx = len_frame
    phase_offset_01, phase_offset_02, phase_offset_12 = np.zeros(ref_frame_cnt), np.zeros(ref_frame_cnt), np.zeros(ref_frame_cnt)
    t = np.linspace(0, ref_frame_cnt-1, ref_frame_cnt)*0.1
    for i in range(ref_frame_cnt):
        iq0 = read_dat_file(iq0_path, len_frame, start_idx)
        iq1 = read_dat_file(iq1_path, len_frame, start_idx)
        iq2 = read_dat_file(iq2_path, len_frame, start_idx)
        start_idx += len_frame
        phase_offset_01[i] = np.mean(np.unwrap(np.angle(iq0/iq1)))
        phase_offset_02[i] = np.mean(np.unwrap(np.angle(iq0/iq2)))
        phase_offset_12[i] = np.mean(np.unwrap(np.angle(iq1/iq2)))

    phase_offset_01 = np.unwrap(phase_offset_01)
    phase_offset_02 = np.unwrap(phase_offset_02)
    phase_offset_12 = np.unwrap(phase_offset_12)
    plt.plot(t, phase_offset_01, label='angle(iq0/iq1)')
    plt.plot(t, phase_offset_02, label='angle(iq0/iq2)')
    plt.plot(t, phase_offset_12, label='angle(iq1/iq2)')
    plt.title('phase offset from ref signal')
    plt.xlabel('time (s)')
    plt.legend()
    phase_offset_01_mean = np.mean(phase_offset_01)
    phase_offset_02_mean = np.mean(phase_offset_02)
    phase_offset_12_mean = np.mean(phase_offset_12)
    # phase_offset_12_mean, phase_offset_02_mean
    print('The ref signal ends at index {}'.format(noise_idx))
    print('Capture lasts {} seconds'.format(t_end))
    return noise_idx, phase_offset_01_mean, phase_offset_02_mean, phase_offset_12_mean, t_end