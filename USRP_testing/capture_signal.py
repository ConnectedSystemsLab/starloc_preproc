import uhd
import numpy as np
from datetime import datetime, timedelta
import os

def capture_signal(center_frequency, bandwidth, duration, output_file):
    
    usrp = uhd.usrp.MultiUSRP()
    usrp.set_rx_subdev_spec("A:0")

    num_samps = duration*bandwidth # number of samples to be received
    center_freq = center_frequency # Hz
    sample_rate = bandwidth # Hz - bandwidth cannot be greater than the sample rate
    # gain = 50 # dB

    usrp.set_rx_rate(sample_rate, 0)
    usrp.set_rx_freq(uhd.libpyuhd.types.tune_request(center_freq), 0)
    # usrp.set_rx_gain(gain, 0)
    usrp.set_rx_agc(True, 0)

    # Set up the stream and receive buffer
    stream_args = uhd.usrp.StreamArgs("fc32", "sc16")
    stream_args.channels = [0]
    metadata = uhd.types.RXMetadata()
    streamer = usrp.get_rx_stream(stream_args)
    recv_buffer = np.zeros((1, 1000), dtype=np.complex64)

    # Start Stream
    stream_cmd = uhd.types.StreamCMD(uhd.types.StreamMode.start_cont)
    stream_cmd.stream_now = True
    streamer.issue_stream_cmd(stream_cmd)

    # Receive Samples
    samples = np.zeros(num_samps, dtype=np.complex64)
    for i in range(num_samps//1000):
        streamer.recv(recv_buffer, metadata)
        samples[i*1000:(i+1)*1000] = recv_buffer[0]

    # Stop Stream
    stream_cmd = uhd.types.StreamCMD(uhd.types.StreamMode.stop_cont)
    streamer.issue_stream_cmd(stream_cmd)

    print(len(samples))
    print(samples[0:10])

if __name__ == "__main__":
    
    center_freq_list = [11.325e9, 11.575e9, 11.825e9, 11.950e9] 
    bandwidth = 100e6
    rec_duration = 30 # duration for each capture from usrp in seconds
    start_time = datetime.now()
    stop_time = start_time + timedelta(hours=12)
    dest_folder = "~/Desktop/usrp_data/" # enter super directory in which all usrp data is stored
    dest_sub_folder = "usrp_signal_capture_"+start_time.year+"_"+start_time.month+"_"+start_time.day
    
    while True:
        if stop_time >= datetime.now():
            break
        else:
            for center_freq in center_freq_list:
                current_time = datetime.now()
                output_filename = "IQsamples_"+current_time.year+"_"+current_time.month+"_"+current_time.day+"_"+current_time.hour+"_"+current_time.minute+"_"+current_time.second+"_"+".dat"
                output_file_path = os.path.join(dest_folder, dest_sub_folder, output_filename)
                capture_signal(center_frequency=center_freq, bandwidth=bandwidth, duration=rec_duration, output_file=output_file_path)
