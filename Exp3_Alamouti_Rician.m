% EXP 3: Alamouti 2x1 / 2x2 over a Rician channel
% Requires Communications Toolbox: pskmod, pskdemod, berfading, biterr
clc; clear; close all; rng(1);
Eb=0:10; Ks=[4 .6]; Ms=[4 8]; N=40000; % CHANGE THE K VALUE HERE ACCORDING TO QUESTION
for ki=1:2
    K=Ks(ki); figure; hold on;
    for nr=1:2
        for mi=1:2
            M=Ms(mi); b=log2(M); sim=zeros(size(Eb));
            for j=1:numel(Eb)
                q=randi([0 M-1],2*N,1); s=pskmod(q,M,0,'gray');
                s1=s(1:2:end); s2=s(2:2:end);
                u=zeros(N,1); v=zeros(N,1);
                h=(sqrt(K)+(randn(nr,2,N)+1i*randn(nr,2,N))/sqrt(2))/sqrt(K+1);
                n0=1/(b*10^(Eb(j)/10));
                for r=1:nr
                    h1=reshape(h(r,1,:),N,1); h2=reshape(h(r,2,:),N,1);
                    y1=(h1.*s1+h2.*s2)/sqrt(2)+sqrt(n0/2)*(randn(N,1)+1i*randn(N,1));
                    y2=(-h1.*conj(s2)+h2.*conj(s1))/sqrt(2)+sqrt(n0/2)*(randn(N,1)+1i*randn(N,1));
                    u=u+conj(h1).*y1+h2.*conj(y2);
                    v=v+conj(h2).*y1-h1.*conj(y2);
                end
                dec=pskdemod(reshape([u.';v.'],[],1),M,0,'gray');
                sim(j)=biterr(q,dec,b)/(2*N*b);
            end
            a=(nr-1)*2+mi;
            pSim(a)=semilogy(Eb,sim,'o-','LineWidth',1.1);
            pTh(a)=semilogy(Eb,berfading(Eb,'psk',M,2*nr,K),'-');
        end
    end
    set(gca,'YScale','log'); grid on;
    title(['Rician model (K = ' num2str(K) ')']);
    xlabel('EbNo (dB)'); ylabel('BER');
    legend([pSim(1:2) pTh(1:2) pSim(3:4) pTh(3:4)], ...
        'QPSK(simulated) 2x1','8-PSK(simulated) 2x1', ...
        'QPSK(theory) 2x1','8-PSK(theory) 2x1', ...
        'QPSK(simulated) 2x2','8-PSK(simulated) 2x2', ...
        'QPSK(theory) 2x2','8-PSK(theory) 2x2');
end
