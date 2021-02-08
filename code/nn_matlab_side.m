ofdm_params.nSubcarriers = 600;
ofdm_params.subcarrier_spacing = 15e3; % 15kHz subcarrier spacing
ofdm_params.constellation = 'QPSK';
ofdm_params.cp_length = 144; % Number of samples in cyclic prefix.
ofdm_params.nSymbols = 10;
PA_board = 'webRF';

fake_impairments.add_iq_imbalance = 1;
fake_impairments.add_lo_leakage = 1;

seed = 1;
plot_spectrum = 1;