import os
import argparse
import json
import scipy.io as sio
import numpy as np
from typing import Final
from utils.imu_data import IMUData

def save_calibration_phases_and_capture_duration():
    """
     Extract Calibration Siganl phase from IQ files. 
    """

    from utils.calibration import CalibrationSignal

    ## Create instance of CalibrationSignal for each iq file. More details in utils/calibration.py
    calib_signals = [CalibrationSignal(iq_filepaths[0], fc, tx_freq, sample_rate), CalibrationSignal(iq_filepaths[1], fc, tx_freq, sample_rate), CalibrationSignal(iq_filepaths[2], fc, tx_freq, sample_rate)]
    ## Getting calib/ref signal indexes (startidx, stopidx, transmit interval) for each time that the calibration signal is transmittes
    calibsig_idxs = [calib_signals[0].get_all_refsigidx(), calib_signals[1].get_all_refsigidx(), calib_signals[2].get_all_refsigidx()]
    ## Calculate total secs of capture
    capture_secs =  calibsig_idxs[0][-1][1] / sample_rate # seconds after start of capture when calibration signal stops transmitting

    ## Get phase of calibration signal at each calib/ref signal index
    ref_sig_idxs = calibsig_idxs[0]
    calibsig_phases = [calib_signals[0].get_refsig_phase(ref_sig_idxs), calib_signals[1].get_refsig_phase(ref_sig_idxs), calib_signals[2].get_refsig_phase(ref_sig_idxs)]
    phase_offset_01 = np.unwrap(calibsig_phases[0]-calibsig_phases[1])
    phase_offset_21 = np.unwrap(calibsig_phases[2]-calibsig_phases[1])

    # save the ref_sig_idxs and calibration phases as .mat file
    sio.savemat(os.path.join(intermediate_results_folder, "calibration_intermediate.mat"), \
        {"ref_sig_idx": ref_sig_idxs, \
        "phase_offset_01": phase_offset_01, \
        "phase_offset_21": phase_offset_21, \
        "capture_duration": capture_secs})
    print("Calibration phases saved to: ", os.path.join(intermediate_results_folder, "calibration_intermediate.mat"))


def get_all_sat_dopplers():
    """
    Save the doppler profiles of all satellites visible during the observation. 
    We use this to find the satellite ID and the ground truth location of the satellite.
    """
    from utils.sat_simulation import faster_doppler_sim
    
    calibration_matfile = os.path.join(intermediate_results_folder, "calibration_intermediate.mat")
    calibration_mat = sio.loadmat(calibration_matfile)
    capture_duration = calibration_mat["capture_duration"].item()
    print("Capture duration: ", capture_duration)

    sat_dopp_dict, t_list = faster_doppler_sim(tle_path=tle_filepath, 
                                           fc=fc, 
                                           t_start=start_time, 
                                           t_stop=start_time+capture_duration, 
                                           t_step=1, 
                                           ground_station=(lat_gs, lon_gs))

    output_doppler_file = os.path.join(intermediate_results_folder, "output_doppler.mat")
    sio.savemat(output_doppler_file, {'sat_dopp_dict': sat_dopp_dict, 't_list': t_list})
    print("All satellite Doppler profiles saved to: ", output_doppler_file)

    
def detect_and_track_centertones():
    """
    Detect and track the centertones from the raw IQ data, and then assign them to unique satellites.
    """
    # first track the centertones from the raw IQ data
    from utils.track_centertones import track_centertones_from_raw_data
    
    calibration_matfile = os.path.join(intermediate_results_folder, "calibration_intermediate.mat")
    num_read_samples = nfft
    track_centertones_from_raw_data(iq_filepaths, sample_rate, num_read_samples, calibration_matfile, intermediate_results_folder)
    
    # now assign the tracked centertones to unique satellites
    from utils.track_centertones import get_persat_centertones_and_ids
    get_persat_centertones_and_ids(centertones_matfile=os.path.join(intermediate_results_folder, "centertones.mat"), 
                                   output_doppler_matfile=os.path.join(intermediate_results_folder, "output_doppler.mat"),
                                   results_dir=intermediate_results_folder, 
                                   period_starts=obs_periods['period_starts'], 
                                   period_ends=obs_periods['period_ends'],
                                   sample_rate=sample_rate, 
                                   fc=fc, 
                                   d=d, 
                                   nfft=nfft)
    
