#!/bin/bash

# Run the usrp python script to record data in background
# TODO echo "Running Python script:"
# TODO 


### Check if there is a new file in a directory and 

# Define the directory you want to monitor
directory="/home/jidazhang/Desktop/usrp_data/9_20/"
output_directory="./bash_scripts/new_files_output/9_20/"
latest_checked_file="none"
last_checked_file="none"
all_checked_time="Nan"
# Matlab input params

sample_rate=100000000
center_freq=11575000000
if_visual=0
time_capture=120
# matlab_code=""
# Set the duration. When no new file is entered in the directory for this duration, the program ends. 
duration=120

# Get the start time in seconds
start_time=$(date +%s)

# Run the loop until the desired duration is reached
while true; 
do
    python3 ./bash_scripts/usrp_auto.py "$sample_rate" "$center_freq" "$time_capture"
    # Put your loop logic here
    # For example, you can echo some message to simulate work being done
    echo "Loop is running..."
    current_time=$(date +%s)
    # Get the latest modification time of any data file in the directory
    # Jida: ls -t ensures the latest file appear at the first
    mod_files_arr=($(ls -t "$directory"))
    echo "${mod_files_arr[@]}"
    # Check if there are any data files and if the latest modification time is greater than the previous one
    i=0
    # for file in "${mod_files_arr[@]}"
    # do
        # if [ "$latest_checked_file" = "$file" ]; then
        #     if [[ $i -lt ${#mod_files_arr[@]}-1 ]]; then
        file=${mod_files_arr[0]}
        echo "Need to check $file"
        file_path="$directory$file"
        echo "$file_path"
        matlab -nodisplay -nodesktop -r "cd Tool_Functions; frame_detect_pss('$file_path',$sample_rate,$if_visual);exit;"
        # output_file="$output_directory${mod_files_arr[$i+1]}"
        output_file="$output_directory$file"
        output_file_noframe="${output_file/.dat/_0.mat}"
        output_file_frame="${output_file/.dat/_1.mat}"
        if [ -e "$output_file_noframe" ]; then
            rm "$file_path"
            echo "deleted $file_path"
        fi
        i=$((i+1))
        
    # done
    
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