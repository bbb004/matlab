clc;
clear;
close all;

%% ================================================================
% PART 1
% Create an HT waveform with:
% 4 transmit antennas
% 2 space-time streams
% Fourier spatial mapping
% ================================================================

disp(' ');
disp('================================================');
disp('PART 1: 4x2 MIMO TGn Channel');
disp('================================================');

%% Create HT configuration

cfg1 = wlanHTConfig( ...
    'NumTransmitAntennas', 4, ...
    'NumSpaceTimeStreams', 2, ...
    'SpatialMapping', 'Fourier');

%% Generate HT waveform

txSig = wlanWaveformGenerator( ...
    [1; 0; 0; 1], ...
    cfg1);

%% Get correct sampling rate from configuration

fs1 = wlanSampleRate(cfg1);

disp(['HT sample rate = ' num2str(fs1/1e6) ' MHz']);

%% Create 4x2 TGn channel

tgnChan1 = wlanTGnChannel( ...
    'SampleRate', fs1, ...
    'NumTransmitAntennas', 4, ...
    'NumReceiveAntennas', 2, ...
    'LargeScaleFadingEffect', 'None');

%% Pass waveform through TGn channel

rxSig = tgnChan1(txSig);

%% Display spectrum

saScope = spectrumAnalyzer( ...
    'SampleRate', fs1, ...
    'ShowLegend', true, ...
    'ChannelNames', {'Receive Antenna 1', ...
                     'Receive Antenna 2'});

saScope(rxSig);

%% ================================================================
% PART 2
% Recover HT Data from a 2x2 MIMO TGn Channel
% ================================================================

disp(' ');
disp('================================================');
disp('PART 2: HT Data Recovery from 2x2 MIMO Channel');
disp('================================================');

%% Channel bandwidth and sample rate

bw = 'CBW40';

%% Create HT configuration

cfg2 = wlanHTConfig( ...
    'ChannelBandwidth', bw, ...
    'NumTransmitAntennas', 2, ...
    'NumSpaceTimeStreams', 2);

%% Get sample rate directly from configuration

fs2 = wlanSampleRate(cfg2);

disp(['HT sample rate = ' num2str(fs2/1e6) ' MHz']);

%% Generate random PSDU

txPSDU = randi( ...
    [0 1], ...
    8 * cfg2.PSDULength, ...
    1);

%% Generate HT-LTF

txLTF = wlanHTLTF(cfg2);

%% Generate HT-Data field

txDataSig = wlanHTData( ...
    txPSDU, ...
    cfg2);

%% ================================================================
% Create 2x2 TGn channel
% ================================================================

tgnChan2 = wlanTGnChannel( ...
    'SampleRate', fs2, ...
    'NumTransmitAntennas', 2, ...
    'NumReceiveAntennas', 2, ...
    'LargeScaleFadingEffect', 'None');

%% ================================================================
% AWGN CHANNEL
%
% We use ONE AWGN channel here.
%
% SNR = 15 dB
% ================================================================

snr = 15;

chNoise = comm.AWGNChannel( ...
    'NoiseMethod', ...
    'Signal to noise ratio (SNR)', ...
    'SNR', snr, ...
    'SignalPower', 1);

%% ================================================================
% Pass HT-LTF through TGn channel
% ================================================================

rxLTF_noisy = chNoise( ...
    tgnChan2(txLTF));

%% Pass HT Data through TGn channel

rxDataSig_noisy = chNoise( ...
    tgnChan2(txDataSig));

%% ================================================================
% Noise variance estimate
%
% For a normalized signal:
%
% Noise variance = 10^(-SNR/10)
%
% This is the value required by wlanHTDataRecover.
% ================================================================

nVar = 10^(-snr/10);

disp(['Noise variance = ' num2str(nVar)]);

%% ================================================================
% HT-LTF DEMODULATION
% ================================================================

dLTF = wlanHTLTFDemodulate( ...
    rxLTF_noisy, ...
    cfg2);

%% ================================================================
% CHANNEL ESTIMATION
% ================================================================

chEst = wlanHTLTFChannelEstimate( ...
    dLTF, ...
    cfg2);

%% ================================================================
% HT DATA RECOVERY
% ================================================================

rxPSDU = wlanHTDataRecover( ...
    rxDataSig_noisy, ...
    chEst, ...
    nVar, ...
    cfg2);

%% ================================================================
% Calculate number of bit errors
% ================================================================

numErr = biterr( ...
    txPSDU, ...
    rxPSDU);

%% Calculate BER

ber = numErr / length(txPSDU);

%% Display results

disp(['Number of bit errors = ' num2str(numErr)]);

disp(['Total transmitted bits = ' ...
    num2str(length(txPSDU))]);

disp(['BER = ' num2str(ber)]);

%% ================================================================
% PART 3
% Compare Random Number Sources for TGn Channel
% ================================================================

disp(' ');
disp('================================================');
disp('PART 3: TGn Random Number Stream Comparison');
disp('================================================');

%% Create Non-HT configuration

cfg3 = wlanNonHTConfig;

%% Generate waveform

tx = wlanWaveformGenerator( ...
    [1; 0; 0; 1], ...
    cfg3);

%% Create TGn channel with default parameters

tgnChan3 = wlanTGnChannel;

%% Display default random stream

disp('Default TGn RandomStream:');

disp(tgnChan3.RandomStream);

%% ================================================================
% GLOBAL STREAM
% ================================================================

disp(' ');
disp('Testing Global stream...');

%% Preallocate

rxGlobal = cell(2,1);

%% Pass waveform through channel twice

for i = 1:2

    rxGlobal{i} = tgnChan3(tx);

    reset(tgnChan3);

end

%% Compare received waveforms

sameGlobal = isequal( ...
    rxGlobal{1}, ...
    rxGlobal{2});

disp(['Are the two Global-stream outputs identical? ' ...
    mat2str(sameGlobal)]);

%% ================================================================
% MT19937AR WITH SEED
% ================================================================

%% Release channel before changing property

release(tgnChan3);

%% Set random stream

tgnChan3.RandomStream = ...
    'mt19937ar with seed';

%% Set seed

tgnChan3.Seed = 73;

disp(' ');
disp('RandomStream after changing:');

disp(tgnChan3.RandomStream);

disp(['Seed = ' num2str(tgnChan3.Seed)]);

%% ================================================================
% Generate two channel realizations
% ================================================================

rxSeeded = cell(2,1);

for i = 1:2

    rxSeeded{i} = tgnChan3(tx);

    reset(tgnChan3);

end

%% Compare seeded outputs

sameSeeded = isequal( ...
    rxSeeded{1}, ...
    rxSeeded{2});

disp(['Are the two seeded outputs identical? ' ...
    mat2str(sameSeeded)]);

%% ================================================================
% Final summary
% ================================================================

disp(' ');
disp('================================================');
disp('SIMULATION SUMMARY');
disp('================================================');

disp('Part 1: 4x2 TGn channel waveform generated.');

disp(['Part 2: Bit errors = ' num2str(numErr)]);

disp(['Part 2: BER = ' num2str(ber)]);

disp(['Part 3: Global stream identical = ' ...
    mat2str(sameGlobal)]);

disp(['Part 3: Seeded stream identical = ' ...
    mat2str(sameSeeded)]);

disp('================================================');
