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
            print(f'Error: Time {time} not found in ephemeris file {eph_file_path}')
            return None
           
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
        return sat_pos
    
    def is_unzipped(self):
        return os.path.exists(os.path.join(self.file_path, 'unzipped'))
    


def convert_ephemeristime_to_utctimestamp(yyyyDOYhhmmss: str) -> float:
    yyyy = int(yyyyDOYhhmmss[0:4])
    DOY = int(yyyyDOYhhmmss[4:7])
    hh = int(yyyyDOYhhmmss[7:9])
    mm = int(yyyyDOYhhmmss[9:11])
    ss = int(yyyyDOYhhmmss[11:13])
    utc_time = datetime(yyyy, 1, 1, hh, mm, ss, tzinfo=pytz.utc) + timedelta(DOY - 1)
    utc_timestamp = datetime.timestamp(utc_time)
    return utc_timestamp