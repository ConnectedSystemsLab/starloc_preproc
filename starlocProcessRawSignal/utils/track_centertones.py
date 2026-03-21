import numpy as np
import scipy.io as sio
import scipy.fft as fft
import os
from utils.read_raw_data import read_dat_file

def track_centertones_from_raw_data(iq_filepaths: list[str], sample_rate: int, num_read_samples: int, calibration_matfile: str, output_dir: str):
    """
    Track the center tones from the raw IQ data.
    
    Args:
        iq_filepaths: List of paths to the IQ data files. Expects three files, one for each rx
    """
    
    calib_mat = sio.loadmat(calibration_matfile)
    t_end = float(calib_mat["capture_duration"].item())
    ref_sig_idx = calib_mat["ref_sig_idx"]  # shape (N, 3)

    f_0 = iq_filepaths[0]
    f_1 = iq_filepaths[1]
    f_2 = iq_filepaths[2]

    freqs = np.linspace(-sample_rate / 2, sample_rate / 2, num_read_samples)

    res = []
    snr_list = []
    start_idx = 0
    thresh = 3.5
    if_visual = False
    buffer = int(0.1 * 2e6)

    while start_idx < t_end * sample_rate:
        sig_0 = read_dat_file(f_0, count=num_read_samples, start_index=start_idx)
        sig_1 = read_dat_file(f_1, count=num_read_samples, start_index=start_idx)
        sig_2 = read_dat_file(f_2, count=num_read_samples, start_index=start_idx)

        # skip if current position is within a reference signal window
        later_than_begin = start_idx >= ref_sig_idx[:, 0] - buffer
        earlier_than_end = start_idx <= ref_sig_idx[:, 1] + buffer
        if np.any(later_than_begin & earlier_than_end):
            start_idx += num_read_samples // 2
            continue

        sig_0_fft = fft.fftshift(fft.fft(sig_0))
        sig_1_fft = fft.fftshift(fft.fft(sig_1))
        sig_2_fft = fft.fftshift(fft.fft(sig_2))

        sig_0_fft_abs = np.abs(sig_0_fft)
        sig_1_fft_abs = np.abs(sig_1_fft)
        sig_2_fft_abs = np.abs(sig_2_fft)

        pw_avg_0 = np.mean(sig_0_fft_abs)
        pw_avg_1 = np.mean(sig_1_fft_abs)
        pw_avg_2 = np.mean(sig_2_fft_abs)

        idx_0 = np.where(sig_0_fft_abs > thresh * pw_avg_0)[0]
        idx_1 = np.where(sig_1_fft_abs > thresh * pw_avg_1)[0]
        idx_2 = np.where(sig_2_fft_abs > thresh * pw_avg_2)[0]

        idx_com = np.intersect1d(np.intersect1d(idx_0, idx_1), idx_2)
        t = (start_idx + num_read_samples / 2) / sample_rate

        if len(idx_com) > 1:
            sig_0_peaks = np.mean(sig_0_fft_abs[idx_com] ** 2)
            sig_1_peaks = np.mean(sig_1_fft_abs[idx_com] ** 2)
            sig_2_peaks = np.mean(sig_2_fft_abs[idx_com] ** 2)

            logical_idx = np.ones(len(sig_0_fft_abs), dtype=bool)
            logical_idx[idx_com] = False

            sig_0_noise = np.mean(sig_0_fft_abs[logical_idx] ** 2)
            sig_1_noise = np.mean(sig_1_fft_abs[logical_idx] ** 2)
            sig_2_noise = np.mean(sig_2_fft_abs[logical_idx] ** 2)

            snr_0 = 10 * np.log10(sig_0_peaks / sig_0_noise)
            snr_1 = 10 * np.log10(sig_1_peaks / sig_1_noise)
            snr_2 = 10 * np.log10(sig_2_peaks / sig_2_noise)
            avg_snr = (snr_0 + snr_1 + snr_2) / 3
            # print(f"avg snr: {avg_snr:.6f}")
            snr_list.append([t, avg_snr])

        for idx in idx_com:
            res.append([t, idx, sig_0_fft[idx], sig_1_fft[idx], sig_2_fft[idx]])

        start_idx += num_read_samples // 2

    res = np.array(res) if res else np.empty((0, 5))
    snr_arr = np.array(snr_list) if snr_list else np.empty((0, 2))

    sio.savemat(os.path.join(output_dir, "centertones.mat"), {"res": res})
    sio.savemat(os.path.join(output_dir, "snr.mat"), {"snr": snr_arr})
    print(f"Centertone detection and tracking: done, result saved in {os.path.join(output_dir, 'centertones.mat')} and {os.path.join(output_dir, 'snr.mat')}, total {res.shape[0]} points")