def collect_main_files():
    """
    Collect all the main files from the intermediate results folder and save them to the results folder. 
    These are the matfiles that are used for the next steps of the pipeline.
    """

    # collect necessary stuff from calibration.mat
    calibration_matfile = os.path.join(intermediate_results_folder, "calibration_intermediate.mat")
    calibration_mat = sio.loadmat(calibration_matfile)
    
    sio.savemat(os.path.join(results_folder, "calibration.mat"), \
        {"ref_sig_idx": calibration_mat["ref_sig_idx"], \
        "phase_offset_01": calibration_mat["phase_offset_01"], \
        "phase_offset_21": calibration_mat["phase_offset_21"]})

    print("\n ======== Raw signal processing complete ======== \n")
    print("calibration.mat needed in StarLoc localization saved to: ", os.path.join(results_folder, "calibration.mat"))

    # collect necessary stuff from persat_centertones_and_ids.mat
    persat_centertones_and_ids_matfile = os.path.join(intermediate_results_folder, "persat_centertones_and_ids.mat")
    persat_centertones_and_ids_mat = sio.loadmat(persat_centertones_and_ids_matfile)
    
    sio.savemat(os.path.join(results_folder, "tracked_tones.mat"), \
        {"tones_dict": persat_centertones_and_ids_mat["dopp_track_dict"], \
        "main_tone_dict": persat_centertones_and_ids_mat["dopp_track_main_dict"], \
        "id_dict": persat_centertones_and_ids_mat["id_dict"]})
    
    print("tracked_tones.mat needed in StarLoc localization saved to: ", os.path.join(results_folder, "tracked_tones.mat"))
    
    

if __name__ == "__main__":
    # parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--obs_folder", type=str, default="/home/ishani/starloc_dataset/obs_0", \
        help="Path to the observation folder containing raw IQ data files")
    parser.add_argument("--results_folder", type=str, default="../data/12Mar2024_23_17", \
        help="Path to the output folder where results will be saved")
    parser.add_argument("--config_file", type=str, default="./config.json", \
        help="Path to the JSON configuration file with basic hardware")
    args = parser.parse_args()
    obs_folder = args.obs_folder
    results_folder = args.results_folder
    intermediate_results_folder = os.path.join(results_folder, "intermediate_results")

    # create results folder if it doesn't exist
    if not os.path.exists(results_folder):
        print("Results folder does not exist, creating it")
        os.makedirs(results_folder)
    
    # create intermediate results folder if it doesn't exist
    if not os.path.exists(intermediate_results_folder):
        print("Intermediate results folder does not exist, creating it")
        os.makedirs(intermediate_results_folder)
    
    # Load config file and the parameters should be globally available. 
    # Also preventing re-write of these variables, so I don't accidentaly modify or re-use the same variable name
    with open(args.config_file, 'r') as f:
        config = json.load(f)
        iq_filepaths = [os.path.join(obs_folder, f) for f in os.listdir(obs_folder) if f.endswith('.dat')]
        iq_filepaths.sort()
        print("IQ files found: ", iq_filepaths)
        imu_filepath = os.path.join(obs_folder, [f for f in os.listdir(obs_folder) if f.endswith('.txt') and 'imu' in f.lower()][0])
        print("IMU file found: ", imu_filepath)
        tle_filepath = os.path.join(obs_folder, [f for f in os.listdir(obs_folder) if f.endswith('.tle')][0])
        print("TLE file found: ", tle_filepath)
        print("\n-------------------\n")
        # start_time of the observation
        start_time = float(iq_filepaths[0].split('_')[-2]) # utc epoch second at time of capture
        print("Start time of the observation: ", start_time)

        #get satellite observation windows
        obs_periods_filepath = config['obs_periods_filepath']
        with open(obs_periods_filepath, 'r') as _f:
            _obs_periods = json.load(_f)
        # extract the date key format from the filename (e.g. 12Mar2024_23_17)
        _filename_parts = os.path.basename(iq_filepaths[0]).split('_')
        _date_key = f"{_filename_parts[1]}_{_filename_parts[2]}_{_filename_parts[3]}"
        obs_periods = _obs_periods[_date_key]
        
        # get lat_lon from imu file
        imu = IMUData(imu_filepath)
        imu_data = imu.read_imu_data()
        lat, lon, alt = imu.get_latlonalt_()
        lat_gs, lon_gs, alt_gs = np.mean(lat), np.mean(lon), np.mean(alt)
        print("Ground station lat, lon, alt: ", lat_gs, lon_gs, alt_gs)
        
        fc: Final = config['hw_parameters']['center_freq']
        tx_freq: Final = config['hw_parameters']['calibsig_freq']
        sample_rate: Final = config['hw_parameters']['sample_rate']
        d: Final = config['hw_parameters']['antenna_spacing_meters']
        stft_win: Final = config['hw_parameters']['stft_win']
        nfft: Final = int(sample_rate*stft_win)
        c: Final = 299792458 # speed of light in m/s
    
    ### ======================================================= ###
    ### STEP 1: Extract Calibration Siganl phase from IQ files. ###
    ### ======================================================= ###
    save_calibration_phases_and_capture_duration()

    ### ======================================================= ###
    ### STEP 2: Get all satellite dopplers.                     ###
    ### ======================================================= ###
    get_all_sat_dopplers()

    ### ======================================================= ###
    ### STEP 3: Track the center tones from the raw IQ data.
    ###         and assign them to unique satellites.           ###
    ### ======================================================= ###
    detect_and_track_centertones()

    ### ======================================================= ###
    ### STEP 4: Collect all the main files from the intermediate results folder and save them to the results folder. 
    ###         These are the matfiles that are used for the main StarLoc localization pipeline.
    ### ======================================================= ###
    collect_main_files()

    

