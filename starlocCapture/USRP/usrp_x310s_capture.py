#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: 1
# GNU Radio version: 3.10.8.0

from PyQt5 import Qt
from gnuradio import qtgui
from gnuradio import blocks
from gnuradio import gr
from gnuradio.filter import firdes
from gnuradio.fft import window
import sys
import signal
from PyQt5 import Qt
from argparse import ArgumentParser
from gnuradio.eng_arg import eng_float, intx
from gnuradio import eng_notation
from gnuradio import uhd
import time
import sip
from skyfield.api import load



class usrp(gr.top_block, Qt.QWidget):

    def __init__(self):
        gr.top_block.__init__(self, "1", catch_exceptions=True)
        Qt.QWidget.__init__(self)
        self.setWindowTitle("1")
        qtgui.util.check_set_qss()
        try:
            self.setWindowIcon(Qt.QIcon.fromTheme('gnuradio-grc'))
        except BaseException as exc:
            print(f"Qt GUI: Could not set Icon: {str(exc)}", file=sys.stderr)
        self.top_scroll_layout = Qt.QVBoxLayout()
        self.setLayout(self.top_scroll_layout)
        self.top_scroll = Qt.QScrollArea()
        self.top_scroll.setFrameStyle(Qt.QFrame.NoFrame)
        self.top_scroll_layout.addWidget(self.top_scroll)
        self.top_scroll.setWidgetResizable(True)
        self.top_widget = Qt.QWidget()
        self.top_scroll.setWidget(self.top_widget)
        self.top_layout = Qt.QVBoxLayout(self.top_widget)
        self.top_grid_layout = Qt.QGridLayout()
        self.top_layout.addLayout(self.top_grid_layout)

        self.settings = Qt.QSettings("GNU Radio", "usrp")

        try:
            geometry = self.settings.value("geometry")
            if geometry:
                self.restoreGeometry(geometry)
        except BaseException as exc:
            print(f"Qt GUI: Could not restore geometry: {str(exc)}", file=sys.stderr)

        ##################################################
        # Variables
        ##################################################
        # get global variables
        global month
        global day
        print("month: ", month)
        print("day: ", day)
        self.freq_3 = freq_3 = 11325000000
        self.samp_rate = samp_rate = 2e6
        self.mon = mon = month
        self.minu = minu = 15
        self.hr = hr = 15
        self.freq = freq = freq_3
        self.day = day 
        self.root = root = "/home/ishani/LeoPNT/USRP_data/"
        self.path_time = path_time = "time_" + str(hr) + "_" + str(minu)
        self.path_freq = path_freq = "_freq_"+str(freq/1e9)[0:2]+"_"+str(freq/1e9)[3:] +  "G"
        self.path_date = path_date = str(mon) + "_" + str(day)+"/"
        self.path_bw = path_bw = "_bw_"+str(samp_rate/1e6)+"M"
        self.freq_9 = freq_9 = 11950000000
        self.freq_8 = freq_8 = 12575000000
        self.freq_7 = freq_7 = 12325000000
        self.freq_6 = freq_6 = 12075000000
        self.freq_5 = freq_5 = 11825000000
        self.freq_4 = freq_4 = 11575000000
        self.freq_2 = freq_2 = 11075000000
        self.freq_1 = freq_1 = 10825000000
        self.center_freq = center_freq = freq-10e9

        # get and save tle file
        ts_readable = time.asctime(time.gmtime(time.time()))
        ts_str = ts_readable.split(" ")
        print("ts_str: ", ts_str)
        ts_str = ts_str[3]+ts_str[1]+ts_str[5]+"_"+ts_str[4]
        print("ts_str: ", ts_str)
        url = "https://celestrak.org/NORAD/elements/supplemental/sup-gp.php?FILE=starlink&FORMAT=tle"
        satellites = load.tle_file(url,filename=root+path_date+"utctime_"+ts_str+"_starlink.tle")

        ##################################################
        # Blocks
        ##################################################

        self.uhd_usrp_source_0_0_0 = uhd.usrp_source(
            ",".join(("addr0=192.168.40.2,addr1=192.168.10.3", '')),
            uhd.stream_args(
                cpu_format="fc32",
                args='',
                channels=list(range(0,3)),
            ),
        )
        self.uhd_usrp_source_0_0_0.set_clock_source('external', 0)
        self.uhd_usrp_source_0_0_0.set_time_source('external', 0)
        self.uhd_usrp_source_0_0_0.set_subdev_spec('B:0', 0)
        self.uhd_usrp_source_0_0_0.set_clock_source('external', 1)
        self.uhd_usrp_source_0_0_0.set_time_source('external', 1)
        self.uhd_usrp_source_0_0_0.set_subdev_spec('A:0 B:0', 1)
        self.uhd_usrp_source_0_0_0.set_samp_rate(samp_rate)
        _last_pps_time = self.uhd_usrp_source_0_0_0.get_time_last_pps().get_real_secs()
        # Poll get_time_last_pps() every 50 ms until a change is seen
        while(self.uhd_usrp_source_0_0_0.get_time_last_pps().get_real_secs() == _last_pps_time):
            time.sleep(0.05)
        # Set the time to PC time on next PPS
        self.uhd_usrp_source_0_0_0.set_time_next_pps(uhd.time_spec(int(time.time()) + 1.0))
        # Sleep 1 second to ensure next PPS has come
        time.sleep(1)

        self.uhd_usrp_source_0_0_0.set_center_freq(center_freq, 0)
        self.uhd_usrp_source_0_0_0.set_antenna("RX2", 0)
        self.uhd_usrp_source_0_0_0.set_normalized_gain(0.0, 0)

        self.uhd_usrp_source_0_0_0.set_center_freq(center_freq, 1)
        self.uhd_usrp_source_0_0_0.set_antenna("RX2", 1)
        self.uhd_usrp_source_0_0_0.set_normalized_gain(0.0, 1)

        self.uhd_usrp_source_0_0_0.set_center_freq(center_freq, 2)
        self.uhd_usrp_source_0_0_0.set_antenna("RX2", 2)
        self.uhd_usrp_source_0_0_0.set_normalized_gain(0.0, 2)
        self.qtgui_time_sink_x_0_1 = qtgui.time_sink_c(
            4096, #size
            samp_rate, #samp_rate
            "", #name
            3, #number of inputs
            None # parent
        )
        self.qtgui_time_sink_x_0_1.set_update_time(0.1)
        self.qtgui_time_sink_x_0_1.set_y_axis(-1, 1)

        self.qtgui_time_sink_x_0_1.set_y_label('Amplitude', "")

        self.qtgui_time_sink_x_0_1.enable_tags(False)
        self.qtgui_time_sink_x_0_1.set_trigger_mode(qtgui.TRIG_MODE_AUTO, qtgui.TRIG_SLOPE_POS, 0.0, 0, 0, "")
        self.qtgui_time_sink_x_0_1.enable_autoscale(True)
        self.qtgui_time_sink_x_0_1.enable_grid(True)
        self.qtgui_time_sink_x_0_1.enable_axis_labels(True)
        self.qtgui_time_sink_x_0_1.enable_control_panel(True)
        self.qtgui_time_sink_x_0_1.enable_stem_plot(False)


        labels = ['Signal 1', 'Signal 2', 'Signal 3', 'Signal 4', 'Signal 5',
            'Signal 6', 'Signal 7', 'Signal 8', 'Signal 9', 'Signal 10']
        widths = [1, 1, 1, 1, 1,
            1, 1, 1, 1, 1]
        colors = ['blue', 'red', 'green', 'black', 'cyan',
            'magenta', 'yellow', 'dark red', 'dark green', 'dark blue']
        alphas = [1.0, 1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0, 1.0]
        styles = [1, 1, 1, 1, 1,
            1, 1, 1, 1, 1]
        markers = [-1, -1, -1, -1, -1,
            -1, -1, -1, -1, -1]


        for i in range(6):
            if len(labels[i]) == 0:
                if (i % 2 == 0):
                    self.qtgui_time_sink_x_0_1.set_line_label(i, "Re{{Data {0}}}".format(i/2))
                else:
                    self.qtgui_time_sink_x_0_1.set_line_label(i, "Im{{Data {0}}}".format(i/2))
            else:
                self.qtgui_time_sink_x_0_1.set_line_label(i, labels[i])
            self.qtgui_time_sink_x_0_1.set_line_width(i, widths[i])
            self.qtgui_time_sink_x_0_1.set_line_color(i, colors[i])
            self.qtgui_time_sink_x_0_1.set_line_style(i, styles[i])
            self.qtgui_time_sink_x_0_1.set_line_marker(i, markers[i])
            self.qtgui_time_sink_x_0_1.set_line_alpha(i, alphas[i])

        self._qtgui_time_sink_x_0_1_win = sip.wrapinstance(self.qtgui_time_sink_x_0_1.qwidget(), Qt.QWidget)
        self.top_layout.addWidget(self._qtgui_time_sink_x_0_1_win)
        self.qtgui_freq_sink_x_0_0 = qtgui.freq_sink_c(
            32768, #size
            window.WIN_BLACKMAN_hARRIS, #wintype
            center_freq, #fc
            samp_rate, #bw
            "", #name
            3,
            None # parent
        )
        self.qtgui_freq_sink_x_0_0.set_update_time(0.10)
        self.qtgui_freq_sink_x_0_0.set_y_axis((-140), 10)
        self.qtgui_freq_sink_x_0_0.set_y_label('Relative Gain', 'dB')
        self.qtgui_freq_sink_x_0_0.set_trigger_mode(qtgui.TRIG_MODE_FREE, 0.0, 0, "")
        self.qtgui_freq_sink_x_0_0.enable_autoscale(False)
        self.qtgui_freq_sink_x_0_0.enable_grid(False)
        self.qtgui_freq_sink_x_0_0.set_fft_average(1.0)
        self.qtgui_freq_sink_x_0_0.enable_axis_labels(True)
        self.qtgui_freq_sink_x_0_0.enable_control_panel(False)
        self.qtgui_freq_sink_x_0_0.set_fft_window_normalized(False)



        labels = ['', '', '', '', '',
            '', '', '', '', '']
        widths = [1, 1, 1, 1, 1,
            1, 1, 1, 1, 1]
        colors = ["blue", "red", "green", "black", "cyan",
            "magenta", "yellow", "dark red", "dark green", "dark blue"]
        alphas = [1.0, 1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0, 1.0]

        for i in range(3):
            if len(labels[i]) == 0:
                self.qtgui_freq_sink_x_0_0.set_line_label(i, "Data {0}".format(i))
            else:
                self.qtgui_freq_sink_x_0_0.set_line_label(i, labels[i])
            self.qtgui_freq_sink_x_0_0.set_line_width(i, widths[i])
            self.qtgui_freq_sink_x_0_0.set_line_color(i, colors[i])
            self.qtgui_freq_sink_x_0_0.set_line_alpha(i, alphas[i])

        self._qtgui_freq_sink_x_0_0_win = sip.wrapinstance(self.qtgui_freq_sink_x_0_0.qwidget(), Qt.QWidget)
        self.top_layout.addWidget(self._qtgui_freq_sink_x_0_0_win)

        ts = time.time()
        ts_str = time.asctime(time.gmtime(ts)).split(" ")
        ts_str = "utctime_"+ts_str[3]+ts_str[1]+ts_str[5]+"_"+ts_str[4]
        ts_fine = ts
        self.blocks_file_sink_0_0_1 = blocks.file_sink(gr.sizeof_gr_complex*1, root+path_date+ts_str+path_freq+path_bw+"_ts_"+str(ts_fine)+"_inrx0.dat", False)
        self.blocks_file_sink_0_0_1.set_unbuffered(False)
        self.blocks_file_sink_0_0_0_1 = blocks.file_sink(gr.sizeof_gr_complex*1, root+path_date+ts_str+path_freq+path_bw+"_ts_"+str(ts_fine)+"_inrx1.dat", False)
        self.blocks_file_sink_0_0_0_1.set_unbuffered(False)
        self.blocks_file_sink_0_0_0_0_0 = blocks.file_sink(gr.sizeof_gr_complex*1, root+path_date+ts_str+path_freq+path_bw+"_ts_"+str(ts_fine)+"_inrx2.dat", False)
        self.blocks_file_sink_0_0_0_0_0.set_unbuffered(False)
        print("Done creating file sinks", root+path_date+path_time+path_freq+path_bw+"_"+str(ts), "at: " + time.asctime(time.gmtime(time.time())))

        ##################################################
        # Connections
        ##################################################
        self.connect((self.uhd_usrp_source_0_0_0, 2), (self.blocks_file_sink_0_0_0_0_0, 0))
        self.connect((self.uhd_usrp_source_0_0_0, 1), (self.blocks_file_sink_0_0_0_1, 0))
        self.connect((self.uhd_usrp_source_0_0_0, 0), (self.blocks_file_sink_0_0_1, 0))
        self.connect((self.uhd_usrp_source_0_0_0, 2), (self.qtgui_freq_sink_x_0_0, 2))
        self.connect((self.uhd_usrp_source_0_0_0, 0), (self.qtgui_freq_sink_x_0_0, 0))
        self.connect((self.uhd_usrp_source_0_0_0, 1), (self.qtgui_freq_sink_x_0_0, 1))
        self.connect((self.uhd_usrp_source_0_0_0, 1), (self.qtgui_time_sink_x_0_1, 1))
        self.connect((self.uhd_usrp_source_0_0_0, 2), (self.qtgui_time_sink_x_0_1, 2))
        self.connect((self.uhd_usrp_source_0_0_0, 0), (self.qtgui_time_sink_x_0_1, 0))


    def closeEvent(self, event):
        self.settings = Qt.QSettings("GNU Radio", "usrp")
        self.settings.setValue("geometry", self.saveGeometry())
        self.stop()
        self.wait()

        event.accept()

    def get_freq_3(self):
        return self.freq_3

    def set_freq_3(self, freq_3):
        self.freq_3 = freq_3
        self.set_freq(self.freq_3)

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.set_path_bw("_bw_"+str(self.samp_rate/1e6)+"M")
        self.qtgui_freq_sink_x_0_0.set_frequency_range(self.center_freq, self.samp_rate)
        self.qtgui_time_sink_x_0_1.set_samp_rate(self.samp_rate)
        self.uhd_usrp_source_0_0_0.set_samp_rate(self.samp_rate)

    def get_mon(self):
        return self.mon

    def set_mon(self, mon):
        self.mon = mon
        self.set_path_date(str(self.mon) + "_" + str(self.day)+"/")

    def get_minu(self):
        return self.minu

    def set_minu(self, minu):
        self.minu = minu
        self.set_path_time("time_" + str(self.hr) + "_" + str(self.minu))

    def get_hr(self):
        return self.hr

    def set_hr(self, hr):
        self.hr = hr
        self.set_path_time("time_" + str(self.hr) + "_" + str(self.minu))

    def get_freq(self):
        return self.freq

    def set_freq(self, freq):
        self.freq = freq
        self.set_center_freq(self.freq-10e9)
        self.set_path_freq("_freq_"+str(self.freq/1e9)[0:2]+"_"+str(self.freq/1e9)[3:] +  "G")

    def get_day(self):
        return self.day

    def set_day(self, day):
        self.day = day
        self.set_path_date(str(self.mon) + "_" + str(self.day)+"/")

    def get_root(self):
        return self.root

    def set_root(self, root):
        self.root = root
        self.blocks_file_sink_0_0_0_0_0.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+"_inrx2.dat")
        self.blocks_file_sink_0_0_0_1.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+"_inrx1.dat")
        self.blocks_file_sink_0_0_1.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+"_inrx0.dat")

    def get_path_time(self):
        return self.path_time

    def set_path_time(self, path_time):
        self.path_time = path_time
        self.blocks_file_sink_0_0_0_0_0.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+"_inrx2.dat")
        self.blocks_file_sink_0_0_0_1.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+"_inrx1.dat")
        self.blocks_file_sink_0_0_1.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+"_inrx0.dat")

    def get_path_freq(self):
        return self.path_freq

    def set_path_freq(self, path_freq):
        self.path_freq = path_freq
        self.blocks_file_sink_0_0_0_0_0.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+"_inrx2.dat")
        self.blocks_file_sink_0_0_0_1.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+"_inrx1.dat")
        self.blocks_file_sink_0_0_1.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+"_inrx0.dat")

    def get_path_date(self):
        return self.path_date

    def set_path_date(self, path_date):
        self.path_date = path_date
        self.blocks_file_sink_0_0_0_0_0.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+"_inrx2.dat")
        self.blocks_file_sink_0_0_0_1.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+"_inrx1.dat")
        self.blocks_file_sink_0_0_1.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+"_inrx0.dat")

    def get_path_bw(self):
        return self.path_bw

    def set_path_bw(self, path_bw):
        self.path_bw = path_bw
        self.blocks_file_sink_0_0_0_0_0.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+"_inrx2.dat")
        self.blocks_file_sink_0_0_0_1.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+"_inrx1.dat")
        self.blocks_file_sink_0_0_1.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+"_inrx0.dat")

    def get_freq_9(self):
        return self.freq_9

    def set_freq_9(self, freq_9):
        self.freq_9 = freq_9

    def get_freq_8(self):
        return self.freq_8

    def set_freq_8(self, freq_8):
        self.freq_8 = freq_8

    def get_freq_7(self):
        return self.freq_7

    def set_freq_7(self, freq_7):
        self.freq_7 = freq_7

    def get_freq_6(self):
        return self.freq_6

    def set_freq_6(self, freq_6):
        self.freq_6 = freq_6

    def get_freq_5(self):
        return self.freq_5

    def set_freq_5(self, freq_5):
        self.freq_5 = freq_5

    def get_freq_4(self):
        return self.freq_4

    def set_freq_4(self, freq_4):
        self.freq_4 = freq_4

    def get_freq_2(self):
        return self.freq_2

    def set_freq_2(self, freq_2):
        self.freq_2 = freq_2

    def get_freq_1(self):
        return self.freq_1

    def set_freq_1(self, freq_1):
        self.freq_1 = freq_1

    def get_center_freq(self):
        return self.center_freq

    def set_center_freq(self, center_freq):
        self.center_freq = center_freq
        self.qtgui_freq_sink_x_0_0.set_frequency_range(self.center_freq, self.samp_rate)
        self.uhd_usrp_source_0_0_0.set_center_freq(self.center_freq, 0)
        self.uhd_usrp_source_0_0_0.set_center_freq(self.center_freq, 1)
        self.uhd_usrp_source_0_0_0.set_center_freq(self.center_freq, 2)


def main(top_block_cls=usrp, options=None):

    qapp = Qt.QApplication(sys.argv)

    import argparse
    import os

    parser = argparse.ArgumentParser(description='get month and day to create destination folder')
    parser.add_argument('--month', type=int, help='month', required=True)
    parser.add_argument('--day', type=int, help='day', required=True)
    args = parser.parse_args()
    global month
    month = args.month
    global day
    day = args.day

    if not os.path.exists("/home/ishani/LeoPNT/USRP_data/"+str(month)+"_"+str(day)):
        os.makedirs("/home/ishani/LeoPNT/USRP_data/"+str(month)+"_"+str(day))

    tb = top_block_cls()
    
    print('Creating GUI render at: ' + str(time.time()))
    tb.start()
    tb.show()

    def sig_handler(sig=None, frame=None):
        tb.stop()
        tb.wait()

        Qt.QApplication.quit()

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    timer = Qt.QTimer()
    timer.start(500)
    timer.timeout.connect(lambda: None)
    
    print("Start Timestamp: " + str(time.time()))  
    qapp.exec_()
    print("End Timestamp:" + str(time.time()))

if __name__ == '__main__':
    main()