def get_persat_centertones_and_ids(centertones_matfile: str, output_doppler_matfile: str,
                   results_dir: str, period_starts: list, period_ends: list,
                   sample_rate: float, fc: float, d: float, nfft: int):
    """
    Performs the following steps:

    Part 1: Split detected centertone points by satellite observation window,
            track and connect centertone harmonics (i.e., doppler shifted centertones across time), fit Doppler curves, compute
            phase-difference slopes.  Saves doppler_track.mat as intermediate result for later use.

    Part 2: Match each observed Doppler track to a simulated satellite.
            Saves id result plot.

    Args:
        centertones_matfile:    path to centertones.mat  (output of track_centertones)
        output_doppler_matfile: path to output_doppler.mat (output of get_all_sat_dopplers: contains tle-based satellite doppler profiles of all visible satellites)
        results_dir:            intermediate results folder where output files are written
        period_starts:          list of ints — start times (s) for each satellite window
        period_ends:            list of ints — end   times (s) for each satellite window
        sample_rate:            receiver sample rate (Hz)
        fc:                     carrier frequency (Hz)
        d:                      antenna spacing (m)
        nfft:                   FFT size used during centertone detection
    """

    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt

    period_starts = np.asarray(period_starts)
    period_ends   = np.asarray(period_ends)
    num_periods   = len(period_starts)

    # frequency axis (0-based bin indices from centertones.mat map directly into this)
    f = np.linspace(-sample_rate / 2, sample_rate / 2, nfft)
    bin_freq    = sample_rate / nfft
    bin_spacing = 43.9e3 / bin_freq

    # ── load centertones ────────────────────────────────────────────────────
    res = sio.loadmat(centertones_matfile)['res']   # (N, 5): [t, bin_idx, iq0, iq1, iq2]

    # # ── uncomment to plot raw detections ─────────────────────────────────────
    # fig, ax = plt.subplots()
    # ax.plot(res[:, 0].real, res[:, 1].real, '.', markersize=2)
    # ax.set_xlabel('t (s)'); ax.set_ylabel('bin index')
    # fig.savefig(os.path.join(results_dir, 'doppler_track.png'), dpi=100)
    # plt.close(fig)

    # ═══════════════════════════════════════════════════════════════════════
    # PART 1 — Doppler tracking and satellite splitting
    # ═══════════════════════════════════════════════════════════════════════

    # split res rows into per-satellite windows (windows may overlap)
    res_per_sat = [np.empty((0, res.shape[1]), dtype=res.dtype) for _ in range(num_periods)]
    for row in res:
        t_ii = row[0].real
        for jj in range(num_periods):
            if period_starts[jj] <= t_ii <= period_ends[jj]:
                res_per_sat[jj] = np.vstack([res_per_sat[jj], row])

    dopp_track_dict      = [None] * num_periods
    dopp_track_main_dict = [None] * num_periods
    dis_thresh_default   = 25

    for sat_id in range(num_periods):
        res_1sat   = res_per_sat[sat_id]
        num_points = res_1sat.shape[0]

        if num_points == 0:
            dopp_track_dict[sat_id]      = np.empty((0, res.shape[1]), dtype=res.dtype)
            dopp_track_main_dict[sat_id] = np.empty((0, res.shape[1]), dtype=res.dtype)
            continue

        dis_thresh = dis_thresh_default

        # ── greedy nearest-neighbour tracking ──────────────────────────────
        tracks = []
        stft_step = nfft / sample_rate      # seconds per STFT frame
        time_gap  = stft_step * 15          # match threshold in time

        for ii in range(num_points):
            pnt_curr   = res_1sat[ii]
            t_curr     = pnt_curr[0].real
            f_bin_cur  = pnt_curr[1].real
            assigned   = False
            for jj in range(len(tracks)):
                last      = tracks[jj][-1]
                t_last    = last[0].real
                f_bin_last= last[1].real
                if abs(t_curr - t_last) < time_gap and abs(f_bin_cur - f_bin_last) < 30:
                    tracks[jj] = np.vstack([tracks[jj], pnt_curr])
                    assigned = True
                    break
            if not assigned:
                tracks.append(pnt_curr.reshape(1, -1))

        # ── pick longest track as the main track ───────────────────────────
        durations = [trk[-1, 0].real - trk[0, 0].real for trk in tracks]
        max_idx   = int(np.argmax(durations))
        track_main = tracks[max_idx].copy()

        # ── degree-1 fit on main track; absorb points all other frequency centertones into this main track ─────
        a1 = np.polyfit(track_main[:, 0].real, track_main[:, 1].real, 1)
        for ii in range(num_points):
            pnt_curr  = res_1sat[ii]
            t_curr    = pnt_curr[0].real
            f_bin_cur = pnt_curr[1].real
            f_bin_tar = np.polyval(a1, t_curr)
            for jj in range(-8, 9):
                if abs(f_bin_tar + jj * bin_spacing - f_bin_cur) < dis_thresh:
                    bias      = np.zeros(res.shape[1], dtype=res.dtype)
                    bias[1]   = round(jj * bin_spacing)
                    track_main = np.vstack([track_main, pnt_curr - bias])
                    break

        # ── degree-2 fit; final point filter ───────────────────────────────
        a2      = np.polyfit(track_main[:, 0].real, track_main[:, 1].real, 2)
        offsets = np.arange(-8, 9) * bin_spacing
        dopp_track = np.empty((0, res.shape[1]), dtype=res.dtype)
        for ii in range(num_points):
            pnt_curr  = res_1sat[ii]
            t_curr    = pnt_curr[0].real
            f_bin_cur = pnt_curr[1].real
            dis = f_bin_cur - (np.polyval(a2, t_curr) + offsets)
            if np.min(np.abs(dis)) < dis_thresh:
                dopp_track = np.vstack([dopp_track, pnt_curr])

        dopp_track_dict[sat_id]      = dopp_track
        dopp_track_main_dict[sat_id] = track_main

        # ── remove points assigned here from the next overlapping window ────
        if sat_id < num_periods - 1 and period_starts[sat_id + 1] <= period_ends[sat_id]:
            for ii in range(dopp_track.shape[0]):
                keep = ~np.all(res_per_sat[sat_id + 1] == dopp_track[ii], axis=1)
                res_per_sat[sat_id + 1] = res_per_sat[sat_id + 1][keep]

    # ── convert bin indices → Hz in dopp_track_main_dict ───────────────────
    for sat_id in range(num_periods):
        dm = dopp_track_main_dict[sat_id]
        if dm is None or dm.shape[0] == 0:
            continue
        bin_idx = np.clip(dm[:, 1].real.astype(int), 0, len(f) - 1)
        dopp_track_main_dict[sat_id][:, 1] = f[bin_idx]


    # ═══════════════════════════════════════════════════════════════════════
    # PART 2 — Get the satellite IDs, for GT purpose
    # ═══════════════════════════════════════════════════════════════════════

    doppler_data = sio.loadmat(output_doppler_matfile)
    sat_dopp_dict = doppler_data['sat_dopp_dict']   # (1,1) structured array
    t_list        = doppler_data['t_list'].flatten()
    sat_sim_fns   = list(sat_dopp_dict.dtype.names)

    def get_sat_dopp(name):
        # sat_dopp_dict[name] → (3, N): [doppler, az, el]. Only first row is used for doppler.
        return sat_dopp_dict[name][0, 0]  

    # consolidate dopp_track_main_dict to unique timestamps
    for sat_id in range(num_periods):
        dm = dopp_track_main_dict[sat_id]
        if dm is None or dm.shape[0] == 0:
            continue
        t_uniq = np.unique(dm[:, 0].real)
        dm_ = np.zeros((len(t_uniq), 3))
        for idx, t_now in enumerate(t_uniq):
            mask = dm[:, 0].real == t_now
            dm_[idx, 0] = t_now
            dm_[idx, 1] = np.mean(dm[mask, 1].real)
            dm_[idx, 2] = np.mean(dm[mask, 2].real) if dm.shape[1] > 2 else 0.0
        dopp_track_main_dict[sat_id] = dm_

    id_dict    = [None] * num_periods
    freq_offset = np.zeros(num_periods)

    for sat_id in range(num_periods):
        dm = dopp_track_main_dict[sat_id]
        if dm is None or dm.shape[0] == 0:
            continue
        t_1 = dm[0, 0];  t_2 = dm[-1, 0]
        sim_idx_1 = int(np.argmin(np.abs(t_list - t_1)))
        sim_idx_2 = int(np.argmin(np.abs(t_list - t_2)))

        min_var = np.inf
        for name in sat_sim_fns:
            sim_dopp = get_sat_dopp(name)[0, :]
            seg = sim_dopp[sim_idx_1:sim_idx_2 + 1]
            if np.any(np.isnan(seg)):
                continue
            a        = np.polyfit(t_list[sim_idx_1:sim_idx_2 + 1], seg, 2)
            dopp_tar = np.polyval(a, dm[:, 0])
            dopp_var = np.var(dm[:, 1] - dopp_tar)
            if dopp_var < min_var:
                min_var          = dopp_var
                id_dict[sat_id]  = name
                freq_offset[sat_id] = np.mean(-(dm[:, 1] - dopp_tar))

    # ── plot ID result ───────────────────────────────────────────────────────
    
    fig, ax = plt.subplots(figsize=(12, 5))
    for name in sat_sim_fns:
        ax.plot(t_list, get_sat_dopp(name)[0, :], '--', alpha=0.3, linewidth=0.8)
    for sat_id in range(num_periods):
        dm = dopp_track_main_dict[sat_id]
        if dm is not None and dm.shape[0] > 0:
            label = id_dict[sat_id] if id_dict[sat_id] else f'sat #{sat_id}'
            ax.plot(dm[:, 0], dm[:, 1] + freq_offset[sat_id], 'o', markersize=4, label=label)
    ax.legend(fontsize=7); ax.set_xlabel('t (s)'); ax.set_ylabel('Doppler (Hz)')
    fig.savefig(os.path.join(results_dir, 'id_result.png'), dpi=100)
    plt.close(fig)
    print("Satellite IDs:", {i: id_dict[i] for i in range(num_periods)})



    # ── save the per satellite centertones, main_dopp_track and identified satellite IDs ──────────────────────────────────────────────────
    dopp_track_cell = np.empty(num_periods, dtype=object)
    dopp_track_main_cell = np.empty(num_periods, dtype=object)
    for i in range(num_periods):
        dopp_track_cell[i] = dopp_track_dict[i] if dopp_track_dict[i] is not None else np.array([])
        dopp_track_main_cell[i] = dopp_track_main_dict[i] if dopp_track_main_dict[i] is not None else np.array([])
    sio.savemat(os.path.join(results_dir, 'persat_centertones_and_ids.mat'), {
        'dopp_track_dict': dopp_track_cell,
        'dopp_track_main_dict': dopp_track_main_cell,
        'id_dict':         np.array(id_dict, dtype=object),
        'freq_offset':     freq_offset,
    })
    print(f"Saved persat_centertones_and_ids.mat in ({results_dir})")
