clc;
close all;
clear;

%% ================================================================
%  802.11n HT 2x2 MIMO Packet Error Rate Simulation
%  20 MHz, MCS 15, TGn Model-B
% ================================================================

%% Create HT configuration
cfgHT = wlanHTConfig;

cfgHT.ChannelBandwidth = 'CBW20';
cfgHT.NumTransmitAntennas = 2;
cfgHT.NumSpaceTimeStreams = 2;
cfgHT.PSDULength = 1000;
cfgHT.MCS = 15;
cfgHT.ChannelCoding = 'BCC';

%% ================================================================
% Configure TGn Channel
% ================================================================

tgnChannel = wlanTGnChannel;

tgnChannel.DelayProfile = 'Model-B';

tgnChannel.NumTransmitAntennas = ...
    cfgHT.NumTransmitAntennas;

tgnChannel.NumReceiveAntennas = 2;

tgnChannel.TransmitReceiveDistance = 10;

tgnChannel.LargeScaleFadingEffect = 'None';

%% ================================================================
% Simulation Parameters
% ================================================================

snr = 10:10:50;

maxNumPEs = 50;
maxNumPackets = 1000;

%% ================================================================
% Sampling Rate
% ================================================================

fs = wlanSampleRate(cfgHT);

%% Set TGn channel sampling rate
tgnChannel.SampleRate = fs;

%% ================================================================
% Get WLAN Field Indices
% ================================================================

ind = wlanFieldIndices(cfgHT);

%% Number of SNR points
S = numel(snr);

%% Preallocate PER array
packetErrorRate = NaN(S,1);

%% ================================================================
% Simulation Loop
% ================================================================

