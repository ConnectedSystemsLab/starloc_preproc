import re
import numpy as np

def read_dat_file(file_path, start_index=None, end_index=None):
    """
    Reads complex data from a .dat file and returns an array of complex numbers.
    """
    f = open(file_path, 'rb')
    iq = np.fromfile(f, dtype=np.float32)
    iq = iq.reshape((-1, 2))  # Reshape to get pairs of floats for each complex number
    
    if start_index is None:
        start_index = 0
    if end_index is None:
        end_index = len(iq)
    
    iq = iq[start_index:end_index,0] + 1j*iq[start_index:end_index,1]

    return iq
