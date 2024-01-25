import numpy as np
import matplotlib.pyplot as plt
import scipy.signal as signal
def calc_AoA(iq0, iq1, iq2, d_02, d_12, lam, phase_offset_02, phase_offset_12):
    """
    iq2------iq1
    |
    |
    |
    iq0
    """

    num_ambiguity_1 = int(d_02/(lam/2))
    num_ambiguity_2 = int(d_12/(lam/2))
    del_phi_1 = np.zeros((num_ambiguity_1, len(iq0)))
    del_phi_2 = np.zeros((num_ambiguity_2, len(iq0)))
    pattern_1 = np.unwrap(np.angle(iq0/iq2))
    pattern_2 = np.unwrap(np.angle(iq1/iq2))
    phi_bound_1 = np.pi*num_ambiguity_1
    phi_bound_2 = np.pi*num_ambiguity_2

    # calculate all possible delta_phis
    for i in range(num_ambiguity_1):
        del_phi_1[i, :] = pattern_1 + 2*np.pi*(i-num_ambiguity_1//2)
    print(np.mean(del_phi_1[-1, :]))
    if np.mean(del_phi_1[-1, :]) > phi_bound_1:
        del_phi_1 = del_phi_1 - 2*np.pi
    plt.figure()
    for i in range(num_ambiguity_1):
        plt.plot(del_phi_1[i, :])
    plt.hlines(-phi_bound_1, 0, len(iq0)-1, linestyles='dashed', colors='brown', label='lower bound')
    plt.hlines(phi_bound_1, 0, len(iq0)-1, linestyles='dashed', colors='brown', label='lower bound')
    plt.legend()
    plt.title('All possible phase difference - 1')
    plt.show()

    for i in range(num_ambiguity_2):
        del_phi_2[i, :] = pattern_2 + 2*np.pi*(i-num_ambiguity_2//2)
    if pattern_2[0] < 0:
        del_phi_2 = del_phi_2 + 2*np.pi
    plt.figure()
    for i in range(num_ambiguity_2):
        plt.plot(del_phi_2[i, :])
    plt.hlines(-np.pi*num_ambiguity_2, 0, len(iq0)-1, linestyles='dashed', colors='brown', label='lower bound')
    plt.hlines(np.pi*num_ambiguity_2, 0, len(iq0)-1, linestyles='dashed', colors='brown', label='lower bound')
    plt.legend()
    plt.title('All possible phase difference - 2')
    plt.show()

def calc_AoA_2(del_phi_01, del_phi_02, d_01, d_02, lam, phase_offset_01, phase_offset_02):
    """
    iq2------iq1
    |
    |
    |
    iq0

    to reuse the previous code, here 1 means direction 0-2, 2 means direction 1-2
    """
    phi_bound_1 = d_01/lam*2*np.pi*np.sin(np.deg2rad(20))
    phi_bound_2 = d_02/lam*2*np.pi*np.sin(np.deg2rad(20))
    num_ambiguity_1 = np.ceil(phi_bound_1/(np.pi)).astype(int)
    num_ambiguity_2 = np.ceil(phi_bound_2/(np.pi)).astype(int)
    phi_bias_1 = np.zeros((num_ambiguity_1, 1))
    phi_bias_2 = np.zeros((num_ambiguity_2, 1))
    pattern_1 = np.unwrap(np.mod(del_phi_01-phase_offset_01, 2*np.pi))
    pattern_2 = np.unwrap(np.mod(del_phi_02-phase_offset_02, 2*np.pi))
    # pattern_1 = np.unwrap(np.angle(iq0/iq2*np.exp(-1j*phase_offset_02)))
    # pattern_2 = np.unwrap(np.angle(iq1/iq2*np.exp(-1j*phase_offset_12)))
    d_1, d_2 = d_01, d_02

    # average the pattern
    # avg_window_len = int(1)
    # pattern_1 = signal.filtfilt(np.ones(avg_window_len)/avg_window_len, 1, pattern_1)
    # pattern_2 = signal.filtfilt(np.ones(avg_window_len)/avg_window_len, 1, pattern_2)
    # calculate all possible delta_phis
    for i in range(num_ambiguity_1):
        phi_bias_1[i] = 2*np.pi*(i-num_ambiguity_1//2)
    if np.mean(pattern_1+phi_bias_1[0]) < -phi_bound_1:
        phi_bias_1 += 2*np.pi
    for i in range(num_ambiguity_2):
        phi_bias_2[i] = 2*np.pi*(i-num_ambiguity_2//2)
    if np.mean(pattern_2+phi_bias_2[0]) < -phi_bound_2:
        phi_bias_2 += 2*np.pi
        
    # plt.figure()
    # for i in range(num_ambiguity_1):
    #     plt.plot(pattern_1 + phi_bias_1[i])
    # plt.hlines(-phi_bound_1, 0, len(iq0)-1, linestyles='dashed', colors='brown', label='lower bound')
    # plt.hlines(phi_bound_1, 0, len(iq0)-1, linestyles='dashed', colors='brown', label='lower bound')
    # plt.legend()
    # plt.title('All possible phase difference - 1')
    # plt.show()
    # plt.figure()
    # for i in range(num_ambiguity_2):
    #     plt.plot(pattern_2 + phi_bias_2[i])
    # plt.hlines(-phi_bound_2, 0, len(iq0)-1, linestyles='dashed', colors='brown', label='lower bound')
    # plt.hlines(phi_bound_2, 0, len(iq0)-1, linestyles='dashed', colors='brown', label='lower bound')
    # plt.legend()
    # plt.title('All possible phase difference - 2')
    # plt.show()

    # calculate AoA
    # first check which del_phi exceeds the bounds, exclude those
    for i in range(num_ambiguity_1):
        del_phi_1_i = pattern_1 + phi_bias_1[i]
        if np.max(del_phi_1_i) > phi_bound_1 or np.min(del_phi_1_i) < -phi_bound_1:
            phi_bias_1[i] = np.nan
    for i in range(num_ambiguity_2):
        del_phi_2_i = pattern_2 + phi_bias_2[i]
        if np.max(del_phi_2_i) > phi_bound_2 or np.min(del_phi_2_i) < -phi_bound_2:
            phi_bias_2[i] = np.nan
    phi_bias_1 = phi_bias_1[~np.isnan(phi_bias_1)]
    phi_bias_2 = phi_bias_2[~np.isnan(phi_bias_2)]
    num_ambiguity_2d = len(phi_bias_1) * len(phi_bias_2)
    print('Number of del_phi_1 ambiguities: '+str(len(phi_bias_1)))
    print('Number of del_phi_2 ambiguities: '+str(len(phi_bias_2)))

    # then do the formula based AoA estimation
    phi, az, el = np.zeros((num_ambiguity_2d, len(del_phi_01))), np.zeros((num_ambiguity_2d, len(del_phi_01))), np.zeros((num_ambiguity_2d, len(del_phi_01)))
    for i in range(len(phi_bias_1)):
        for j in range(len(phi_bias_2)):
            del_phi_1_i = pattern_1 + phi_bias_1[i]
            del_phi_2_j = pattern_2 + phi_bias_2[j]
            phi_ = np.arctan2(-del_phi_2_j/d_2, -del_phi_1_i/d_1)
            phi_ = np.mod(phi_, 2*np.pi)
            # az_ = 2*np.pi-phi_
            az_ = phi_
            # elevation
            el_ = np.arccos(-del_phi_1_i*lam/(2*np.pi*d_1*np.cos(az_)))
            az[i*len(phi_bias_2)+j, :] = az_
            el[i*len(phi_bias_2)+j, :] = el_
            
    return az, el, len(phi_bias_1)*len(phi_bias_2)