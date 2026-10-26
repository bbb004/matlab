% EXP 7: SUI-1 MIMO channel (IEEE 802.16 WiMAX) - 2 Doppler PSD and 3 envelope graphs
% Requires Communications Toolbox and Signal Processing Toolbox
clc; clear; close all; rng(1);
Fs=0.1e6; N=3e6; % Keep N=3e6 to match record's graph x-axis
ch=comm.MIMOChannel('SampleRate',Fs, ...
    'PathDelays',[0 .4 .9]*1e-6,'AveragePathGains',[0 -15 -20], ...
    'FadingDistribution','Rician','KFactor',4, ...
    'MaximumDopplerShift',.5,'DopplerSpectrum',doppler('Rounded'), ...
    'TransmitCorrelationMatrix',[1 .7;.7 1], ...
    'ReceiveCorrelationMatrix',1,'PathGainsOutputPort',true);
x=pskmod(randi([0 3],N,2),4); [~,g]=ch(x);
fd=ch.MaximumDopplerShift; f=-fd:.01:fd;
a=ch.DopplerSpectrum.Polynomial;
Sd=(a(1)+a(2)*(f/fd).^2+a(3)*(f/fd).^4) ...
    /(2*fd*(a(1)+a(2)/3+a(3)/5))*10^(-15/10);
for k=1:2
    [P,F]=pwelch(g(:,2,k),hamming(N/5),N/10,[],Fs,'centered');
    figure; plot(F/1e3,10*log10(P)); hold on;
    plot(f(Sd>0)/1e3,10*log10(Sd(Sd>0)),'k--');
    axis([-.01 .01 -80 10]); grid on;
    title(['Doppler Spectrum - Link ' num2str(k) ' of 2nd Path']);
    xlabel('Frequency (kHz)'); ylabel('Power/frequency (dB/Hz)');
    legend('Simulation','Theory');
end
for k=1:3
    figure; semilogy(abs(g(:,k,1)),'b'); hold on;
    semilogy(abs(g(:,k,2)),'r'); grid on;
    title(['Fading envelopes for two transmit links of Path ' num2str(k)]);
    legend('First transmit link','Second transmit link');
    C=corrcoef(g(:,k,1),g(:,k,2)).';
    disp(['Tx correlation matrix, path ' num2str(k)]);
    disp(C);
    disp(['Path ' num2str(k) ' correlation = ' num2str(C(1,2))]);
end
disp('Specified transmit correlation = 0.7');
