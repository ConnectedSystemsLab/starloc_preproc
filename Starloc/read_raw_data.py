import numpy as np

def read_dat_file(file_path, count=None, start_index=None):
    """
    Reads complex data from a .dat file and returns an array of complex numbers.
    :param file_path: path to the .dat file
    :param count: number of complex numbers to read
    :param start_index: index to start reading from
    """
    if start_index is None:
        start_index = 0

    if count is None:
        count = -1
        
    f = open(file_path, 'rb')
    f.seek(4 * 2 * start_index, 0)
    data = np.fromfile(f, dtype=np.float32, count=2 * count)
    f.close()

    i = data[::2]
    q = data[1::2]
    iq = i + 1j * q

    return iq
