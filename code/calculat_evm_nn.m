function evm_w_dpd = calculat_evm_nn(w_out_dpd_real, w_out_dpd_imag, w_dpd_real, w_dpd_imag, original_symbols_real, original_symbols_imag)

Fs = 200e6;

%% Rebuild the modulator
ofdm_params.nSubcarriers = 600;
ofdm_params.subcarrier_spacing = 15e3; % 15kHz subcarrier spacing
ofdm_params.constellation = 'QPSK';
ofdm_params.cp_length = 144; % Number of samples in cyclic prefix.
ofdm_params.nSymbols = 10;

fake_impairments.add_iq_imbalance = 0;
fake_impairments.add_lo_leakage = 0;

addpath(genpath('OFDM-Matlab'))
modulator = OFDM(ofdm_params);

%% Demodulate the RX Data to compute EVM to monitor inband performance
w_out_dpd = w_out_dpd_real + 1i * w_out_dpd_imag;
w_dpd = w_dpd_real + 1i * w_dpd_imag;
original_symbols = original_symbols_real + 1i * original_symbols_imag;

% Downsample both.
downsampled_w_out_dpd = down_sample(w_out_dpd);
downsampled_w_dpd = down_sample(w_dpd);

fd_w_out_dpd = modulator.demod(downsampled_w_out_dpd);
fd_w_out_dpd = fd_w_out_dpd * norm(original_symbols) / norm(fd_w_out_dpd);
evm_w_out_dpd = modulator.calculate_evm(fd_w_out_dpd, original_symbols)

fd_w_dpd = modulator.demod(downsampled_w_dpd);
fd_w_dpd = fd_w_dpd * norm(original_symbols) / norm(fd_w_dpd);
evm_w_dpd = modulator.calculate_evm(fd_w_dpd, original_symbols)


end

function out = down_sample(in)
current_sampling_rate = 200e6;
desired_sampling_rate = 15360000;
downsample_rate = floor(current_sampling_rate/desired_sampling_rate);
out = resample(in, 1, downsample_rate);
end


