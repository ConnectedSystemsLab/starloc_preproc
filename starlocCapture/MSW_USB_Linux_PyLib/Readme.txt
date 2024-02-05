USB_RF_Switch.py is Python library file to use with Mini-Circuits USB RF Switch , Digital Switch , ModularZT  & ZT Box (all Product ID 0x22)


Instruction for using USB_RF_Switch.py library :

install the following libraries: 
WINDOWS:

pip is located under [python folder]\scripts\pip 

1. pip install libusb
2. pip install pyusb
3. copy libusb-1.0.dll from  [python folder]\Lib\site-packages\libusb\_platform\_windows
   (amd64 or x86 version according to python version 32/64 to system folder System32 or SysWow64) or add the path of the dll.

If the user is using the 32 version of Python , then he should copy from the x86 directory the dll to his default sys folder ( system32 for 32 bit windows or SysWOW64 for the 64 bit windows)
If he is using Python64 he should copy the dll from amd64 folder to the default sys folder. 




LINUX:
(From TErminal under sudo)

python get-pip.py pip==9.0.2 wheel==0.30.0 setuptools==28.8.0  (for python2)
python3 get-pip.py pip==9.0.2 wheel==0.30.0 setuptools==28.8.0 (for Python3)

pip install --upgrade pip
pip3 install --upgrade pip (for Python3)

* if you dont have already pip installed 

pip install libusb
pip3 install libusb (for Python3)

pip install pyusb
pip3 install pyusb (for Python3)

Using the library: 

Put the library USB_RF_Switch.py under working folder or add the path to the library location
run the followinbg example python Test_Lib.py (or Python3 Test_Lib.py)

To import the library : 
import USB_RF_Switch 
SW1=USB_RF_Switch.RF_Switch()

Now you can send commands to the Switch:
serial=SW1.ReadSN()
model=SW1.Send_SCPI(":MN?")
etc... 

The functions are in the library file. 

