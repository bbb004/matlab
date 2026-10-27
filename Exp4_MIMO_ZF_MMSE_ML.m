Nt = 2;                     % Transmit antennas
Nr = 2;                     % Receive antennas
    
EbNoVec = -10:5:20;
modOrd = 2;                 % QPSK (2 bits/symbol)
M = 2^modOrd;

stream = RandStream('mt19937ar');

%% Generate all ML candidates
allBits = de2bi(0:2^(modOrd*Nt)-1, modOrd*Nt, 'left-msb').';
allTxSig = reshape(pskmod(allBits(:), M, 0, 'gray', 'InputType','bit'), ...
                   Nt, []);

%% BER Arrays
BER_ZF = zeros(length(EbNoVec),1);
BER_MMSE = zeros(length(EbNoVec),1);
BER_ML = zeros(length(EbNoVec),1);

%% Simulation Parameters
maxBits = 1e5;
maxErrs = 100;

%% Plot
figure;
hold on;
grid on;
set(gca,'YScale','log');
xlabel('Eb/No (dB)');
ylabel('BER');
title('2x2 Spatial Multiplexing (QPSK)');
ylim([1e-4 1]);

%% Loop over SNR
for idx = 1:length(EbNoVec)

    snrIndB = EbNoVec(idx) + 10*log10(modOrd);
    snrLinear = 10^(snrIndB/10);

    totalBits = 0;

    errZF = 0;
    errMMSE = 0;
    errML = 0;

    while totalBits < maxBits && ...
         (errZF < maxErrs || errMMSE < maxErrs || errML < maxErrs)

        %% Random bits
        msg = randi(stream,[0 1],Nt*modOrd,1);

        %% QPSK Modulation
        txSig = pskmod(msg,M,0,'gray','InputType','bit');

        %% Rayleigh Channel
        H = (randn(stream,Nr,Nt)+1i*randn(stream,Nr,Nt))/sqrt(2);

        %% AWGN
        rxSig = awgn(H*txSig,snrIndB,'measured',stream);

        %% =======================
        %% ZF-SIC
        %% =======================
        r = rxSig;
        Htemp = H;

        estZF = zeros(Nt*modOrd,1);
        orderVec = 1:Nt;

        for n = 1:Nt

            G = (Htemp'*Htemp)\eye(size(Htemp,2));

            [~,k] = min(diag(G));

            symNum = orderVec(k);

            detected = G(k,:)*Htemp'*r;

            bits = pskdemod(detected,M,0,'gray','OutputType','bit');

            estZF((symNum-1)*modOrd+1:symNum*modOrd)=bits;

            if n<Nt
                r = r - Htemp(:,k)*pskmod(bits,M,0,'gray','InputType','bit');
            end

            Htemp(:,k)=[];
            orderVec(k)=[];

        end

        %% =======================
        %% MMSE-SIC
        %% =======================
        r = rxSig;
        Htemp = H;

        estMMSE = zeros(Nt*modOrd,1);
        orderVec = 1:Nt;

        for n = 1:Nt

            G = (Htemp'*Htemp + ...
                (size(Htemp,2)/snrLinear)*eye(size(Htemp,2)))\eye(size(Htemp,2));

            [~,k] = min(diag(G));

            symNum = orderVec(k);

            detected = G(k,:)*Htemp'*r;

            bits = pskdemod(detected,M,0,'gray','OutputType','bit');

            estMMSE((symNum-1)*modOrd+1:symNum*modOrd)=bits;

            if n<Nt
                r = r - Htemp(:,k)*pskmod(bits,M,0,'gray','InputType','bit');
            end

            Htemp(:,k)=[];
            orderVec(k)=[];

        end

        %% =======================
        %% ML Detection
        %% =======================
        metric = sum(abs(rxSig - H*allTxSig).^2,1);

        [~,k] = min(metric);

        estML = allBits(:,k);

        %% BER Update
        errZF = errZF + biterr(msg,estZF);
        errMMSE = errMMSE + biterr(msg,estMMSE);
        errML = errML + biterr(msg,estML);

        totalBits = totalBits + length(msg);

    end

    BER_ZF(idx) = errZF/totalBits;
    BER_MMSE(idx) = errMMSE/totalBits;
    BER_ML(idx) = errML/totalBits;

    fprintf('Eb/No = %2d dB | ZF = %.3e | MMSE = %.3e | ML = %.3e\n',...
        EbNoVec(idx),BER_ZF(idx),BER_MMSE(idx),BER_ML(idx));

end

%% Plot Results
semilogy(EbNoVec,BER_ZF,'r*-','LineWidth',1.5);
semilogy(EbNoVec,BER_MMSE,'bo-','LineWidth',1.5);
semilogy(EbNoVec,BER_ML,'gd-','LineWidth',1.5);

legend('ZF-SIC','MMSE-SIC','ML','Location','southwest');
grid on;
