function results =  run_exp(ofdm_params, dpd_params, PA_board, fake_impairments, seed, plot_spectrum, dbm_power)
%% Setup Everything
if nargin == 0
    ofdm_params.nSubcarriers = 600;
    ofdm_params.subcarrier_spacing = 15e3; % 15kHz subcarrier spacing
    ofdm_params.constellation = 'QPSK';
    ofdm_params.cp_length = 144; % Number of samples in cyclic prefix.
    ofdm_params.nSymbols = 10;
    
    dpd_params.order = 9;
    dpd_params.memory_depth = 4;
    dpd_params.nIterations = 2;
    dpd_params.block_size = 50000;
    dpd_params.use_conj = 0;
    dpd_params.use_dc_term = 0;
    
    
    fake_impairments.add_iq_imbalance = 0;
    fake_impairments.add_lo_leakage = 0;
    
    PA_board = 'webRF'; % either 'WARP', 'webRF', or 'none'
    seed = 100;
    plot_spectrum = 1;
end

% Add the submodules to path
addpath(genpath('OFDM-Matlab'))
addpath(genpath('WARPLab-Matlab-Wrapper'))
addpath(genpath('Power-Amplifier-Model'))

% translate n_subcarriers to bw for aclr cal later
switch ofdm_params.nSubcarriers
    case 600
        bw = 10e6;
    case 1200
        bw = 20e6;
end

rms_input = 0.3;

% Setup the PA simulator or TX board
switch PA_board
    case 'WARP'
        warp_params.nBoards = 1;         % Number of boards
        warp_params.RF_port  = 'A2B';    % Broadcast from RF A to RF B. Can also do 'B2A'
        board = WARP(warp_params);
        Fs = 40e6;    % WARP board sampling rate.
    case 'none'
        board = PowerAmplifier(7, 4);
        Fs = 40e6;    % WARP board sampling rate.
    case 'webRF'
        %dbm_power = -25;
        board = webRF(dbm_power, fake_impairments.add_iq_imbalance, ...
            fake_impairments.add_lo_leakage);
        Fs = 200e6;   % webRF sampling rate.
end

% Setup OFDM
modulator = OFDM(ofdm_params);

% Create TX Data
rng(seed);
[original_tx_data, original_symbols] = modulator.use;
upsampled_tx_data = up_sample(original_tx_data, Fs, modulator.sampling_rate);
learning_tx_data = normalize_for_pa(upsampled_tx_data, rms_input);

% Create testing data.
rng(seed+100);
[original_tx_data, original_symbols] = modulator.use;
upsampled_tx_data = up_sample(original_tx_data, Fs, modulator.sampling_rate);
tx_data = normalize_for_pa(upsampled_tx_data, rms_input);

% Setup DPD
dpd = ILA_DPD(dpd_params);

%% Run Expierement

% Current issue. Need to investigate how my upsampling and downsampling
% shifts the signal around.
w_out_dpd = board.transmit(tx_data);
dpd.perform_learning(learning_tx_data, board);
w_dpd = board.transmit(dpd.predistort(tx_data));

%% Demodulate the RX Data to compute EVM to monitor inband performance
downsampled_w_out_dpd = down_sample(w_out_dpd, Fs, modulator.sampling_rate);
downsampled_w_dpd = down_sample(w_dpd, Fs, modulator.sampling_rate);

fd_w_out_dpd = modulator.demod(downsampled_w_out_dpd);
fd_w_out_dpd = fd_w_out_dpd * norm(original_symbols) / norm(fd_w_out_dpd);
results.evm_w_out_dpd = modulator.calculate_evm(fd_w_out_dpd, original_symbols);

fd_w_dpd = modulator.demod(downsampled_w_dpd);
fd_w_dpd = fd_w_dpd * norm(original_symbols) / norm(fd_w_dpd);
results.evm_w_dpd = modulator.calculate_evm(fd_w_dpd, original_symbols);

%% Compute and save stats
results.aclr_w_out_dpd = compute_aclr(w_out_dpd, Fs, bw);
results.aclr_w_dpd = compute_aclr(w_dpd, Fs, bw);
results.mse_w_out_dpd  = compute_mse(w_out_dpd, tx_data);
results.mse_w_dpd  = compute_mse(w_dpd, tx_data);
results.n_params = dpd.n_params;
results.n_mults = dpd.n_mults;

%% Plot
if plot_spectrum
    rms_input = 1.5;
    figure(400)
    %plot_results('psd', 'Original TX signal', tx_data, Fs)
    % Only plot w_out_dpd on 1st plot.
    if dpd.order == 1
        w_out_dpd = normalize_for_pa(w_out_dpd, rms_input);
        plot_results('psd', 'No DPD', w_out_dpd, Fs)
    end
    str = sprintf('With %dth order DPD', dpd.order);
    w_dpd = normalize_for_pa(w_dpd, rms_input);
    plot_results('psd', str, w_dpd, Fs)
end
end

%% Some helper functions
function mse = compute_mse(desired, actual)
error = actual - desired;
mse = norm(error)^2/numel(error);
end

function aclr = compute_aclr(signal, Fs, bw)
channel_power = bandpower(signal, Fs, [-0.5*bw, 0.5*bw]);
adjacent_power = bandpower(signal, Fs, [-0.49*Fs, -0.5*bw]) + ...
    bandpower(signal, Fs, [0.5*bw, 0.49*Fs]);
aclr = 10*log10(adjacent_power/channel_power);
end

function out = up_sample(in, Fs, sampling_rate)

%upsample_rate = floor(Fs/sampling_rate);
%up = upsample(in, upsample_rate);
out = resample(in, floor(Fs/sampling_rate), 1);
%b = firls(255,[0 (1/upsample_rate -0.02) (1/upsample_rate +0.02) 1],[1 1 0 0]);
%out = filter(b,1,up);
%beta = 0.25;
%upsample_span = 60;
%sps = upsample_rate;
%upsample_rrcFilter = rcosdesign(beta, upsample_span, sps);
%out = upfirdn(in, upsample_rrcFilter, upsample_rate);
end

function out = down_sample(in, current_sampling_rate, desired_sampling_rate)
downsample_rate = floor(current_sampling_rate/desired_sampling_rate);
out = resample(in, 1, downsample_rate);
end
