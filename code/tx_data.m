function rx_data = transimt_with_rfweblab(real_data, imag_data)
tx_data = real_data + 1i*imag_data;
fake_impairments.add_iq_imbalance  = 0;
fake_impairments.add_lo_leakage = 0;
dbm_power = -24;
board = webRF(dbm_power, fake_impairments.add_iq_imbalance, ...
    fake_impairments.add_lo_leakage);
rx_data = board.transmit(tx_data);
end
