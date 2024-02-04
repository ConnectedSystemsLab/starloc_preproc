#!/bin/sh
# This script is written to use with power splitters where you would want to start and stop the reference signal generator script every 10 seconds

python_script="ref_sig.py" # path to the reference signal generator script
for i in {1..70}
do
    # print the current time
    echo "Current time: $(date)"
    nohup python3 -u "$python_script" &

    # Save the process ID of the last background command
    python_pid=$!
    echo "Python script is running with PID: $python_pid"
    # Wait 
    sleep 4
    # Stop the Python script by sending a termination signal
    echo "Stopping Python script with PID: $python_pid"
    kill "$python_pid"
    echo "Stop time: $(date)"
    sleep 8
done
