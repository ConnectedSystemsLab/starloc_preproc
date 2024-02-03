#!/bin/sh

month="2"
day="2"
runtime=20
echo run time: $runtime
destpath="/home/ishani/LeoPNT/USRP_data/${month}_${day}"
echo "Destination path: $destpath"
log_ts=$(date -u +%Y%m%d%H%M%S)
# create folder for day is not already present
mkdir -p $destpath
# also make a folder for log files
mkdir -p $destpath/log_files


# source /home/ishani/prefix-3.10-new/setup_env.sh
# start the reference signal generator script
nohup python3 -u USRP/ref_sig.py > ref_sig.log 2>&1 &
# Save the process ID of the last background command
refsig_pid=$! 

# start the imu capture script
# imu log file
imu_log_file="$destpath/imu_"$(date -u +%Y%m%d%H%M%S)".mtb"
echo "IMU log file: $imu_log_file"
nohup python3 -u IMU/receive_from_IMU.py --logfilename $imu_log_file --run_for_secs $runtime > imu_capture.log 2>&1 &
# Save the process ID of the last background command
imucapture_pid=$!

# start the starloCapture script
nohup python3 -u USRP/usrp_x310s_capture.py --month $month --day $day > usrp_x310s_capture.log 2>&1 &
# Save the process ID of the last background command
sleep 3
usrp_x310s_capture_pid=$!

# start the toggle switch script
conda run -n starloc python3 -u MSW_USB_Linux_PyLib/toggle.py --time_on_port1 1 --time_on_port2 10 --toggle_time $runtime > toggle.log 2>&1 &
# Save the process ID of the last background command
toggle_pid=$!

# show pid of all background processes
echo "PID of reference signal generator: $refsig_pid"
echo "PID of IMU capture: $imucapture_pid"
echo "PID of USRP X310s capture: $usrp_x310s_capture_pid"
echo "PID of toggle switch: $toggle_pid"

# wait for 10 minutes and kill all the background processes
sleep $runtime
echo "Stopping all background processes"
kill $refsig_pid
kill $imucapture_pid
kill $usrp_x310s_capture_pid
kill $toggle_pid
echo "End time: $(date)"
# move the log files to the destination folder

mv ref_sig.log $destpath/log_files/ref_sig_$log_ts.log
mv imu_capture.log $destpath/log_files/imu_capture_$log_ts.log
mv usrp_x310s_capture.log $destpath/log_files/usrp_x310s_capture_$log_ts.log
mv toggle.log $destpath/log_files/toggle_$log_ts.log

