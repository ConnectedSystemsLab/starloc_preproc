## References

Links that might be useful.

### Signal capture

- Starlink Ku band signal capture
  - The owner of this blog captured downlink satellite-to-user traffic in the 250 MHz channels at: 11075, 11325 and 11575 MHz;
  - **9 tones** placed at the central 1MHz has been observed, as well as the guard interval between frames;
  - [Observations of Starlink Satellite -to- User Downlink w/ Software Defined Radio : StarlinkEngineering (reddit.com)](https://www.reddit.com/r/StarlinkEngineering/comments/qwm1v5/observations_of_starlink_satellite_to_user/)

### Signal processing

1. works by Zaher M. Kassas

   (This guy published many papers with similar contents, and he usually cites his own work :joy:)

   - First results 1

     This paper derives the signal model and formulate the satellite capturing problem as a subspace detection problem. After that, the doppler is estimated from which the location information can be recovered.

     [Acquisition, Doppler Tracking, and Positioning With Starlink LEO Satellites: First Results | IEEE Journals & Magazine | IEEE Xplore](https://ieeexplore.ieee.org/document/9612022)

   - First results 3

     A longer version of "first results 1 & 2". (In addition, it is not well written. Some notations don't make sense)

     [First Results of Differential Doppler Positioning with Unknown Starlink Satellite Signals | IEEE Conference Publication | IEEE Xplore](https://ieeexplore.ieee.org/document/9843493)

   - Signal structure

     This paper unveils the signal structure of the transmitted OFDM-like signal, e.g., a $1.32$ ms frame period (Fig. 2), central tones (Fig. 1).

     [Unveiling Starlink LEO Satellite OFDM-Like Signal Structure Enabling Precise Positioning | IEEE Journals & Magazine | IEEE Xplore](https://ieeexplore.ieee.org/document/10098597)

   - Phase tracking

     This paper utilizes the central tones to position.

     [The First Carrier Phase Tracking and Positioning Results With Starlink LEO Satellite Signals | IEEE Journals & Magazine | IEEE Xplore](https://ieeexplore.ieee.org/document/9541006)

2. U. of T. @ Austin

   - Signal structure

     More detailed

     [Signal Structure of the Starlink Ku-Band Downlink | IEEE Journals & Magazine | IEEE Xplore](https://ieeexplore.ieee.org/document/10107477)

### Simulation

- MATLAB Satellite toolbox
  - can be used to simulate the satellite trajectory based on TLE files, from which doppler frequency shift can be calculated;
  - [Matlab toolbox webpage](https://www.mathworks.com/products/satellite-communications.html)
  - [Calculate Latency and Doppler in a Satellite Scenario - MATLAB & Simulink - MathWorks](https://ww2.mathworks.cn/help/satcom/ug/calculate-latency-and-doppler-in-a-satellite-scenario.html)
- TLE file website
  - newest TLE can be found on [CelesTrak: Current Supplemental GP Element Sets](http://celestrak.org/NORAD/elements/supplemental/).