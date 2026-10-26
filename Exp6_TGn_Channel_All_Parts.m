% EXP 6: IEEE 802.11n MIMO TGn Channel (All 3 Parts)
% Requires WLAN Toolbox, Communications Toolbox, and DSP System Toolbox
clc; clear; close all; rng(1);

%% PART 1: 4x2 MIMO TGn Channel & Spectrum Analyzer
disp('--- PART 1: 4x2 MIMO TGn Channel ---');
cfg1=wlanHTConfig('NumTransmitAntennas',4, ...
    'NumSpaceTimeStreams',2,'SpatialMapping','Fourier');
bits1=randi([0 1],8*cfg1.PSDULength,1);
tx1=wlanWaveformGenerator(bits1,cfg1);
fs1=wlanSampleRate(cfg1);
disp(['HT sample rate = ',num2str(fs1/1e6),' MHz']);

ch1=wlanTGnChannel('SampleRate',fs1,'NumTransmitAntennas',4, ...
    'NumReceiveAntennas',2,'LargeScaleFadingEffect','None');
rx1=ch1(tx1);
sa=spectrumAnalyzer('SampleRate',fs1,'ShowLegend',true, ...
    'ChannelNames',{'Receive Antenna 1','Receive Antenna 2'});
sa(rx1);

%% PART 2: HT Data Recovery from 2x2 MIMO Channel
disp('--- PART 2: HT Data Recovery from 2x2 MIMO Channel ---');
cfg2=wlanHTConfig('ChannelBandwidth','CBW40', ...
    'NumTransmitAntennas',2,'NumSpaceTimeStreams',2);
fs2=wlanSampleRate(cfg2);
disp(['HT sample rate = ',num2str(fs2/1e6),' MHz']);

txPSDU=randi([0 1],8*cfg2.PSDULength,1);
txLTF=wlanHTLTF(cfg2);
txDataSig=wlanHTData(txPSDU,cfg2);

ch2=wlanTGnChannel('SampleRate',fs2,'NumTransmitAntennas',2, ...
    'NumReceiveAntennas',2,'LargeScaleFadingEffect','None');
snr=15;
chNoise=comm.AWGNChannel('NoiseMethod','Signal to noise ratio (SNR)', ...
    'SNR',snr,'SignalPower',1);

rxLTF_noisy=chNoise(ch2(txLTF));
rxDataSig_noisy=chNoise(ch2(txDataSig));
nVar=10^(-snr/10);
disp(['Noise variance = ',num2str(nVar)]);

dLTF=wlanHTLTFDemodulate(rxLTF_noisy,cfg2);
chEst=wlanHTLTFChannelEstimate(dLTF,cfg2);
rxPSDU=wlanHTDataRecover(rxDataSig_noisy,chEst,nVar,cfg2);

numErr=biterr(txPSDU,rxPSDU);
ber=numErr/length(txPSDU);
disp(['Number of bit errors = ',num2str(numErr)]);
disp(['Total transmitted bits = ',num2str(length(txPSDU))]);
disp(['BER = ',num2str(ber)]);

%% PART 3: TGn Random Number Stream Comparison
disp('--- PART 3: TGn Random Number Stream Comparison ---');
cfg3=wlanNonHTConfig;
tx3=wlanWaveformGenerator([1;0;0;1],cfg3);
ch3=wlanTGnChannel;
disp(['Default TGn RandomStream: ',ch3.RandomStream]);

rxGlobal=cell(2,1);
for i=1:2
    rxGlobal{i}=ch3(tx3);
    reset(ch3);
end
sameGlobal=isequal(rxGlobal{1},rxGlobal{2});
disp(['Are the two Global-stream outputs identical? ',mat2str(sameGlobal)]);

release(ch3);
ch3.RandomStream='mt19937ar with seed';
ch3.Seed=73;
disp(['RandomStream = ',ch3.RandomStream,' | Seed = ',num2str(ch3.Seed)]);

rxSeeded=cell(2,1);
for i=1:2
    rxSeeded{i}=ch3(tx3);
    reset(ch3);
end
sameSeeded=isequal(rxSeeded{1},rxSeeded{2});
disp(['Are the two seeded outputs identical? ',mat2str(sameSeeded)]);
