# starlocProcessRawSignal

Pipeline for processing raw Starlink IQ captures into the intermediate files needed by the StarLoc localization algorithm.

## Overview

The pipeline takes raw IQ recordings from three receivers (.dat files in the observation folders in the dataset) and produces two `.mat` files — `calibration.mat` and `tracked_tones.mat` — that are consumed by the StarLoc localization notebook.

## Repository Layout

```
starlocProcessRawSignal/
├── main.py                  # Pipeline entry point
├── config.json              # Hardware parameters
├── obs_periods.json         # Per-observation satellite window definitions
├── env.yaml                 # Conda environment
└── utils/
    ├── calibration.py       # CalibrationSignal class — finds and phases cal signal
    ├── sat_simulation.py    # SGP4 propagation using TLE + skyfield
    ├── track_centertones.py # STFT centertone detection, tracking, and satellite ID
    ├── imu_data.py          # IMU file parser for ground station coordinates
    └── read_raw_data.py     # Raw .dat IQ file reader
```

## Usage

Create conda environment:

```bash
conda env create -f env.yaml
```

Activate conda environment: 

```bash
conda activate starloc
```

Run the pipeline: 

```bash
python main.py \
    --obs_folder    /path/to/obs_folder \
    --results_folder /path/to/results_folder \
    --config_file   /path/to/config.json
```

### Arguments

| Argument | Description |
|----------|-------------|
| `--obs_folder` | Observation folder from the dataset. This is expected to contain raw `.dat` IQ files, IMU `.txt`, and `.tle` file |
| `--results_folder` | Output folder (created if it does not exist) |
| `--config_file` | Path to `config.json` containing hardware parameters and satellite observation periods (start and end times of satellite visibility). |


## Pipeline Steps

#### Step 1 — Calibration phase extraction (`save_calibration_phases_and_capture_duration`)
Finds all calibration signal transmissions in the IQ files, extracts the phase of each receiver at each transmission, and computes inter-receiver phase offsets. Saves `<results_folder>/intermediate_results/calibration_intermediate.mat`.

#### Step 2 — Satellite Doppler simulation (`get_all_sat_dopplers`)
Uses the TLE file and ground station coordinates (from IMU) to simulate Doppler profiles for all visible Starlink satellites over the observation window. Saves `<results_folder>/intermediate_results/output_doppler.mat`.

#### Step 3 — Centertone tracking and satellite ID (`detect_and_track_centertones`)
Runs an STFT over the raw IQ data to detect narrowband centertones, tracks them across time, connects harmonic copies, identifies which satellite each track belongs to by matching against the simulated Doppler profiles. Saves `<results_folder>/intermediate_results/centertones.mat` and `<results_folder>/intermediate_results/persat_centertones_and_ids.mat`.

#### Step 4 — Collect outputs (`collect_main_files`)
Packages `calibration.mat` and `tracked_tones.mat` from the intermediate results into the results folder root for use by StarLoc localization.


## Notes
#### 1. Observation folder naming convention

IQ filenames are expected to follow:
```
utctime_{date}_{time}_freq_{f}_bw_{bw}_ts_{timestamp}_inrx{0,1,2}.dat
```
The UTC epoch timestamp embedded in the filename is used as `start_time`.

#### 2. `config.json` description

| Field | Description |
|-------|-------------|
| `center_freq` | Receiver center frequency (Hz) |
| `calibsig_freq` | Calibration signal transmit frequency (Hz) |
| `sample_rate` | SDR sample rate (Hz) |
| `antenna_spacing_meters` | Spacing between antennas (m) |
| `stft_win` | STFT window length (s); determines FFT size as `sample_rate × stft_win` |
| `obs_periods_filepath` | Path to `obs_periods.json` |

