clc;
clear;
close all;

%% ================================================================
% Modified SUI-1 Channel Model
% Doppler Spectrum and Fading Envelope Analysis
% ================================================================

%% Simulation parameters

Rsamp = 0.1e6;
Ns = 3e6;

%% ================================================================
% Create modified SUI-1 MIMO channel
% ================================================================

wimaxChan = comm.MIMOChannel( ...
    'SampleRate', Rsamp, ...
    'PathDelays', [0 0.4 0.9] * 1e-6, ...
    'AveragePathGains', [0 -15 -20], ...
    'FadingDistribution', 'Rician', ...
    'KFactor', 4, ...
    'MaximumDopplerShift', 0.5, ...
    'DopplerSpectrum', doppler('Rounded'), ...
    'TransmitCorrelationMatrix', [1 0.7; 0.7 1], ...
    'ReceiveCorrelationMatrix', 1, ...
    'PathGainsOutputPort', true);

%% ================================================================
% Generate long QPSK frame
% ================================================================

Nt = size(wimaxChan.TransmitCorrelationMatrix, 1);

x = pskmod( ...
    randi([0 3], Ns, Nt), ...
    4);

%% ================================================================
% Pass signal through channel
% ================================================================

[~, g] = wimaxChan(x);

%% ================================================================
% Doppler spectrum of the 1st link of the 2nd path
% ================================================================

figure;

win = hamming(Ns/5);

Noverlap = Ns/10;

pwelch( ...
    g(:,2,1), ...
    win, ...
    Noverlap, ...
    [], ...
    Rsamp, ...
    'centered');

axis([-0.1/10 0.1/10 -80 10]);

legend('Simulation');

title('Doppler Spectrum - 1st Link of 2nd Path');

%% ================================================================
% Theoretical rounded Doppler spectrum
% ================================================================

fd = wimaxChan.MaximumDopplerShift;

f = -fd:0.01:fd;

a = wimaxChan.DopplerSpectrum.Polynomial;

%% Theoretical rounded Doppler spectrum

Sd = 1 / ...
    (2 * fd * ...
    (a(1) + a(2)/3 + a(3)/5)) ...
    .* ...
    ( ...
    a(1) ...
    + a(2) * (f/fd).^2 ...
    + a(3) * (f/fd).^4);

%% Scale by average path power

Sd = Sd * ...
    10^(wimaxChan.AveragePathGains(2)/10);

%% Overlay theoretical spectrum

hold on;

plot( ...
    f(Sd > 0)/1e3, ...
    10*log10(Sd(Sd > 0)), ...
    'k--');

legend( ...
    'Simulation', ...
    'Theory');

%% ================================================================
% Doppler spectrum of the 2nd link of the 2nd path
% ================================================================

figure;

pwelch( ...
    g(:,2,2), ...
    win, ...
    Noverlap, ...
    [], ...
    Rsamp, ...
    'centered');

axis([-0.1/10 0.1/10 -80 10]);

legend('Simulation');

title('Doppler Spectrum - 2nd Link of 2nd Path');

%% Overlay theoretical spectrum

hold on;

plot( ...
    f(Sd > 0)/1e3, ...
    10*log10(Sd(Sd > 0)), ...
    'k--');

legend( ...
    'Simulation', ...
    'Theory');

%% ================================================================
% Fading envelopes for Path 1
% ================================================================

figure;

semilogy( ...
    abs(g(:,1,1)), ...
    'b');

hold on;

grid on;

semilogy( ...
    abs(g(:,1,2)), ...
    'r');

legend( ...
    'First transmit link', ...
    'Second transmit link');

title( ...
    'Fading envelopes for two transmit links of Path 1');

%% ================================================================
% Fading envelopes for Path 2
% ================================================================

figure;

semilogy( ...
    abs(g(:,2,1)), ...
    'b');

hold on;

grid on;

semilogy( ...
    abs(g(:,2,2)), ...
    'r');

legend( ...
    'First transmit link', ...
    'Second transmit link');

title( ...
    'Fading envelopes for two transmit links of Path 2');

%% ================================================================
% Fading envelopes for Path 3
% ================================================================

figure;

semilogy( ...
    abs(g(:,3,1)), ...
    'b');

hold on;

grid on;

semilogy( ...
    abs(g(:,3,2)), ...
    'r');

legend( ...
    'First transmit link', ...
    'Second transmit link');

title( ...
    'Fading envelopes for two transmit links of Path 3');

%% ================================================================
% Transmit correlation coefficients
% ================================================================

TxCorrMatrixPath1 = corrcoef( ...
    g(:,1,1), ...
    g(:,1,2)).';

TxCorrMatrixPath2 = corrcoef( ...
    g(:,2,1), ...
    g(:,2,2)).';

TxCorrMatrixPath3 = corrcoef( ...
    g(:,3,1), ...
    g(:,3,2)).';

%% ================================================================
% Display correlation matrices
% ================================================================

disp(' ');
disp('==============================================');
disp('Transmit Correlation Matrix - Path 1');
disp('==============================================');

disp(TxCorrMatrixPath1);

disp(' ');
disp('==============================================');
disp('Transmit Correlation Matrix - Path 2');
disp('==============================================');

disp(TxCorrMatrixPath2);

disp(' ');
disp('==============================================');
disp('Transmit Correlation Matrix - Path 3');
disp('==============================================');

disp(TxCorrMatrixPath3);

%% ================================================================
% Display correlation coefficients
% ================================================================

disp(' ');
disp('==============================================');
disp('Correlation Coefficients');
disp('==============================================');

disp(['Path 1 = ' ...
    num2str(TxCorrMatrixPath1(1,2))]);

disp(['Path 2 = ' ...
    num2str(TxCorrMatrixPath2(1,2))]);

disp(['Path 3 = ' ...
    num2str(TxCorrMatrixPath3(1,2))]);

disp(' ');
disp('Specified transmit correlation = 0.7');
