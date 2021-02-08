function out = transmit_a_signal(signal)
dbm_power = -24;
board = webRF(dbm_power, fake_impairments.add_iq_imbalance, ...
    fake_impairments.add_lo_leakage);
Fs = 200e6;   % webRF sampling rate.
out = board.transmit(signal);
end

