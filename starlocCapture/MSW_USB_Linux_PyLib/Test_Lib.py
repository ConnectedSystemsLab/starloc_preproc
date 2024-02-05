import time
import USB_RF_Switch 
U1=USB_RF_Switch.RF_Switch()

s1=U1.ReadSN()
print (s1)

s1=U1.Send_SCPI(":MN?")
print (s1)
s1=U1.Send_SCPI(":SN?")
print (s1)

# SPDT switches
s1=U1.Send_SCPI("SETA=1")
print (s1)
s1=U1.Send_SCPI("SWPORT?")
print (s1)

# SP4T switches
#s1=U1.Send_SCPI("SP4TA:STATE:4")
#print (s1)
#s1=U1.Send_SCPI("SP4TA:STATE?")
#print (s1)

# SP6T switches
#s1=U1.Send_SCPI("SP6TA:STATE:6")
#print (s1)
#s1=U1.Send_SCPI("SP6TA:STATE?")
#print (s1)
