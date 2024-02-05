Entire signal capturing pipeline exists in this folder. 
Includes scripts to:
    1. get IMU data
    2. start transmission of refernce signal
    3. start reception from x310 USRPs
    4. toggling the switch intermittently to allow reference signal 

Only change parameters in bash_scripts/run_expt.sh before starting the signal capture

Running the experiment:
1. Make sure you have permissions to access the switch
    sudo chmod 666 /dev/bus/usb/<BUS>/<DEVICE>
    <BUS> and <DEVICE> for the switch can be obtained using lsusb
2. Run capture from this directory
    sh bash_scripts/run_expt.sh