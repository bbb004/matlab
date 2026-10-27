clear; clc; close all;

fc = 1.5e9;
c = 3e8;
lambda = c / fc;
d0 = 100;
sigma_dB = 3;

distance_m = (1:2:31).^2;

tx_gain_linear = [1, 1, 0.5];
rx_gain_linear = [1, 0.5, 0.5];
path_loss_exp  = [2, 3, 6];

num_paths = length(tx_gain_linear);
num_points = length(distance_m);

path_loss_free_space_dB = zeros(num_paths, num_points);
path_loss_log_distance_dB = zeros(num_paths, num_points);
path_loss_log_normal_dB = zeros(num_paths, num_points);

for k = 1:num_paths
    path_loss_free_space_dB(k,:) = calculate_free_space_PL(fc, distance_m, ...
                                    tx_gain_linear(k), rx_gain_linear(k));

    path_loss_log_distance_dB(k,:) = calculate_log_distance_PL(fc, distance_m, ...
                                      d0, path_loss_exp(k));

    path_loss_log_normal_dB(k,:) = calculate_log_normal_PL(fc, distance_m, ...
                                    d0, path_loss_exp(1), sigma_dB);
end

Pt_dBm = 40;
Gt_dBi = 10;
Gr_dBi = 2;
System_Losses_dB = 4;
Rx_Sensitivity_dBm = -90;

Pr_dBm = Pt_dBm + Gt_dBi + Gr_dBi - System_Losses_dB - path_loss_log_normal_dB(1,:);
Link_Margin_dB = Pr_dBm - Rx_Sensitivity_dBm;

num_samples = 100000;

rayleigh_real = randn(1, num_samples) / sqrt(2);
rayleigh_imag = randn(1, num_samples) / sqrt(2);
h_rayleigh = rayleigh_real + 1i * rayleigh_imag;
envelope_rayleigh = abs(h_rayleigh);

K_dB = 6;
K_linear = 10^(K_dB / 10);
specular_comp = sqrt(K_linear / (K_linear + 1));
diffuse_comp  = sqrt(1 / (2 * (K_linear + 1)));

rician_real = specular_comp + diffuse_comp * randn(1, num_samples);
rician_imag = diffuse_comp * randn(1, num_samples);
h_rician = rician_real + 1i * rician_imag;
envelope_rician = abs(h_rician);

figure;
semilogx(distance_m, path_loss_free_space_dB(1,:), 'b-o', 'LineWidth', 1.5); hold on;
semilogx(distance_m, path_loss_free_space_dB(2,:), 'r-^', 'LineWidth', 1.5);
semilogx(distance_m, path_loss_free_space_dB(3,:), 'g-s', 'LineWidth', 1.5);
grid on; axis([1 1000 40 110]);
title(['Free-Space Path Loss Model (f_c = ', num2str(fc/1e6), ' MHz)']);
xlabel('Distance [m]'); ylabel('Path Loss [dB]');
legend('G_t = 1.0, G_r = 1.0', 'G_t = 1.0, G_r = 0.5', 'G_t = 0.5, G_r = 0.5', 'Location', 'northwest');

figure;
semilogx(distance_m, path_loss_log_distance_dB(1,:), 'b-o', 'LineWidth', 1.5); hold on;
semilogx(distance_m, path_loss_log_distance_dB(2,:), 'r-^', 'LineWidth', 1.5);
semilogx(distance_m, path_loss_log_distance_dB(3,:), 'g-s', 'LineWidth', 1.5);
grid on; axis([1 1000 40 110]);
title(['Log-Distance Path Loss Model (f_c = ', num2str(fc/1e6), ' MHz)']);
xlabel('Distance [m]'); ylabel('Path Loss [dB]');
legend('Path Loss Exponent n = 2', 'Path Loss Exponent n = 3', 'Path Loss Exponent n = 6', 'Location', 'northwest');

figure;
subplot(2,1,1);
semilogx(distance_m, path_loss_log_normal_dB(1,:), 'r-o', 'LineWidth', 1.5); hold on;
semilogx(distance_m, path_loss_log_normal_dB(2,:), 'b-^', 'LineWidth', 1.5);
semilogx(distance_m, path_loss_log_normal_dB(3,:), 'g-s', 'LineWidth', 1.5);
grid on; axis([1 1000 40 110]);
title(['Log-Normal Shadowing Path Loss (f_c = ', num2str(fc/1e6), ' MHz, \sigma = ', num2str(sigma_dB), ' dB, n = 2)']);
xlabel('Distance [m]'); ylabel('Path Loss [dB]');
legend('Trial 1', 'Trial 2', 'Trial 3', 'Location', 'northwest');

subplot(2,1,2);
semilogx(distance_m, Pr_dBm, 'b-d', 'LineWidth', 1.5); hold on;
yline(Rx_Sensitivity_dBm, 'r--', 'Receiver Sensitivity (-90 dBm)', 'LineWidth', 1.5);
grid on;
title('Link Budget Analysis: Received Power vs Distance');
xlabel('Distance [m]'); ylabel('Received Power [dBm]');
legend('Received Power (P_r)', 'Sensitivity Threshold');

figure;
histogram(envelope_rayleigh, 100, 'Normalization', 'pdf', 'FaceColor', [0.2 0.6 0.8], 'FaceAlpha', 0.6); hold on;
histogram(envelope_rician, 100, 'Normalization', 'pdf', 'FaceColor', [0.8 0.3 0.2], 'FaceAlpha', 0.6);
grid on;
title('Small-Scale Fading Envelope Distributions');
xlabel('Signal Amplitude Envelope'); ylabel('Probability Density Function (PDF)');
legend('Rayleigh Distribution (NLOS)', ['Rician Distribution (LOS, K = ', num2str(K_dB), ' dB)']);

function PL = calculate_free_space_PL(fc, d, Gt, Gr)
    lambda = 3e8 / fc;
    tmp = lambda ./ (4 * pi * d);
    if nargin > 2
        tmp = tmp * sqrt(Gt);
    end
    if nargin > 3
        tmp = tmp * sqrt(Gr);
    end
    PL = -20 * log10(tmp);
end

function PL = calculate_log_distance_PL(fc, d, d0, n)
    lambda = 3e8 / fc;
    PL_d0 = -20 * log10(lambda / (4 * pi * d0));
    PL = PL_d0 + 10 * n * log10(d / d0);
end

function PL = calculate_log_normal_PL(fc, d, d0, n, sigma)
    lambda = 3e8 / fc;
    PL_d0 = -20 * log10(lambda / (4 * pi * d0));
    shadowing_component = sigma * randn(size(d));
    PL = PL_d0 + 10 * n * log10(d / d0) + shadowing_component;
end
