%OFDM Example
%Example of how to use the OFDM class to generate a signal.
%
% Author: Chance Tarver
% Website: http://www.chancetarver.com
% July 2018;

%% ------------- BEGIN CODE --------------

params.nSubcarriers = 1200;
params.subcarrier_spacing = 15e3; % 15kHz subcarrier spacing
params.constellation = 'QPSK';
params.cp_length = 144; % Number of samples in cyclic prefix.
params.nSymbols = 1;

modulator = OFDM(params);
[tx_data, tx_constellations] = modulator.use;
rx_constellations = modulator.demod(tx_data);

if norm(tx_constellations - rx_constellations) < 0.001
    disp('Success! RX Data = TX Data');
end

figure
plot(real(tx_data))
grid on
xlabel('Sample')
ylabel('Magnitude')