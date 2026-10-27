% EXP 5: Genuine 802.11n packet-error-rate experiment (not a drawn curve)
% Requires WLAN Toolbox and Communications Toolbox
clc; clear; close all; rng(1);
cfg=wlanHTConfig('ChannelBandwidth','CBW20','NumTransmitAntennas',2, ...
    'NumSpaceTimeStreams',2,'PSDULength',1000,'MCS',15,'ChannelCoding','BCC');
fs=wlanSampleRate(cfg); ind=wlanFieldIndices(cfg);
ofdm=wlanHTOFDMInfo('HT-Data',cfg);
ch=wlanTGnChannel('SampleRate',fs,'DelayProfile','Model-B', ...
    'NumTransmitAntennas',2,'NumReceiveAntennas',2, ...
    'TransmitReceiveDistance',10,'LargeScaleFadingEffect','None');
snr=10:5:50; PER=zeros(size(snr));
maxErrors=200; maxPackets=10000; % Same limits as the record
for j=1:numel(snr)
    eff=snr(j)-10*log10(ofdm.FFTLength/ofdm.NumTones);
    noise=comm.AWGNChannel('NoiseMethod','Signal to noise ratio (SNR)', ...
        'SNR',eff,'SignalPower',.5);
    nVar=.5*10^(-eff/10); errors=0; packets=0;
    while errors<maxErrors && packets<maxPackets
        bits=randi([0 1],8*cfg.PSDULength,1);
        tx=[wlanWaveformGenerator(bits,cfg);zeros(15,2)];
        reset(ch); rx=noise(ch(tx)); packets=packets+1;
        p=wlanPacketDetect(rx,cfg.ChannelBandwidth);
        if isempty(p) || p>15, errors=errors+1; continue; end
        lstf=rx(p+(ind.LSTF(1):ind.LSTF(2)),:);
        rx=frequencyOffset(rx,fs,-wlanCoarseCFOEstimate(lstf,cfg.ChannelBandwidth));
        p=p+wlanSymbolTimingEstimate(rx(p+(ind.LSTF(1):ind.LSIG(2)),:),cfg.ChannelBandwidth);
        if p<0 || p>15, errors=errors+1; continue; end
        lltf=rx(p+(ind.LLTF(1):ind.LLTF(2)),:);
        rx=frequencyOffset(rx,fs,-wlanFineCFOEstimate(lltf,cfg.ChannelBandwidth));
        ltf=rx(p+(ind.HTLTF(1):ind.HTLTF(2)),:);
        H=wlanHTLTFChannelEstimate(wlanHTLTFDemodulate(ltf,cfg),cfg);
        data=rx(p+(ind.HTData(1):ind.HTData(2)),:);
        out=wlanHTDataRecover(data,H,nVar,cfg);
        errors=errors+any(out~=bits);
    end
    PER(j)=errors/packets;
    fprintf('SNR %d completed after %d packets, PER: %.5f\n',snr(j),packets,PER(j));
end
figure; semilogy(snr,PER,'-ob'); grid on;
xlabel('SNR [dB]'); ylabel('PER');
title('802.11n 20MHz, MCS15, Direct Mapping, 2x2 Channel Model B-NLOS');
