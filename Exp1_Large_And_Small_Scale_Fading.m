% EXP 1: Large-scale and Small-scale fading + Link Budget
clc; clear; close all; rng(1);
fc=1.5e9; d=(1:2:31).^2; d0=100; sigma=3;
Gt=[1 1 .5]; Gr=[1 .5 .5]; n=[2 3 6];
P0=20*log10(4*pi*d0*fc/3e8);
for k=1:3
    F(k,:)=20*log10(4*pi*d*fc/3e8)-10*log10(Gt(k)*Gr(k));
    D(k,:)=P0+10*n(k)*log10(d/d0);
    S(k,:)=P0+20*log10(d/d0)+sigma*randn(size(d));
end

% Link Budget
Pr=40+10+2-4-S(1,:);
margin=Pr-(-90);

% Small-Scale Fading (Rayleigh and Rician)
N=1e5; K=10^(6/10);
R=abs((randn(1,N)+1i*randn(1,N))/sqrt(2));
I=abs(sqrt(K/(K+1))+sqrt(1/(2*(K+1)))*(randn(1,N)+1i*randn(1,N)));

% Figure 1: Free Space
figure; semilogx(d,F(1,:),'r-o',d,F(2,:),'r-^',d,F(3,:),'r-s');
title('Free Path-loss Model, f_c=1500MHz');
legend('G_t=1, G_r=1','G_t=1, G_r=0.5','G_t=0.5, G_r=0.5');
axis([1 1000 40 110]); xlabel('Distance[m]'); ylabel('Path loss[dB]'); grid on;

% Figure 2: Log-distance
figure; semilogx(d,D(1,:),'r-o',d,D(2,:),'r-^',d,D(3,:),'r-s');
title('Log-distance Path-loss Model, f_c=1500MHz');
legend('n=2','n=3','n=6');
axis([1 1000 40 110]); xlabel('Distance[m]'); ylabel('Path loss[dB]'); grid on;

% Figure 3: Log-normal Shadowing & Link Budget
figure;
subplot(2,1,1);
semilogx(d,S(1,:),'r-o',d,S(2,:),'r-^',d,S(3,:),'r-s');
title('Log-normal Path-loss Model, f_c=1500MHz, sigma=3dB, n=2');
legend('path 1','path 2','path 3');
axis([1 1000 40 110]); xlabel('Distance[m]'); ylabel('Path loss[dB]'); grid on;

subplot(2,1,2);
semilogx(d,Pr,'b',d,-90*ones(size(d)),'r--');
grid on; title('Link Budget');
xlabel('Distance[m]'); ylabel('Received Power (dBm)');
legend('Received Power','Sensitivity (-90 dBm)');

% Figure 4: Small-Scale Fading Histograms
figure;
histogram(R,100,'Normalization','pdf'); hold on;
histogram(I,100,'Normalization','pdf');
grid on; title('Rayleigh and Rician Fading');
legend('Rayleigh','Rician');
xlabel('Amplitude'); ylabel('PDF');
