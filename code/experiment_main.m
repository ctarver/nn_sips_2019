clear; clc; 
%% Inputs
dpd_params.order = 1;
dpd_params.memory_depth = 4;
dpd_params.nIterations = 2;
dpd_params.block_size = 50000;
dpd_params.use_conj = 1;
dpd_params.use_dc_term = 1;

fake_impairments.add_iq_imbalance = 0;
fake_impairments.add_lo_leakage = 0;

ofdm_params.nSubcarriers = 600;
ofdm_params.subcarrier_spacing = 15e3; % 15kHz subcarrier spacing
ofdm_params.constellation = 'QPSK';
ofdm_params.cp_length = 144; % Number of samples in cyclic prefix.
ofdm_params.nSymbols = 10;
PA_board = 'webRF';

dbm_power = -22.9;

seed = 1;
plot_spectrum = 1;

order_array = 1:2:13;

%% Run
for order = order_array
    fprintf('Starting test for %d order DPD\n', order);
    dpd_params.order = order;
    results(order) = run_exp(ofdm_params, dpd_params, PA_board, fake_impairments, seed, plot_spectrum, dbm_power);
end

%% plot results

% MSE vs DPD order
mse_w_dpds = cell2mat({results(order_array).mse_w_dpd});
mse_w_out_dpd = cell2mat({results(order_array).mse_w_out_dpd});

aclr_w_dpds = cell2mat({results(order_array).aclr_w_dpd});
aclr_w_out_dpds = cell2mat({results(order_array).aclr_w_out_dpd});

evms_w_dpd = cell2mat({results(order_array).evm_w_dpd});
evms_w_out_dpd = cell2mat({results(order_array).evm_w_out_dpd});

n_params = cell2mat({results(order_array).n_params});
n_mults = cell2mat({results(order_array).n_mults});

figure()
plot(n_mults, mse_w_dpds,'o-'); hold on;
plot(n_mults, mse_w_out_dpd, 'o-');
title('mse');

figure()
plot(n_mults, aclr_w_dpds, 'o-'); hold on;
plot(n_mults, aclr_w_out_dpds, 'o-');
title('aclr');

figure()
plot(n_mults, evms_w_dpd, 'o-'); hold on;
plot(n_mults, evms_w_out_dpd, 'o-');
title('evm');

