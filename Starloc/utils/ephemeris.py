# This is a class to read the ephemeris data from the specified file and return the requested parts of the data.
import os
import zipfile

class EphemerisLoader:
    def __init__(self, file_path):
        self.file_path = file_path
    
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

    def get_sat_position(self, eph_file_path, time):
        """
        Get the satellite position at the specified time.

        :param eph_file_path: Ephemeris file path
        :param time: Time in UTC
        :return: Satellite position at the specified time
        """
        with open(eph_file_path, 'r') as eph_file:
            # Read the ephemeris data
            eph_data = eph_file.readlines()
            # Loop through each line of the ephemeris data
            for line in eph_data:
                # Split the line by space
                line_split = line.split()
                # Check if the line contains the satellite position at the specified time
                if line_split[0] == time:
                    # Return the satellite position
                    return line_split[1:4]
        return None

    def is_unzipped(self):
        return os.path.exists(os.path.join(self.file_path, 'unzipped'))