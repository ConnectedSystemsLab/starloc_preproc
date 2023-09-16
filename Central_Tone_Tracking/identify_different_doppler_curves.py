from math import inf
from telnetlib import DO
from scipy import io as sio
from scipy.optimize import linear_sum_assignment
import numpy as np

peak_file_path = '/Users/ishani/UIUC/Research/starlink_ofdm/Central_Tone_Tracking/matlab.mat'
peak_array = sio.loadmat(peak_file_path)['peak_array']


def assign_peaks_to_tracks(peaks, tracks, dist_thresh):
    # fetch the last point from all track and create an array of "curr_points"
    curr_points = []
    for trk in tracks:
        curr_points.append(trk.track_points[-1])
    
    curr_points = np.array(curr_points)
    cost_matrix = np.empty((len(curr_points), len(peaks)))
    for i,curr_point in enumerate(curr_points):
        for j,next_point in enumerate(peaks):
                cost_matrix[i,j] = np.linalg.norm(curr_point-next_point)
    
    if min(cost_matrix.shape) > 0:
        a = (cost_matrix < dist_thresh).astype(np.int32)
        if a.sum(1).max() == 1 and a.sum(0).max() == 1:
            matched_indices = np.stack(np.where(a), axis=1)
        else:
            x, y = linear_sum_assignment(cost_matrix)
            matched_indices = np.array(list(zip(x, y)))
    else:
        matched_indices = np.empty(shape=(0,2))
    
    unmatched_peaks = []
    for p, peak in enumerate(peaks):
        if(p not in matched_indices[:,1]):
            unmatched_peaks.append(p)
    unmatched_tracks = []
    for t, trk in enumerate(tracks):
        if(t not in matched_indices[:,0]):
            unmatched_tracks.append(t)

    #filter out matched with high dist
    matches = []
    for m in matched_indices:
        if(cost_matrix[m[0], m[1]]>dist_thresh):
            unmatched_tracks.append(m[0])
            unmatched_peaks.append(m[1])
        else:
            matches.append(m.reshape(1,2))

    if(len(matches)==0):
        matches = np.empty((0,2),dtype=int)
    else:
        matches = np.concatenate(matches,axis=0)
    
    return matches, np.array(unmatched_peaks), np.array(unmatched_tracks)
    

class DopplerTrack(object):
    num_tracks = 0
    def __init__(self, stalesness_limit=25) -> None:
        self.track_id = DopplerTrack.num_tracks
        DopplerTrack.num_tracks += 1
        self.track_points = []
        self.staleness = 0
        self.staleness_limit = stalesness_limit

    def update(self, peak) -> None:
        # add peak to the track_points if there are elements in peak
        if len(peak) != 0 :
            self.track_points.append(peak)
            self.staleness = 0
        # if not, then increment the staleness
        # check if staleness limit is exceeded, if it has, then return "remove"
        else:
            self.staleness+=1


# TODO: set these parameters:
time = 1
step = 0.5
max_dist = 30
curr_tracks = []
all_tracks = [] 
fbin_hardware = 508
max_time_till_no_update = 40

for i in range(np.shape(peak_array)[0]):
    curr_peaks = np.vstack((np.ones(len(peak_array[i,:]))*time+step*(i-1), peak_array[i,:])).T
    curr_peaks =  np.array([curr_peaks[np.where(curr_peaks[:, 1] != 0), 0][0], np.where(curr_peaks[:, 1] != 0)[0]]).T
    curr_peaks = curr_peaks[np.where(curr_peaks[:, 1] != fbin_hardware)]
    
    if len(curr_tracks) == 0:
        # create new tracks for each peak
        for peak in curr_peaks:
            trk = DopplerTrack(stalesness_limit=max_time_till_no_update)
            trk.track_points.append(peak.tolist())
            curr_tracks.append(trk)
            
    else:
        matched, unmatched_peaks, unmatched_trks = assign_peaks_to_tracks(curr_peaks, curr_tracks, max_dist)
        for elem in matched:
            curr_tracks[elem[0]].update(curr_peaks[elem[1]].tolist()) # see if matched is a list
        
        for points in unmatched_peaks:
            # create new tracks
            trk = DopplerTrack(stalesness_limit=max_time_till_no_update)
            curr_tracks.append(trk)
            trk.update(curr_peaks[points].tolist())
        
        for trks in unmatched_trks:
            # increament track staleness
            curr_tracks[trks].update([])

    # remove stale tracks
    for i,track in enumerate(curr_tracks):
        if track.staleness > track.staleness_limit:
            all_tracks.append(curr_tracks.pop(i))

for i,track in enumerate(curr_tracks):
    all_tracks.append(curr_tracks.pop(i))

track_dict = {}
for track in all_tracks:
    track_dict["track_"+str(track.track_id)] = track.track_points
    print(track.track_id, ":", track.track_points, "\n")



output_tracks_file = "./output_tracks.mat"
sio.savemat(output_tracks_file, {'tracks_dict': track_dict})