#!/bin/bash

# Run the usrp python script to record data in background
# TODO echo "Running Python script:"
# TODO python3 capture_data_usrp.py &

### Check if there is a new file in a directory and 

# Define the directory you want to monitor
directory="./new_files/"
latest_checked_file="none"
last_checked_file="none"
all_checked_time="Nan"

# Set the duration. When no new file is entered in the directory for this duration, the program ends. 
duration=120

# Get the start time in seconds
start_time=$(date +%s)

# Run the loop until the desired duration is reached
while true; do
    # Put your loop logic here
    # For example, you can echo some message to simulate work being done
    echo "Loop is running..."
    current_time=$(date +%s)
    # Get the latest modification time of any data file in the directory
    mod_files_arr=($(ls -rt "$directory"))
    echo "${mod_files_arr[@]}"
    # Check if there are any data files and if the latest modification time is greater than the previous one
    i=0
    for file in "${mod_files_arr[@]}" 
    do
        if [ "$latest_checked_file" = "$file" ]; then
            if [[ $i -lt ${#mod_files_arr[@]}-1 ]]; then
                echo "Need to check ${mod_files_arr[$i+1]}"
                # TODO - call matlab
                # set latest checked file to $file
                latest_checked_file="${mod_files_arr[$i+1]}"
            else
                if [[ "$last_checked_file" = "$latest_checked_file" ]]; then
                    echo "All data files so far are checked"
                else
                    last_checked_file=$latest_checked_file
                    all_checked_time=$(date +%s)
                fi
            fi
        else
            if [ "$latest_checked_file" = "none" ]; then
                # call matlab script to check $file
                # TODO - call matlab
                # set latest checked file to $file
                latest_checked_file=$file
            fi
        fi
        i=$((i+1))
        
    done
    
    # If non
    if [[ "$all_checked_time" != "Nan" ]]; then
        elapsed_time=$((current_time - all_checked_time))
        echo "checking elapsed time $current_time $all_checked_time $elapsed_time"
        # Check if the duration is reached, and exit the loop
        if [[ "$elapsed_time" -ge "$duration" ]]; then
            break
        fi
    fi
    # Introduce a delay before the next iteration (optional)
    sleep 1
done

# TODO you may want to terminate the uhd python script at this point
echo "Files checked : ${mod_files_arr[@]}"
echo "Experiemnt completed after $duration seconds."

