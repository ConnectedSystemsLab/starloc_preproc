#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: 1
# GNU Radio version: 3.10.1.1

from packaging.version import Version as StrictVersion

if __name__ == '__main__':
    import ctypes
    import sys
    if sys.platform.startswith('linux'):
        try:
            x11 = ctypes.cdll.LoadLibrary('libX11.so')
            x11.XInitThreads()
        except:
            print("Warning: failed to XInitThreads()")

from PyQt5 import Qt
from gnuradio import qtgui
from gnuradio.filter import firdes
import sip
from gnuradio import blocks
from gnuradio import gr
from gnuradio.fft import window
import sys
import signal
from argparse import ArgumentParser
from gnuradio.eng_arg import eng_float, intx
from gnuradio import eng_notation
from gnuradio import uhd
import time
import datetime
import os
from argparse import ArgumentParser


from gnuradio import qtgui

class usrp_auto(gr.top_block, Qt.QWidget):

    def __init__(self, args):
        gr.top_block.__init__(self, "1", catch_exceptions=True)
        Qt.QWidget.__init__(self)
        self.setWindowTitle("1")
        qtgui.util.check_set_qss()
        try:
            self.setWindowIcon(Qt.QIcon.fromTheme('gnuradio-grc'))
        except:
            pass
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

        self.settings = Qt.QSettings("GNU Radio", "usrp_auto")

        try:
            if StrictVersion(Qt.qVersion()) < StrictVersion("5.0.0"):
                self.restoreGeometry(self.settings.value("geometry").toByteArray())
            else:
                self.restoreGeometry(self.settings.value("geometry"))
        except:
            pass

        ##################################################
        # Variables
        ##################################################
        self.freq_4 = freq_4 = 11575000000
        # self.samp_rate = samp_rate = 100000000
        self.samp_rate = samp_rate = int(args.sample_rate)
        self.now = datetime.datetime.now()
        self.mon = mon = self.now.month
        self.minu = minu = self.now.minute
        self.hr = hr = self.now.hour
        self.freq = freq = freq_4
        self.day = day = self.now.day
        self.sec = sec = self.now.second
        self.root = root = "/home/jidazhang/Desktop/usrp_data/"
        self.path_time = path_time = "time_" + str(hr) + "_" + str(minu) + "_" + str(sec)
        self.path_freq = path_freq = "_freq_"+str(freq/1e9)[0:2]+"_"+str(freq/1e9)[3:] +  "G"
        self.path_date = path_date = str(mon) + "_" + str(day)+"/"
        self.path_bw = path_bw = "_bw_"+str(samp_rate/1e6)+"M"
        self.freq_9 = freq_9 = 11950000000
        self.freq_8 = freq_8 = 12575000000
        self.freq_7 = freq_7 = 12325000000
        self.freq_6 = freq_6 = 12075000000
        self.freq_5 = freq_5 = 11825000000
        self.freq_3 = freq_3 = 11325000000
        self.freq_2 = freq_2 = 11075000000
        self.freq_1 = freq_1 = 10825000000
        # self.center_freq = center_freq = freq - 9750000000
        self.center_freq = center_freq = int(args.center_freq) - 9750000000

        if not os.path.exists(self.root+self.path_date):
            os.mkdir(self.root+self.path_date)

        ##################################################
        # Blocks
        ##################################################
        self.uhd_usrp_source_0 = uhd.usrp_source(
            ",".join(("addr=192.168.40.2", '')),
            uhd.stream_args(
                cpu_format="fc32",
                args='',
                channels=list(range(0,1)),
            ),
        )
        self.uhd_usrp_source_0.set_subdev_spec('A:0', 0)
        self.uhd_usrp_source_0.set_samp_rate(samp_rate)
        # No synchronization enforced.

        self.uhd_usrp_source_0.set_center_freq(center_freq, 0)
        self.uhd_usrp_source_0.set_antenna("RX2", 0)
        self.uhd_usrp_source_0.set_normalized_gain(0, 0)
        self.qtgui_sink_x_0 = qtgui.sink_c(
            4096, #fftsize
            window.WIN_BLACKMAN_hARRIS, #wintype
            center_freq, #fc
            samp_rate, #bw
            "", #name
            False, #plotfreq
            True, #plotwaterfall
            False, #plottime
            False, #plotconst
            None # parent
        )
        self.qtgui_sink_x_0.set_update_time(1.0/10)
        self._qtgui_sink_x_0_win = sip.wrapinstance(self.qtgui_sink_x_0.qwidget(), Qt.QWidget)

        self.qtgui_sink_x_0.enable_rf_freq(False)

        self.top_layout.addWidget(self._qtgui_sink_x_0_win)
        self.blocks_file_sink_0 = blocks.file_sink(gr.sizeof_gr_complex*1, root+path_date+path_time+path_freq+path_bw+".dat", False)
        self.blocks_file_sink_0.set_unbuffered(False)


        ##################################################
        # Connections
        ##################################################
        self.connect((self.uhd_usrp_source_0, 0), (self.blocks_file_sink_0, 0))
        self.connect((self.uhd_usrp_source_0, 0), (self.qtgui_sink_x_0, 0))


    def closeEvent(self, event):
        self.settings = Qt.QSettings("GNU Radio", "usrp_auto")
        self.settings.setValue("geometry", self.saveGeometry())
        self.stop()
        self.wait()

        event.accept()

    def get_freq_4(self):
        return self.freq_4

    def set_freq_4(self, freq_4):
        self.freq_4 = freq_4
        self.set_freq(self.freq_4)

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.set_path_bw("_bw_"+str(self.samp_rate/1e6)+"M")
        self.qtgui_sink_x_0.set_frequency_range(self.center_freq, self.samp_rate)
        self.uhd_usrp_source_0.set_samp_rate(self.samp_rate)

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
        self.set_center_freq(self.freq - 9750000000)
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
        self.blocks_file_sink_0.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+".dat")

    def get_path_time(self):
        return self.path_time

    def set_path_time(self, path_time):
        self.path_time = path_time
        self.blocks_file_sink_0.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+".dat")

    def get_path_freq(self):
        return self.path_freq

    def set_path_freq(self, path_freq):
        self.path_freq = path_freq
        self.blocks_file_sink_0.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+".dat")

    def get_path_date(self):
        return self.path_date

    def set_path_date(self, path_date):
        self.path_date = path_date
        self.blocks_file_sink_0.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+".dat")

    def get_path_bw(self):
        return self.path_bw

    def set_path_bw(self, path_bw):
        self.path_bw = path_bw
        self.blocks_file_sink_0.open(self.root+self.path_date+self.path_time+self.path_freq+self.path_bw+".dat")

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

    def get_freq_3(self):
        return self.freq_3

    def set_freq_3(self, freq_3):
        self.freq_3 = freq_3

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
        self.qtgui_sink_x_0.set_frequency_range(self.center_freq, self.samp_rate)
        self.uhd_usrp_source_0.set_center_freq(self.center_freq, 0)




