# starlink_ofdm

## Setup Python Environment
This creates a conda environment named ```starloc``` and installs ```requirements.txt```.
```bash
conda env create -f env.yaml 
conda activate starloc
```

## Directories

- `Central_Tone_Tracking/`
  
- `Satellite_Sim/`
  satellite elevation & doppler simulation based on TLE files
- `Tool_Functions/`
  useful auxiliary functions
  - `frame_detect_pss` uses the pss sequence to detect the begining of frames
- `USRP_testing/`
  scripts for capturing data and testing scripts for data captured by usrp
- `OFDM_LAB/`
  learning material
- `bash_scripts`
  shell scripts for running automated experiments (currently contains script to automate data capture on usrp for several hours)
