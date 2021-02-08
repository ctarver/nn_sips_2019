# Get data from matlab
import matlab.engine
import numpy as np
import matplotlib.pyplot as plt

eng = matlab.engine.start_matlab()  # Launch the matlab engine.
dbm_power = -22.9

def main():
    bw = 10e6

    n_neurons = 30
    n_hidden_layers = 1
    activation_function ='relu'
    loss_function = 'mse'
    n_epochs = 50
    n_iterations = 2

    tx_data = Data()
    rx_data = Data()
    # [   a            , b               , c       , d       , e]
    # [original_tx_data, original_symbols, tx_data, w_out_dpd, learning_tx_data]
    # [testing         , testing         , testing, learning , learning
    a, b, c, d, e = np.asarray(eng.create_the_signal(bw, 0, dbm_power, nargout=5))
    tx_data.original = np.squeeze(np.asarray(a))
    tx_data.orginal_fd_symbols = np.squeeze(np.asarray(b))
    tx_data.testing_pre_pa = np.squeeze(np.asarray(c))
    rx_data.post_pa = np.squeeze(np.asarray(d))
    tx_data.pre_pa = np.squeeze(np.asarray(e))

    if bw is 10e6:
        ofdm_sampling_rate = 15360000  # I just stole this from MATLAB.
    elif bw is 20e6:
        ofdm_sampling_rate = 30720000

    # Use NN DPD
    tx_data, rx_data, nn = train_pa_and_dpd_nn(tx_data, rx_data, ofdm_sampling_rate,
                                               n_neurons, n_hidden_layers, activation_function,
                                               loss_function, n_epochs, n_iterations)

    # Use the testing data to compute stats
    real_data = matlab.double(rx_data.nn_testing_data.real.tolist())
    imag_data = matlab.double(rx_data.nn_testing_data.imag.tolist())
    aclr = eng.compute_aclr_nn(real_data, imag_data, bw)
    print(f' ACLR = {aclr}')

    n_mults = compute_n_mults(n_neurons, n_hidden_layers)
    print(f' n_mults = {n_mults}')

    a = matlab.double(rx_data.testing_data_no_dpd.real.tolist())  # without DPD testing data
    b = matlab.double(rx_data.testing_data_no_dpd.imag.tolist())
    c = matlab.double(rx_data.nn_testing_data.real.tolist())    # with DPD testing data
    d = matlab.double(rx_data.nn_testing_data.imag.tolist())
    e = matlab.double(tx_data.orginal_fd_symbols.real.tolist())  # testing data fd symbols
    f = matlab.double(tx_data.orginal_fd_symbols.imag.tolist())
    evm = eng.calculat_evm_nn(a, b, c, d, e, f)


def train_pa_and_dpd_nn(tx_data, rx_data, fs, n_neurons, n_hidden_layers, activation_function,
                        loss_function, n_epochs, n_iterations):

    from linear_nn import AutoEncoder

    # Setup the PA NN model
    nn_pa = AutoEncoder(n_neurons=n_neurons,
                        n_hidden_layers=n_hidden_layers,
                        activation_function=activation_function,
                        loss_function=loss_function,
                        n_epochs=n_epochs)

    # For making it possible to do multiple iterations, we'll pretend we put it through a DPD that did nothing
    tx_data.w_dpd = tx_data.pre_pa
    rx_data.w_dpd = rx_data.post_pa

    for _ in range(n_iterations):
        nn_pa.train_model(tx_data.w_dpd, rx_data.w_dpd)

        # Predistort Data and transmit
        tx_data.w_dpd = nn_pa.use_dpd(tx_data.pre_pa)
        real_data = matlab.double(tx_data.w_dpd.real.tolist())
        imag_data = matlab.double(tx_data.w_dpd.imag.tolist())
        a = np.asarray(eng.transmit_with_rfweblab(real_data, imag_data, 'With NN DPD training ', 1, dbm_power))
        rx_data.w_dpd = np.squeeze(np.asarray(a))
        nn_pa.n_epochs = 40

    #a = matlab.double(rx_data.w_dpd.real.tolist())
    #b = matlab.double(rx_data.w_dpd.imag.tolist())
    #rx_data.original_w_dpd = np.asarray(eng.down_sample_nn(a, b))

    # Try on testing data
    predisorted_testing_data = nn_pa.use_dpd(tx_data.testing_pre_pa)
    real_data = matlab.double(predisorted_testing_data.real.tolist())
    imag_data = matlab.double(predisorted_testing_data.imag.tolist())
    rx_data.nn_testing_data = np.asarray(eng.transmit_with_rfweblab(real_data, imag_data,
                                                                    'NN Testing Data With DPD', 1, dbm_power))

    # testing data no DPD
    real_data = matlab.double(tx_data.testing_pre_pa.real.tolist())
    imag_data = matlab.double(tx_data.testing_pre_pa.imag.tolist())
    rx_data.testing_data_no_dpd = np.asarray(eng.transmit_with_rfweblab(real_data, imag_data,
                                                                        'NN Testing Data No DPD', 1, dbm_power))
    return tx_data, rx_data, nn_pa


class Data:
    """Dummy class to contain data at various stages

    tx_data: original --> upsampled --> pre_pa
    rx_data: post_pa --> downsampled --> original
    """


def compute_n_mults(n_neurons, n_hidden):
    # calculate for input output layer
    n_mults = 2 * (2 * n_neurons)

    # add in hidden layers
    for i in range(n_hidden-1):
        n_mults = n_mults + n_neurons*n_neurons

    return n_mults


if __name__ == '__main__':
    main()