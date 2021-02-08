function out = down_sample_nn(in_real, in_imag)
in = in_real + 1i * in_imag;
Fs = 200e6;
ofdm_rate = 15360000;
downsample_rate = floor(Fs/ofdm_rate);
out = resample(in, 1, downsample_rate);
end