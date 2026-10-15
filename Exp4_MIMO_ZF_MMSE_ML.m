% EXP 4: 2x2 QPSK MIMO with ZF-SIC, MMSE-SIC and ML
% Requires Communications Toolbox: pskmod, pskdemod, biterr
clc; clear; close all; rng(1);
Eb=-10:5:20; N=10000; BER=zeros(numel(Eb),3);
Q=pskmod((0:3)',4);
[a,b]=ndgrid(1:4);
C=[Q(a(:)) Q(b(:))]';
for j=1:numel(Eb)
    n0=1/(2*10^(Eb(j)/10));
    for k=1:N
        idx=randi(4,2,1); s=reshape(Q(idx),2,1);
        H=(randn(2)+1i*randn(2))/sqrt(2);
        y=H*s+sqrt(n0/2)*(randn(2,1)+1i*randn(2,1));
        for m=1:2
            if m==1, W=pinv(H); else, W=(H'*H+n0*eye(2))\H'; end
            [~,first]=min(sum(abs(W).^2,2)); second=3-first;
            s1=pskmod(pskdemod(W(first,:)*y,4),4);
            rest=y-H(:,first)*s1;
            s2=(H(:,second)'*rest)/(H(:,second)'*H(:,second));
            est=zeros(2,1); est(first)=pskdemod(s1,4);
            est(second)=pskdemod(s2,4);
            BER(j,m)=BER(j,m)+biterr(idx-1,est,2);
        end
        [~,best]=min(sum(abs(y-H*C).^2,1));
        BER(j,3)=BER(j,3)+biterr(idx-1,pskdemod(C(:,best),4),2);
    end
end
BER=BER/(4*N);
figure; semilogy(Eb,BER(:,1),'r*-',Eb,BER(:,2),'bo-',Eb,BER(:,3),'gd-');
grid on; axis([-10 20 1e-3 1]);
title('2x2 Uncoded QPSK System');
xlabel('Eb/No (dB)'); ylabel('BER');
legend('ZF-SIC','MMSE-SIC','ML');
