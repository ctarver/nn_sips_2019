function [original_tx_data, original_symbols, tx_data, w_out_dpd, learning_tx_data] = create_the_signal(bw, plot, dbm_power)

if nargin == 0
    bw = 10e6;
    plot = 1;
end

switch bw
    case 10e6
        ofdm_params.nSubcarriers = 600;
    case 20e6
        ofdm_params.nSubcarriers = 1200;
end

ofdm_params.subcarrier_spacing = 15e3; % 15kHz subcarrier spacing
ofdm_params.constellation = 'QPSK';
ofdm_params.cp_length = 144; % Number of samples in cyclic prefix.
ofdm_params.nSymbols = 10;

fake_impairments.add_iq_imbalance = 0;
fake_impairments.add_lo_leakage = 0;

Fs = 200e6;   % webRF sampling rate.

% Setup OFDM
addpath(genpath('OFDM-Matlab'))
modulator = OFDM(ofdm_params);

rms_input = 1.5;  % This value gives a good std for neural net training

% Create learning Data
seed = 1;
rng(seed);
[original_tx_data, original_symbols] = modulator.use;
upsampled_tx_data = up_sample(original_tx_data, Fs, modulator.sampling_rate);
learning_tx_data = normalize_for_pa(upsampled_tx_data, rms_input);

board = webRF(dbm_power, fake_impairments.add_iq_imbalance, ...
    fake_impairments.add_lo_leakage);
w_out_dpd = board.transmit(learning_tx_data);

% Stats for NN learning info:
mean(real(learning_tx_data))
mean(imag(learning_tx_data))
std(real(learning_tx_data))
std(imag(learning_tx_data))

% Create testing data.
rng(seed+100);
[original_tx_data, original_symbols] = modulator.use;
upsampled_tx_data = up_sample(original_tx_data, Fs, modulator.sampling_rate);
tx_data = normalize_for_pa(upsampled_tx_data, rms_input);

mean(real(w_out_dpd))
mean(imag(w_out_dpd))
std(real(w_out_dpd))
std(imag(w_out_dpd))

if plot
    plot_results('psd', 'NN Test. No DPD', w_out_dpd, Fs);
end
end

function out = up_sample(in, Fs, sampling_rate)
out = resample(in, floor(Fs/sampling_rate), 1);
end