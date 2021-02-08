function aclr = compute_aclr_nn(signal_real, signal_imag, bw)
Fs = 200e6;

signal = signal_real + 1i * signal_imag;
channel_power = bandpower(signal, Fs, [-0.5*bw, 0.5*bw]);
adjacent_power = bandpower(signal, Fs, [-0.49*Fs, -0.5*bw]) + ...
    bandpower(signal, Fs, [0.5*bw, 0.49*Fs]);
aclr = 10*log10(adjacent_power/channel_power);
end