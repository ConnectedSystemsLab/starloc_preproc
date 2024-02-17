# How does the pipeline work and data formats

This file shows how to use the pipeline under the `Starloc/` folder, as well as the data formats of some intermediate results. Basically heavy tasks are in python, some are in matlab for visualization.

- Step 1: Getting basic information
  run `Starloc.ipynb` step 1 and save basic information to folder `$date/`, where `$date` is the time stamp of each capture, e.g. `5Feb2024_23-58-08`

  - info.mat
    - `IQ_Sample_file_0`: path for rx0
    - `sample_rate`
    - `date`
    - `start_time`: in timestamp
    - `ref_sig_idx`: shape is ref sig # x 3, with i-th row first/second column starting/ending sample # of the i-th ref sig, third column is the duration in secs
    - `t_end`: duration of the entire capture in secs
    - `phase_offset_01`: shape is 1 x ref sig #, phase diff of ref sig between rx0 & rx1
    - `phase_offset_21`: ...
- Step 2: Center tone tracking
  first change variable `date_` in `phase_from_bin_track.m` and run it to track the center tone for 3 lnbs
  - res.mat
    - `res`: tracked points # x 5, col-1 is time in secs, col-2 is the freq bin, col-3/4/5 is rx0/1/2's fft @ that freq bin
- Step 3: Have a look at step 2's result
  run `Starloc.ipynb` step 3
- Step 4: Doppler simulation
  run `Starloc.ipynb` step 4
  - output_doppler.mat
    - `sat_dopp_dict`: fields are the sat id, values are 3 x time instance #, with first row = doppler in Hz, second/third row = azimuth/elevation in degs
- Step 5: get phase diff
  run `phase_from_bin.m` following the instruction in it. In part 3, save 
  - phase_comp.mat
    - `dopp_track_dict`: a (1, sat #) cell, in each cell the format is similar as res.mat
    - `"sat_dopp_dict"`: the same as step 4
    - `id_dict`: a (1, sat #) cell, each is the i-th sat's id
- Step 6: get numba