def main(top_block_cls=usrp_auto, options=None):

    # root = "/home/jidazhang/Desktop/usrp_data/9_19/"
    # old_file = os.listdir(root)
    # os.remove(os.path.join(root, old_file[0]))
    
    parser = ArgumentParser()
    parser.add_argument("sample_rate", help="sample rate")
    parser.add_argument("center_freq", help="the center frequency of the channel")
    parser.add_argument("duration", help="the time period for one capture (s)")
    args = parser.parse_args()
    # class A:
    #     def __init__(self):
    #         self.sample_rate = "100000000"
    #         self.center_freq = "11575000000"

    # args = A()
    
    if StrictVersion("4.5.0") <= StrictVersion(Qt.qVersion()) < StrictVersion("5.0.0"):
        style = gr.prefs().get_string('qtgui', 'style', 'raster')
        Qt.QApplication.setGraphicsSystem(style)
    qapp = Qt.QApplication(sys.argv)

    tb = top_block_cls(args)

    tb.start()

    tb.show()

    def sig_handler(sig=None, frame=None):
        tb.stop()
        tb.wait()

        Qt.QApplication.quit()

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    timer = Qt.QTimer()
    # timer.start(500)
    # timer.timeout.connect(lambda: None)
    timer.start(int(args.duration)*1000)
    timer.timeout.connect(sig_handler)

    qapp.exec_()

if __name__ == '__main__':
    main()
