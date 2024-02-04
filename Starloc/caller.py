
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

if __name__ == "__main__":

    # call_imu_data()
    call_calibration()
