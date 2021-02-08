function rx_data = transmit_with_rfweblab(real_data, imag_data, title, plot, dbm_power)
if nargin == 3
   plot = 1; 
end
tx_data = real_data + 1i*imag_data;
tx_data = transpose(tx_data);
fake_impairments.add_iq_imbalance  = 0;
fake_impairments.add_lo_leakage = 0;

board = webRF(dbm_power, fake_impairments.add_iq_imbalance, ...
    fake_impairments.add_lo_leakage);
size(tx_data)
rx_data = board.transmit(tx_data);
if plot
    plot_results('psd', title, rx_data, 200e6)
end
end
