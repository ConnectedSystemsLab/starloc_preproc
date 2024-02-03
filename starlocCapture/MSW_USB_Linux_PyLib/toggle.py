import USB_RF_Switch
import time
from time import sleep

class Toggle():
    def __init__(self):
        self.switch = USB_RF_Switch.RF_Switch()
        # create switch array with [switch number, state]
        self.switch_arr = [[1, 0], [2, 0], [3, 0], [4, 0]]
        # set state of all switches to 0 (COM->port1)
        for i in self.switch_arr:
            self.switch.Switch(i[0], i[1])
        print("Switches initialized")
        sleep(1)

    def change_switch_state(self, switch_number, current_state, switch_state):
        if current_state == switch_state:
            return switch_number, current_state
        
        # change switch state
        self.switch.Switch(switch_number, switch_state)
        # update current_state
        current_state = switch_state
        self.switch_arr[switch_number-1][1] = current_state

        return switch_number, current_state

    def toggle_all_switches(self):
        # toggle all switches
        for i in self.switch_arr:
            self.change_switch_state(i[0], i[1], not(i[1]))
            
        return self.switch_arr
    
    def toggle_in_loop(self, time_on_port1, time_on_port2, toggle_time):
        """
        Toggles all switches in a loop for a given time
        :param toggle_delay: delay between toggles in seconds
        :param toggle_time: time until switch is toggled in seconds
        """
        # make sure switches start from port1
        for i in self.switch_arr:
            self.change_switch_state(i[0], i[1], 0)

        start_time = time.time()
        while time.time() - start_time < toggle_time:
            # since all switches are on port1 to begin with, wait for time_on_port1 to elapse before toggling
            sleep(time_on_port1)
            self.toggle_all_switches()
            sleep(time_on_port2)
            self.toggle_all_switches() 
        print("Switches done toggling", self.switch_arr)            
        
    
if __name__ == '__main__':
    toggle = Toggle()
    
    # parse arguments
    import argparse
    parser = argparse.ArgumentParser(description='Toggle switches')
    parser.add_argument('--time_on_port1', type=float, help='time for which com->port1 is connected', required=True)
    parser.add_argument('--time_on_port2', type=float, help='time for which com->port2 is connected', required=True)
    parser.add_argument('--toggle_time', type=float, help='time until switch is toggled in seconds', required=True)
    args = parser.parse_args()

    toggle.toggle_in_loop(args.time_on_port1, args.time_on_port2, args.toggle_time)
