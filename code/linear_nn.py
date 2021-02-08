import numpy as np
from keras.layers import Dense
from keras.layers import concatenate
from keras.layers import Input
from keras.models import Model
from keras.utils.vis_utils import plot_model
import matplotlib.pyplot as plt
from keras.callbacks import TensorBoard

n_neruons_pa = 80
n_layers_pa = 2

class AutoEncoder:
    # TODO: Change to 32 bit float or lower precision.
    def __init__(self, n_neurons: int = 10, n_hidden_layers: int = 1,
                 activation_function: str = 'relu', loss_function: str = 'mse', optimizer: str = 'adam',
                 n_epochs: int = 10):
        self.n_neurons = n_neurons
        self.n_hidden_layers = n_hidden_layers
        self.activation_function = activation_function
        self.loss_function = loss_function
        self.optimizer = optimizer
        self.n_epochs = n_epochs
        self.pa_nn_history = None
        self.dpd_nn = None
        self.dpd_nn_history = None

        """ CREATE THE NN FOR THE PA-----------------------------------------"""
        # Input Layer expects time steps of 2 features
        pa_input = Input(shape=(2, ))
        if n_layers_pa == 1:
            hidden = Dense(n_neruons_pa, activation=self.activation_function)(pa_input)
            merge = concatenate([pa_input, hidden])
            index_linear_bypass_layer_pa = 2
        elif n_layers_pa == 2:
            hidden_1 = Dense(n_neruons_pa, activation=self.activation_function)(pa_input)
            hidden_2 = Dense(n_neruons_pa, activation=self.activation_function)(hidden_1)
            merge = concatenate([pa_input, hidden_2])
            index_linear_bypass_layer_pa = 4
        output = Dense(2, activation='linear')(merge)
        self.pa_nn = Model(inputs=pa_input, outputs=output)
        # summarize layers
        print(self.pa_nn.summary())
        # plot graph plot_model(self.pa_nn, to_file='recurrent_neural_network.png')

        self.pa_nn.compile(optimizer=self.optimizer, loss=self.loss_function)
        weights = self.pa_nn.get_weights()
        weights[index_linear_bypass_layer_pa][0, 0] = 1
        weights[index_linear_bypass_layer_pa][0, 1] = 0
        weights[index_linear_bypass_layer_pa][1, 0] = 0
        weights[index_linear_bypass_layer_pa][1, 1] = 1
        self.pa_nn.set_weights(weights)
        print('PA Weights:')
        print(self.pa_nn.get_weights())

        """CREATE A DPD MODEL ----------------------------------------------------------------"""
        dpd_input = Input(shape=(2, ))
        if self.n_hidden_layers == 1:
            dpd_dense = Dense(self.n_neurons, activation=self.activation_function)(dpd_input)
            dpd_merge = concatenate([dpd_input, dpd_dense])
            index_linear_bypass_layer = 2
        elif self.n_hidden_layers == 2:
            dpd_dense_1 = Dense(self.n_neurons, activation=self.activation_function)(dpd_input)
            dpd_dense_2 = Dense(self.n_neurons, activation=self.activation_function)(dpd_dense_1)
            dpd_merge = concatenate([dpd_input, dpd_dense_2])
            index_linear_bypass_layer = 4
        dpd_output = Dense(2, activation='linear')(dpd_merge)
        self.dpd_nn = Model(inputs=dpd_input, outputs=dpd_output)
        weights = self.dpd_nn.get_weights()
        weights[index_linear_bypass_layer][0, 0] = 1
        weights[index_linear_bypass_layer][0, 1] = 0
        weights[index_linear_bypass_layer][1, 0] = 0
        weights[index_linear_bypass_layer][1, 1] = 1
        self.dpd_nn.set_weights(weights)
        print('DPD Weights:')
        print(self.dpd_nn.get_weights())
        # summarize layers print(dpd.summary())
        # plot graph plot_model(dpd, to_file='dpd_recurrent_neural_network.png')

    def train_model(self, pa_input, pa_output):
        """Train the PA DPD"""
        # Reshape the training data.

        tbCallBack = TensorBoard(log_dir='./Graph', histogram_freq=0, write_graph=True, write_images=True)

        x_train = np.transpose(np.stack((pa_input.real, pa_input.imag)))
        y_train = np.transpose(np.stack((pa_output.real, pa_output.imag)))

        #n_timesteps, n_features = x_train.shape

        #x_train = x_train.reshape((1, n_timesteps, n_features))
        #y_train = y_train.reshape((1, n_timesteps, n_features))

        self.pa_nn_history = self.pa_nn.fit(x=x_train, y=y_train, epochs=self.n_epochs, callbacks=[tbCallBack])

        # Freeze these PA Weights
        self.pa_nn.trainable = False
        self.pa_nn.compile(optimizer=self.optimizer, loss=self.loss_function)

        """REUSE THOSE LAYERS TO CREATE A DPD-PA NN-------------------------------------------"""
        dpd_pa_input = Input(shape=(2, ))
        dpd_out = self.dpd_nn(dpd_pa_input)
        pa_out = self.pa_nn(dpd_out)
        dpd_pa_model = Model(inputs=dpd_pa_input, outputs=pa_out)
        dpd_pa_model.compile(optimizer=self.optimizer, loss=self.loss_function)
        self.dpd_nn_history = dpd_pa_model.fit(x=x_train, y=x_train, epochs=self.n_epochs)

        # UnFreeze the PA Weights to allow for retraining.
        self.pa_nn.trainable = True
        self.pa_nn.compile(optimizer=self.optimizer, loss=self.loss_function)

        # Plot training & validation loss values
        plt.plot(self.pa_nn_history.history['loss'])
        plt.title('Model loss')
        plt.ylabel('Loss')
        plt.xlabel('Epoch')
        plt.show()
        print('PA NN Weights:')
        print(self.pa_nn.get_weights())

        print('DPD NN Weights:')
        print(self.dpd_nn.get_weights())

    def use_dpd(self, x):
        x_predict = np.transpose(np.stack((x.real, x.imag)))
        # n_timesteps, n_features = x_predict.shape
        # x_predict = x_predict.reshape((1, n_timesteps, n_features))
        nn_output = self.dpd_nn.predict(x_predict)
        nn_pa_output = 1j * nn_output[..., 1]
        nn_pa_output += nn_output[..., 0]
        return nn_pa_output.flatten()

    def add_training_data(self, pa_input, pa_output):
        """TODO: Future Method for adding different examples to training data. Add examples along time axis"""
        pass


if __name__ == '__main__':
    from cli import Data
    from phypy import modulators
    from rfweblab import RFWebLab

    # Make some containers for data:
    tx_data = Data()
    rx_data = Data()

    # Build the OFDM modulator and the signal
    ofdm = modulators.OFDM(n_subcarriers=600)
    tx_data.original = ofdm.use(n_symbols=2)

    # Set up the RFWebLab PA
    board = RFWebLab()
    # Upsample the data to the proper sampling rate for the board
    tx_data.upsampled = board.up_sample(tx_data.original, ofdm.sampling_rate)
    tx_data.pre_pa = board.normalize_signal_for_pa(tx_data.upsampled)

    # Transmit the data without DPD
    rx_data.post_pa = board.transmit(tx_data.pre_pa)

    nnpa = NeuralNetPA(tx_data.pre_pa, rx_data.post_pa)
