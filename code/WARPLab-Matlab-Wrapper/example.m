%WARPLab Matlab Wrapper Example
%Example of how to use the WARP class to start a board, send a sinusoid,
%then receive it back.
%
% Author: Chance Tarver
% Website: http://www.chancetarver.com
% July 2018; Last revision: 12-May-2004

%% ------------- BEGIN CODE --------------

% Setup params
params.nBoards = 1;         % Number of boards
params.RF_port  = 'A2B';    % Broadcast from RF A to RF B. Can also do 'B2A'

% Setup board
board = WARP(params);

% Setup TX Signal
tx_length = 2^17;
ts_tx = 1/40e6;
t = [0:ts_tx:((tx_length - 1) * ts_tx)].';   % Create time vector (Sample Frequency is ts_tx (Hz))
tx_Data = 0.6 * exp(j*2*pi * 2e6 * t);       % Create  1 MHz sinusoid

% Transmit
rx_Data = board.transmit(tx_Data);

%% Plot the input to WARP and the Output.
% Create figure
figure1 = figure;
axes1 = axes('Parent',figure1);
hold(axes1,'on');
plot(real(tx_Data), 'DisplayName', 'TxData');
hold on;
plot(real(rx_Data), 'DisplayName', 'RxData');
xlabel('Sample')
ylabel('Magnitude')
hold on;
legend(gca,'show');
grid on;
xlim(axes1,[-0 500]);
ylim(axes1,[-1 1]);



