import numpy as np
import matplotlib.pyplot as plt

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