for i = 1:S

    disp(' ');
    disp('================================================');
    disp(['Starting simulation for SNR = ' num2str(snr(i)) ' dB']);
    disp('================================================');

    numPacketErrors = 0;
    n = 1;

    %% ------------------------------------------------------------
    % Loop over packets
    % -------------------------------------------------------------

    while (numPacketErrors <= maxNumPEs) && ...
            (n <= maxNumPackets)

        %% Generate random PSDU

        txPSDU = randi( ...
            [0 1], ...
            cfgHT.PSDULength * 8, ...
            1);

        %% Generate 802.11n HT waveform

        tx = wlanWaveformGenerator( ...
            txPSDU, ...
            cfgHT);

        %% Add trailing zeros
        % Allows for channel filter delay

        tx = [tx; ...
            zeros(15, cfgHT.NumTransmitAntennas)];

        %% --------------------------------------------------------
        % Pass waveform through TGn channel
        % ---------------------------------------------------------

        reset(tgnChannel);

        rxNoNoise = tgnChannel(tx);

        %% --------------------------------------------------------
        % Calculate received signal power
        % ---------------------------------------------------------

        signalPower = mean(abs(rxNoNoise(:)).^2);

        %% --------------------------------------------------------
        % Create AWGN channel
        % ---------------------------------------------------------

        awgnChannel = comm.AWGNChannel( ...
            'NoiseMethod', ...
            'Signal to noise ratio (SNR)', ...
            'SNR', ...
            snr(i), ...
            'SignalPower', ...
            signalPower);

        %% Add AWGN noise

        rx = awgnChannel(rxNoNoise);

        %% ========================================================
        % PACKET DETECTION
        % =========================================================

        coarsePktOffset = wlanPacketDetect( ...
            rx, ...
            cfgHT.ChannelBandwidth);

        %% If packet is not detected

        if isempty(coarsePktOffset)

            numPacketErrors = numPacketErrors + 1;

            n = n + 1;

            continue;

        end

        %% ========================================================
        % COARSE FREQUENCY OFFSET ESTIMATION
        % =========================================================

        lstf = rx( ...
            coarsePktOffset + ...
            (ind.LSTF(1):ind.LSTF(2)), ...
            :);

        coarseFreqOff = wlanCoarseCFOEstimate( ...
            lstf, ...
            cfgHT.ChannelBandwidth);

        %% Correct coarse frequency offset

        rx = frequencyOffset( ...
            rx, ...
            fs, ...
            -coarseFreqOff);

        %% ========================================================
        % FINE PACKET TIMING ESTIMATION
        % =========================================================

        nonhtfields = rx( ...
            coarsePktOffset + ...
            (ind.LSTF(1):ind.LSIG(2)), ...
            :);

        finePktOffset = wlanSymbolTimingEstimate( ...
            nonhtfields, ...
            cfgHT.ChannelBandwidth);

        %% Final packet offset

        pktOffset = coarsePktOffset + finePktOffset;

        %% Check packet offset

        if pktOffset > 15

            numPacketErrors = numPacketErrors + 1;

            n = n + 1;

            continue;

        end

        %% ========================================================
        % FINE FREQUENCY OFFSET ESTIMATION
        % =========================================================

        lltf = rx( ...
            pktOffset + ...
            (ind.LLTF(1):ind.LLTF(2)), ...
            :);

        fineFreqOff = wlanFineCFOEstimate( ...
            lltf, ...
            cfgHT.ChannelBandwidth);

        %% Correct fine frequency offset

        rx = frequencyOffset( ...
            rx, ...
            fs, ...
            -fineFreqOff);

        %% ========================================================
        % HT-LTF EXTRACTION
        % =========================================================

        htltf = rx( ...
            pktOffset + ...
            (ind.HTLTF(1):ind.HTLTF(2)), ...
            :);

        %% ========================================================
        % HT-LTF DEMODULATION
        % =========================================================

        htltfDemod = wlanHTLTFDemodulate( ...
            htltf, ...
            cfgHT);

        %% ========================================================
        % CHANNEL ESTIMATION
        % =========================================================

        chanEst = wlanHTLTFChannelEstimate( ...
            htltfDemod, ...
            cfgHT);

        %% ========================================================
        % EXTRACT HT-DATA
        % =========================================================

        htdata = rx( ...
            pktOffset + ...
            (ind.HTData(1):ind.HTData(2)), ...
            :);

        %% ========================================================
        % NOISE VARIANCE
        % ========================================================
        %
        % SNR = SignalPower / NoisePower
        %
        % Therefore:
        %
        % NoisePower = SignalPower / 10^(SNR/10)
        %
        % This replaces htNoiseEstimate(), which is unavailable
        % in the user's MATLAB installation.
        % =========================================================

        nVarHT = signalPower / ...
            (10^(snr(i)/10));

        %% ========================================================
        % HT DATA RECOVERY
        % =========================================================

        rxPSDU = wlanHTDataRecover( ...
            htdata, ...
            chanEst, ...
            nVarHT, ...
            cfgHT);

        %% ========================================================
        % CHECK PACKET ERROR
        % =========================================================

        packetError = any( ...
            biterr(txPSDU, rxPSDU));

        %% Update packet error count

        numPacketErrors = ...
            numPacketErrors + packetError;

        %% Increment packet counter

        n = n + 1;

    end

    %% ============================================================
    % Calculate Packet Error Rate
    % =============================================================

    packetErrorRate(i) = ...
        numPacketErrors / (n - 1);

    %% Display result

    disp(['SNR = ' num2str(snr(i)) ...
        ' dB | Packets = ' num2str(n-1) ...
        ' | Packet Errors = ' num2str(numPacketErrors) ...
        ' | PER = ' num2str(packetErrorRate(i))]);

end

%% ================================================================
% Plot PER versus SNR
% ================================================================

figure;

semilogy( ...
    snr, ...
    packetErrorRate, ...
    '-ob', ...
    'LineWidth', 1.5);

grid on;

xlabel('SNR [dB]');

ylabel('Packet Error Rate (PER)');

title( ...
    '802.11n 20 MHz, MCS 15, 2x2 TGn Model-B');

xlim([min(snr) max(snr)]);
