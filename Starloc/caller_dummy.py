
def call_ephemeris_and_unzip():
    from utils.ephemeris import EphemerisLoader
    zip_folder_path = '/home/ishani/LeoPNT/USRP_data/2_20/ephemeris'
    eph = EphemerisLoader(zip_folder_path) # creates an instance of EphemerisLoader. More details in utils/ephemeris.py
    # eph.unzip_files(output_folder_path) # use the unzip_files() method to unzip the ephemeris files
    print(eph.is_unzipped())
    sat_id = 'STARLINK-1013'
    eph_file_path = eph.find_one_sat(sat_id) # use the find_one_sat() method to find the ephemeris data for the specified satellite ID
    print(eph_file_path)
    time = '2024051170742.000'
    from utils.ephemeris import convert_ephemeristime_to_utctimestamp
    time = convert_ephemeristime_to_utctimestamp(time)
    print(time)
    from skyfield.api import load
    ts = load.timescale()
    t = ts.utc(2024, 2, 20, 23, 33, 42)
    pos, vel = eph.get_sat_position_velocity_at_t(eph_file_path, time)
    print(pos, vel)
    skyfield_pos = eph.convert_sat_position_velocity_to_skyfieldformat(pos, vel, t)


if __name__ == "__main__":

    # call_imu_data()
    # call_calibration()
    call_ephemeris_and_unzip()