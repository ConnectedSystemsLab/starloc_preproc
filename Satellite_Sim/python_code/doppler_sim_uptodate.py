from turtle import st
from skyfield.api import load, wgs84
from numpy import array2string
from datetime import datetime, timedelta
# from get_temp_press import get_nexthour_temp_press
import os
from scipy import io as sio

c = 299792458
fc = 11.325e9
url = "https://celestrak.org/NORAD/elements/supplemental/sup-gp.php?FILE=starlink&FORMAT=tle" #  need to replace with old tle depending on they day when you recorded data
path = "/Users/ishani/UIUC/Research/starlink_ofdm/Sat_Identify/tles/9_14/Starlink.tle"
satellites = load.tle_file(path) # either use path to tle or directly fetch latest tle from the url
print(satellites)
print(len(satellites))
# print(satellites)
open_satfile_list = []
siebel_lat, siebel_lon = (+40.11389690596162, -88.22484814695467)
bagels_lat, bagels_lon = (+40.11398436467024, -88.22459037110089)
siebel = wgs84.latlon(siebel_lat, siebel_lon) 
bagels = wgs84.latlon(+40.11398436467024, -88.22459037110089)
gs =  siebel # change
ts = load.timescale()
t_start = t = ts.utc(2023, 9, 14, 11, 27, 5) # TODO: add 5 hours for UTC time BROOO!!!! utc time format #change 
t_start = t = ts.utc(t_start.utc_datetime() + timedelta(hours=5)) 
t_stop = ts.utc(2023, 9, 14, 11, 27+8, 5)# utc time format #change
t_stop = ts.utc(t_stop.utc_datetime() + timedelta(hours=5)) 
t_step = 0.5 # in seconds #change

# t_start_datetime = t_datetime = datetime(2023, 3, 16, 15, 0, 0) #change
loc = (siebel_lat, siebel_lon) #change

results_folder = 'sim_outputs/gs_siebel-tstart_'+str(t_start.utc_datetime())+'-tstop_'+str(t_stop.utc_datetime())+'-t_step_'+str(t_step)
if not(os.path.exists(results_folder)):
    os.mkdir(results_folder)

sat_dopp_dict={}
sec_into_sim = -0.5
while True:
    sec_into_sim = sec_into_sim + t_step
    # temperature, pressure = get_nexthour_temp_press(loc, t_datetime)
    
    for satellite in satellites:
        # get all starlink sats that were above horizon at 1:37:51 CST / 7:37:51 pm UTC
        # get range rates for them and calculate doppler shift
        dist = (satellite-gs).at(t)
        alt, az, distance = dist.altaz() # include atmospheric temperature and pressure. Why? If you want Skyfield to estimate how high the atmosphere might lift the body’s image, give the argument temperature_C either the temperature in degrees centigrade, or the string 'standard' (in which case 10°C is used).
        # alt, az, distance = dist.altaz()
        if alt.degrees>60:
            # print('------------')
            # print('SAT:', satellite.name, '\tElev: ', alt.degrees, '\tAz: ', az.degrees)
            _, _, the_range, _, _, range_rate = dist.frame_latlon_and_rates(gs)
            # print(array2string(the_range.km, precision=2), 'km', "\t Distance = ", "Dist =", distance )
            # print(array2string(range_rate.km_per_s, precision=10), 'km/s')
            doppler_shift = fc*range_rate.km_per_s*1000/c #convert to m/s
            # print("doppler shift = ", doppler_shift)
            f = str(satellite.name)+".csv"
        
            if f in open_satfile_list:
                with open(os.path.join(results_folder,f),mode='a') as sat_file:
                    row = str(t.utc_datetime()) + "," + str(wgs84.subpoint(satellite.at(t)).latitude) + "," + str(wgs84.subpoint(satellite.at(t)).longitude) + "," + str(alt.degrees) + "," + str(az.degrees) + "," + array2string(the_range.km, precision=10) + "," + array2string(range_rate.km_per_s, precision=10) + "," + str(doppler_shift) + "\n"
                    sat_file.write(row)
                sat_dopp_dict["S_"+str(satellite.name).split("-")[1]].append([sec_into_sim, doppler_shift])
                # print(str(satellite.name).split("-")[1], range_rate.km_per_s, the_range.km)
                
                # sat_file.close()
            else:
                with open(os.path.join(results_folder,f),mode='w') as sat_file:
                    header = "Time" + "," + "Sat Lat" + "," + "Sat Lon" + "," + "Sat Elev" + "," + "Sat Az" + "," + "Dist/Range" + "," + "Range Rate (km/s)" + "," + "Doppler Shift (Hz)" + "\n"
                    row = str(t.utc_datetime()) + "," + str(wgs84.subpoint(satellite.at(t)).latitude) + "," + str(wgs84.subpoint(satellite.at(t)).longitude) + "," + str(alt.degrees) + "," + str(az.degrees) + "," + array2string(the_range.km, precision=10) + "," + array2string(range_rate.km_per_s, precision=10) + "," + str(doppler_shift) + "\n"
                    sat_file.write(header)
                    sat_file.write(row)
                    open_satfile_list.append(f)
                sat_dopp_dict["S_"+str(satellite.name).split("-")[1]] = []   
                sat_dopp_dict["S_"+str(satellite.name).split("-")[1]].append([sec_into_sim, doppler_shift])
                # sat_file.close()
        else:
            continue    
            
    # update t
    # print("out of while")
    t = ts.utc(t.utc_datetime() + timedelta(seconds=t_step)) 
    # print(t)
    # t_datetime = t_datetime + timedelta(seconds=t_step)
    print(str(t.utc_datetime()), str(t_stop.utc_datetime()))
    if t.utc_datetime() >= t_stop.utc_datetime():
        break

sat_dopp_file = "./sat_dopp_dict_.mat"
print(sat_dopp_dict)
sio.savemat(sat_dopp_file, {'sat_dopp_dict': sat_dopp_dict})