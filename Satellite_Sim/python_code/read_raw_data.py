import re
import numpy as np

def read_dat_file(file_path, start_index=None, end_index=None):
    """
    Reads complex data from a .dat file and returns an array of complex numbers.
    """
    if start_index is None:
        start_index = 0
    if end_index is None:
        end_index = len(iq)-1

    print(start_index, end_index)

    f = open(file_path, 'rb')
    # read file from start_index to end_index
    iq = np.fromfile(f, offset=start_index*4*2, count=(end_index-start_index)*2, dtype=np.float32)
    # iq = np.fromfile(f, offset=start_index*4*2, dtype=np.float32)
    iq = iq.reshape((-1, 2))  # Reshape to get pairs of floats for each complex number
    
    iq = iq[:,0] + 1j*iq[:,1]
    f.close()

    return iq

