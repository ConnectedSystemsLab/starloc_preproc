
def call_imu_data():
    from utils.imu_data import IMUData
    imu = IMUData('/home/ishani/LeoPNT/USRP_data/2_3/imu_20240203233508.txt') # creates an instance of IMUData
    imu_data = imu.read_imu_data() # reads all imu data from the file. More details in utils/imu_data.py 
    attitude = imu.get_attitude() # use the get_attitude() method to get the yaw pitch and roll data
    import numpy as np  
    mean_attuitude = [np.mean(attitude[0]), np.mean(attitude[1]), np.mean(attitude[2])]
    print(mean_attuitude)
    time = imu.get_utctimestamp() # use the get_utctimestamp() method to get the timestamp data

    latlong = imu.get_latlonalt()

def call_calibration():
    from utils.calibration import CalibrationSignal
    filepath ='/home/ishani/LeoPNT/USRP_data/2_3/utctime_3Feb2024_22:03:48_freq_11_325G_bw_2.0M_ts_1706997828.7235794_inrx0.dat'
    center_freq_rx = 11.325e9
    tx_freq = 11.3252e9
    sample_rate = 2e6
    cal = CalibrationSignal(filepath, center_freq_rx, tx_freq, sample_rate) # creates an instance of CalibrationSignal. More details in utils/calibration.py 
    ref_sig_idx = cal.get_all_refsigidx() # use the get_all_refsigidx() method to get the start and stop index of the reference signal
    print(ref_sig_idx) 

def call_ephemeris_and_unzip():
    from utils.ephemeris import EphemerisLoader
    zip_folder_path = '/home/ishani/LeoPNT/USRP_data/2_20/ephemeris'
    eph = EphemerisLoader(zip_folder_path) # creates an instance of EphemerisLoader. More details in utils/ephemeris.py
    # eph.unzip_files(output_folder_path) # use the unzip_files() method to unzip the ephemeris files
    print(eph.is_unzipped())
    sat_id = 'STARLINK-2377'
    eph_file_path = eph.find_one_sat(sat_id) # use the find_one_sat() method to find the ephemeris data for the specified satellite ID
    print(eph_file_path)

if __name__ == "__main__":

    # call_imu_data()
    # call_calibration()
    call_ephemeris_and_unzip()
