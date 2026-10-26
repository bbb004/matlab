% EXP 2: Diversity combining (SC, MRC, EGC) over Rayleigh and Rician channels
clc; clear; close all; rng(1);
SNR=-10:2:12; N=200000; B=zeros(numel(SNR),4,2,3);
for type=1:2 % 1=Rayleigh, 2=Rician
    for L=1:4 % Diversity branches
        for j=1:numel(SNR)
            bits=randi([0 1],1,2*N);
            s=(2*bits(1:N)-1)+1i*(2*bits(N+1:end)-1);
            h=(randn(L,N)+1i*randn(L,N))/sqrt(2);
            if type==2, h=(sqrt(1.5)+h)/sqrt(2.5); end
            r=h.*s+(randn(L,N)+1i*randn(L,N))/sqrt(2*10^(SNR(j)/10));
            [~,ix]=max(abs(h).^2,[],1);
            id=sub2ind([L N],ix,1:N);
            z{1}=conj(h(id)).*r(id); % SC
            z{2}=sum(conj(h).*r,1); % MRC
            z{3}=sum(conj(h)./abs(h).*r,1); % EGC
            for m=1:3
                B(j,L,type,m)=mean([real(z{m})>0 imag(z{m})>0]~=bits);
            end
        end
    end
end
names={'Selective Combining','Maximal Ratio Combining','Equal Gain Combining'};
channel={'Rayleigh','Ricean'};
for type=1:2
    for m=1:3
        figure; semilogy(SNR,squeeze(B(:,:,type,m)),'-*'); grid on;
        title(['BER of ' names{m} ' (' channel{type} ')']);
        xlabel('SNR (dB)'); ylabel('Bit error rate');
        legend('L=1','L=2','L=3','L=4');
    end
end
for type=1:2
    figure;
    semilogy(SNR,B(:,4,type,1),'-+',SNR,B(:,4,type,3),'-*',SNR,B(:,4,type,2),'-o');
    grid on; title(['BER of SC & MRC & EGC (' channel{type} ')']);
    xlabel('SNR (dB)'); ylabel('Bit error rate');
    legend('Selective Combining','Equal Gain Combining','Maximal Ratio Combining');
end
