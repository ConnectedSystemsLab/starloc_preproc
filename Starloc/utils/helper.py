# helper functions for generic tasks

def get_distkm_latlon_coordinates(location_coords1, location_coords2):
    """
    Calculate distance between two sets of gps coordinates in km
    :param location_coords1: numpy array [lat, lon] of location(s) 1 in degrees. If multiple locations, it should be a 2D array with shape (n, 2)
    :param location_coords2: numpy array [lat, lon] of location(s) 2 in degrees
    """
    # convert all coordinates in radians
    import numpy as np
    # check if the input is 2D numpy array, if not convert it to 2D numpy array
    if not isinstance(location_coords1, np.ndarray) or len(location_coords1.shape) == 1:
        location_coords1 = np.array(location_coords1, dtype=np.float64)
        location_coords1 = location_coords1.reshape(-1, 2)
    if not isinstance(location_coords2, np.ndarray) or len(location_coords2.shape) == 1:
        location_coords2 = np.array(location_coords2, dtype=np.float64)
        location_coords2 = location_coords2.reshape(-1, 2)
    
    lat1 = np.deg2rad(location_coords1[:, 0])
    lon1 = np.deg2rad(location_coords1[:, 1])
    lat2 = np.deg2rad(location_coords2[:, 0])
    lon2 = np.deg2rad(location_coords2[:, 1])

    dlat = lat1 - lat2
    dlon = lon1 - lon2
    a = np.sin(dlat/2)**2 + np.cos(lat1) * np.cos(lat2) * np.sin(dlon/2)**2
    dist = 2 * np.arcsin(np.sqrt(a))*6371 # in km

    return dist
    
def diff_discrete_doppler(dopp_track):
    """
    Differentiate a discrete doppler track (that is not continuous and has missing values in between). 
    First the doppler track is made continuous by doing a polynomial fit. 
    The differentiation is done by taking the difference between consecutive values.
    
    :param dopp_track: 2D numpy array of time, doppler values
    """
    import numpy as np
    t = dopp_track[:, 0].real 
    dopp = dopp_track[:, 1].real
    t_start, t_end = np.min(t), np.max(t)
    p = np.polyfit(t, dopp, 3, w=np.abs(dopp_track[:, 2])**2)
    t_ = np.arange(t_start, t_end, 0.001)
    dopp_ = np.polyval(p, t_)
    dopp_diff = np.diff(dopp_) / np.diff(t_)
    t_diff = t_[:-1] + 0.5 * np.diff(t_)
    return np.column_stack((t_diff, dopp_diff)), p