% EXP 6: 4x2 IEEE 802.11n TGn channel - result is a spectrum analyzer
% Requires WLAN Toolbox and DSP System Toolbox
clc; clear; close all; rng(1);
cfg=wlanHTConfig('NumTransmitAntennas',4, ...
    'NumSpaceTimeStreams',2,'SpatialMapping','Fourier');
bits=randi([0 1],8*cfg.PSDULength,1);
tx=wlanWaveformGenerator(bits,cfg);
ch=wlanTGnChannel('SampleRate',20e6,'NumTransmitAntennas',4, ...
    'NumReceiveAntennas',2,'LargeScaleFadingEffect','None');
rx=ch(tx);
sa=spectrumAnalyzer('SampleRate',20e6,'ShowLegend',true, ...
    'ChannelNames',{'Stream 1','Stream 2'});
sa(rx);
