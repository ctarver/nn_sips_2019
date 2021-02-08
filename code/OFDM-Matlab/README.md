# OFDM for Matlab

This is an OFDM class for MATLAB. This class allows the user to generate OFDM signals with various subcarrier spacings, cyclic prefix lengths, and number of symbols.

### How to install this: 
#### Option 1: Add OFDM.m to the path:
Download this repo. Put the OFDM.m in the folder of your project or in any folder that is in the Matlab path. Then proceed to use the class to use the provided PA model or train a new model. 

#### Option 2: Add as a submodule in your git project:
If you already are using git with your project, you can use this as a submodule. In the main directory of your project, run
```
git submodule add https://github.com/ctarver/OFDM-Matlab.git
git submodule update --init --recursive
```
This repo should show up in your project. Then just commit the new submodule to your project like you would commit anything. 
To use the class, you still need to add the OFDM.m to your Matlab path.
```addpath(genpath(OFDM-Matlab))```

### How to use the OFDM class:
Initialize with:
`modulator = OFDM(params);`

The inputs params is a struct with the following properties:
  - nSubcarriers
  - subcarrier_spacing
  - constellation
  - cp_length
  - nSymbols
  
To modulate data according to the parameters, simply use the `use` method, `[tx_data, tx_constellations] = modulator.use;`. 

To demodulate data according to the parameters, simply use the `demod` method, `rx_constellations = modulator.demod(tx_data);`.

 ### Todo:
 - Add option to provide data instead of doing random data. 
 - Have the demodulator also demod the constellation on each subcarrier. 

Checkout the example.m to see more.             
