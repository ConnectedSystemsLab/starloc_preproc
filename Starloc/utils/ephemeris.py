# This is a class to read the ephemeris data from the specified file and return the requested parts of the data.
import array
from datetime import datetime, timedelta
from tracemalloc import start
from matplotlib import lines
import pytz
import os
import zipfile
import linecache
import numpy as np
from skyfield.api import load, wgs84
from skyfield.units import Distance, Velocity
from skyfield.positionlib import ICRF, Geocentric

class EphemerisLoader:
    def __init__(self, file_path):
        self.file_path = file_path
        self.lines_to_skip = 4 # the number of lines to skip in the ephemeris file. These lines contain the header information
    
    def unzip_files(self):
        """
        Unzip the downloaded ephemeris files and save them in the 'unzipped' folder in the same directory as the zip files.

        """
        zip_folder_path = self.file_path
        output_folder_path = os.path.join(zip_folder_path, 'unzipped')
        # Create the output folder if it doesn't exist
        if not os.path.exists(output_folder_path):
            os.makedirs(output_folder_path)
        else:
            print(f'Output folder already exists: {output_folder_path}')
            return

        # List all files in the zip_folder_path
        zip_files = [file for file in os.listdir(zip_folder_path) if file.endswith('.zip')]

        # Loop through each zip file and extract its contents to the output folder
        for zip_file in zip_files:
            zip_file_path = os.path.join(zip_folder_path, zip_file)
            with zipfile.ZipFile(zip_file_path, 'r') as zip_ref:
                zip_ref.extractall(output_folder_path)

        print(f'Unzipped files saved in: {output_folder_path}')
    
    def find_one_sat(self, sat_id):
        """
        Find the ephemeris data for the specified satellite ID.

        :param sat_id: Satellite ID
        :return: Ephemeris data for the specified satellite ID
        """
        # Get the unzipped folder path
        unzipped_folder_path = os.path.join(self.file_path, 'unzipped')
        # List all files in the unzipped folder
        eph_files = [file for file in os.listdir(unzipped_folder_path) if file.endswith('.txt')]
        # Loop through each file and find the ephemeris data for the specified satellite ID
        for eph_file in eph_files:
            eph_file_sat_id = eph_file.split('_')[2]
            if eph_file_sat_id == sat_id:
                eph_file_path = os.path.join(unzipped_folder_path, eph_file)
                return eph_file_path
        return None

    def get_sat_position_velocity_at_t(self, eph_file_path, time):
        """
        Get the satellite position at the specified time.

        :param eph_file_path: Ephemeris file path
        :param time: Time in UTC in the form of utc timestamp(float)
        :return: Satellite position at the specified time
        """
        # get start time
        start_time = convert_ephemeristime_to_utctimestamp(linecache.getline(eph_file_path,5).split()[0])
        # determine the line number with the desired time
        line_number = int((time - start_time)/60)*4 + self.lines_to_skip + 1
        # skip to line with time
        line = linecache.getline(eph_file_path, line_number)
        # verify that time matches with time in file and return position
        if convert_ephemeristime_to_utctimestamp(line.split()[0]) == time:
            pos = np.array(line.split()[1:4], dtype=float)
            vel = np.array(line.split()[4:7], dtype=float)
            return pos, vel
        else:
            # if the query time doesn't match the time in the file, do interpolation using the two closest times
            # get the two closest times
            line_number_l = line_number
            line_number_r = line_number + 4
            time_l = convert_ephemeristime_to_utctimestamp(linecache.getline(eph_file_path, line_number_l).split()[0])
            time_r = convert_ephemeristime_to_utctimestamp(linecache.getline(eph_file_path, line_number_r).split()[0])
            # get the two closest positions
            pos_l = np.array(linecache.getline(eph_file_path, line_number_l).split()[1:4], dtype=float)
            pos_r = np.array(linecache.getline(eph_file_path, line_number_r).split()[1:4], dtype=float)
            vel_l = np.array(linecache.getline(eph_file_path, line_number_l).split()[4:7], dtype=float)
            vel_r = np.array(linecache.getline(eph_file_path, line_number_r).split()[4:7], dtype=float)
            pos = np.array([])
            for i in range(3):
                pos = np.append(pos, self.makima(time_l, time_r, pos_l[i], pos_r[i], vel_l[i], vel_r[i], time))
            vel = np.array([])
            for i in range(3):
                vel = np.append(vel, np.interp(time, [time_l, time_r], [vel_l[i], vel_r[i]]))
            # print(f'Error: Time {time} not found in ephemeris file {eph_file_path}')
            return pos, vel
           
    def convert_sat_position_velocity_to_skyfieldformat(self, pos, vel, skyfieldtime):
        """
        Convert the satellite position to the Skyfield format.

        :param pos: Satellite position at time
        :param skyfieldtime: Time in the Skyfield format timescale.utc()
        :return: Satellite position in the Skyfield format
        """
        pos = Distance(km = pos)
        vel = Velocity(km_per_s = vel)
        sat_pos = Geocentric(pos.au, vel.au_per_d, t=skyfieldtime)
        sat_pos = Geocentric(pos.au, t=skyfieldtime)
        return sat_pos
    
    def is_unzipped(self):
        return os.path.exists(os.path.join(self.file_path, 'unzipped'))
    
    def makima(self, x_l, x_r, y_l, y_r, y_dot_l, y_dot_r, x_q):
        """
        Interpolate using the Makima method.

        :param x_l: Left x value
        :param x_r: Right x value
        :param y_l: Left y value
        :param y_r: Right y value
        :param y_dot_l: Left y dot value
        :param y_dot_r: Right y dot value
        :param x_q: Query x value
        :return: Interpolated y value
        """
        x_l_ = x_l - x_q
        x_r_ = x_r - x_q
        M = np.array([[x_l_**3, x_l_**2, x_l_, 1], [x_r_**3, x_r_**2, x_r_, 1], [3*x_l_**2, 2*x_l_, 1, 0], [3*x_r_**2, 2*x_r_, 1, 0]])
        y = np.array([y_l, y_r, y_dot_l, y_dot_r])
        a = np.linalg.solve(M, y)
        y_q = a[3]

        return y_q


def convert_ephemeristime_to_utctimestamp(yyyyDOYhhmmss: str) -> float:
    yyyy = int(yyyyDOYhhmmss[0:4])
    DOY = int(yyyyDOYhhmmss[4:7])
    hh = int(yyyyDOYhhmmss[7:9])
    mm = int(yyyyDOYhhmmss[9:11])
    ss = int(yyyyDOYhhmmss[11:13])
    utc_time = datetime(yyyy, 1, 1, hh, mm, ss, tzinfo=pytz.utc) + timedelta(DOY - 1)
    utc_timestamp = datetime.timestamp(utc_time)
    return utc_timestamp