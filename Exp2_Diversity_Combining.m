clc;
clear;
close all;

sample_num = 100000;

% Preallocation for Bit Error Rate
Pe_sc  = zeros(12,4,2);   % Selective Combining
Pe_mrc = zeros(12,4,2);   % Maximal Ratio Combining
Pe_egc = zeros(12,4,2);   % Equal Gain Combining

tic

for R = 0:1      % Rayleigh = 0, Ricean = 1

    % Different fading channel has different variance
    if R == 0
        sigma = 1/sqrt(2);
    else
        sigma = 1/2;
    end

    SNR = -10:2:12;

    for enr_index = 1:length(SNR)

        % SNR (Linear)
        enr = 10^(SNR(enr_index)/10);

        % Generate QPSK data (2 bits/symbol)
        data = rand(2, sample_num);
        data = 2*(data > 0.5) - 1;

        Edata = sqrt(2);
        En = Edata / enr;

        for L = 1:4

            % Generate AWGN
            n = normrnd(0, sqrt(En/2), 2, sample_num, L) + ...
                1i*normrnd(0, sqrt(En/2), 2, sample_num, L);

            % Generate fading gain
            g = normrnd(R/2, sigma, 1, sample_num, L) + ...
                1i*normrnd(R/sqrt(2), 1/2, 1, sample_num, L);

            g_tmp = repmat(g, 2, 1, 1);
            tx_data = repmat(data, 1, 1, L);

            % Received signal
            r = g_tmp .* tx_data + n;

            %% Selective Combining
            [Pe_sc(enr_index,L,R+1), result_sc] = ...
                selective_combining(g, g_tmp, r, sample_num, data);

            %% Maximal Ratio Combining
            [Pe_mrc(enr_index,L,R+1), result_mrc] = ...
                maximal_ratio_combining(g_tmp, r, sample_num, data);

            %% Equal Gain Combining
            [Pe_egc(enr_index,L,R+1), result_egc] = ...
                equal_gain_combining(g_tmp, r, sample_num, data);

        end
    end
end

toc

%% ---------------- Rayleigh ----------------

figure;
plot(SNR, Pe_sc(:,:,1), '-*');
set(gca,'YScale','log');
title('BER of Selective Combining (Rayleigh)');
xlabel('SNR (dB)');
ylabel('Bit Error Rate');
legend('L=1','L=2','L=3','L=4');

figure;
plot(SNR, Pe_mrc(:,:,1), '-*');
set(gca,'YScale','log');
title('BER of Maximal Ratio Combining (Rayleigh)');
xlabel('SNR (dB)');
ylabel('Bit Error Rate');
legend('L=1','L=2','L=3','L=4');

figure;
plot(SNR, Pe_egc(:,:,1), '-*');
set(gca,'YScale','log');
title('BER of Equal Gain Combining (Rayleigh)');
xlabel('SNR (dB)');
ylabel('Bit Error Rate');
legend('L=1','L=2','L=3','L=4');

%% ---------------- Ricean ----------------

figure;
plot(SNR, Pe_sc(:,:,2), '-*');
set(gca,'YScale','log');
title('BER of Selective Combining (Ricean)');
xlabel('SNR (dB)');
ylabel('Bit Error Rate');
legend('L=1','L=2','L=3','L=4');

figure;
plot(SNR, Pe_mrc(:,:,2), '-*');
set(gca,'YScale','log');
title('BER of Maximal Ratio Combining (Ricean)');
xlabel('SNR (dB)');
ylabel('Bit Error Rate');
legend('L=1','L=2','L=3','L=4');

figure;
plot(SNR, Pe_egc(:,:,2), '-*');
set(gca,'YScale','log');
title('BER of Equal Gain Combining (Ricean)');
xlabel('SNR (dB)');
ylabel('Bit Error Rate');
legend('L=1','L=2','L=3','L=4');

%% -------- Comparison (Rayleigh) --------

figure;
plot(SNR, Pe_sc(:,4,1), '-+', ...
     SNR, Pe_egc(:,4,1), '-*', ...
     SNR, Pe_mrc(:,4,1), '-o');

set(gca,'YScale','log');
title('BER Comparison (Rayleigh)');
xlabel('SNR (dB)');
ylabel('Bit Error Rate');
legend('Selective Combining', ...
       'Equal Gain Combining', ...
       'Maximal Ratio Combining');

%% -------- Comparison (Ricean) --------

figure;
plot(SNR, Pe_sc(:,4,2), '-+', ...
     SNR, Pe_egc(:,4,2), '-*', ...
     SNR, Pe_mrc(:,4,2), '-o');

set(gca,'YScale','log');
title('BER Comparison (Ricean)');
xlabel('SNR (dB)');
ylabel('Bit Error Rate');
legend('Selective Combining', ...
       'Equal Gain Combining', ...
       'Maximal Ratio Combining');

%% =======================================================================
%% Functions
%% =======================================================================

function [BER, result] = selective_combining(g, g_2, r, sample_num, data)

g_abs = abs(g);

[~, I] = max(g_abs, [], 3);

r_sc_tmp = zeros(2, sample_num);
g_sc = zeros(2, sample_num);

for i = 1:sample_num
    r_sc_tmp(:,i) = r(:,i,I(i));
    g_sc(:,i) = g_2(:,i,I(i));
end

r_sc = real(exp(-1i*angle(g_sc)) .* r_sc_tmp);

result = (r_sc > 0)*2 - 1;

BER = get_BER(result, data, sample_num);

end

%% -----------------------------------------------------------------------

function [BER, result] = maximal_ratio_combining(g_2, r, sample_num, data)

r_mrc = real(sum(conj(g_2).*r, 3));

result = (r_mrc > 0)*2 - 1;

BER = get_BER(result, data, sample_num);

end

%% -----------------------------------------------------------------------

function [BER, result] = equal_gain_combining(g_2, r, sample_num, data)

r_egc = real(sum(exp(-1i*angle(g_2)).*r, 3));

result = (r_egc > 0)*2 - 1;

BER = get_BER(result, data, sample_num);

end

%% -----------------------------------------------------------------------

function Pe = get_BER(A, B, sample_num)

wrong = (A ~= B);

error_count = sum(sum(wrong));

Pe = error_count / (sample_num * 2);
end
