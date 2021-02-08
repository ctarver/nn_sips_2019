import numpy as np
from keras.layers import Dense, Activation
from keras.layers import LeakyReLU
from keras.models import Sequential


class AutoEncoder:
    """Class that holds the PA NN, the DPD-PA NN, and then the DPD NN

    TODO: Convert to functional keras where I don't have to copy layers to new NN models"""

    def __init__(self, n_neurons, n_hidden_layers, activation_function, loss_function, optimizer: str = 'adam',
                 n_epochs: int = 10):
        self.n_neurons = n_neurons
        self.n_hidden_layers = n_hidden_layers
        self.activation_function = activation_function
        self.loss_function = loss_function
        self.optimizer = optimizer
        self.n_epochs = n_epochs
        self.pa_nn_history = None
        self.dpd_nn_history = None

        # Create the NNs. We'll train later
        self.pa_nn = Sequential()  # Will store a PA only NN
        self.build_nn(self.pa_nn, trainable=True)

        self.dpd_pa_model = Sequential()  # Will store a DPD-PA NN
        self.build_nn(self.dpd_pa_model, trainable=True)  # DPD Part
        self.build_nn(self.dpd_pa_model, trainable=False)  # PA Part

        self.dpd_nn = Sequential()  # Will store a DPD only NN
        self.build_nn(self.dpd_nn, trainable=False)

    def train_model(self, pa_input, pa_output):
        """Train a Neural Network to model the PA
        TODO: Add scaling to input output to help NN
        """
        # Split the real and imag parts of input output
        x_train = np.transpose(np.stack((pa_input.real, pa_input.imag)))
        y_train = np.transpose(np.stack((pa_output.real, pa_output.imag)))

        # Train!
        self.pa_nn.compile(loss=self.loss_function, optimizer=self.optimizer)

        self.pa_nn_history = self.pa_nn.fit(x_train, y_train, epochs=self.n_epochs,
                                               batch_size=32, validation_split=0.2)

        # Train DPD-PA Combo Net
        x_train = np.transpose(np.stack((pa_input.real, pa_input.imag)))
        y_train = np.transpose(np.stack((pa_input.real, pa_input.imag)))

        # Copy weights from PA NN over
        for index, layer in enumerate(reversed(self.pa_nn.layers)):
            if layer.__class__.__name__ is 'Dense':
                # TODO: Error check. Make sure that I'm copying into a Dense.
                self.dpd_pa_model.layers[-(index + 1)].set_weights(layer.get_weights())

        # Train!
        self.dpd_pa_model.compile(loss=self.loss_function, optimizer=self.optimizer)

        self.dpd_nn_history = self.dpd_pa_model.fit(x_train, y_train, epochs=self.n_epochs,
                                                    batch_size=32, validation_split=0.2)

        # Copy DPD part to its own NN
        for index, layer in enumerate(self.dpd_nn.layers):
            if layer.__class__.__name__ is 'Dense':
                # TODO: Error check. Make sure that I'm copying into a Dense.
                layer.set_weights(self.dpd_pa_model.layers[index].get_weights())

    def build_nn(self, model, trainable: bool):
        """Build the structure of the NN for the PA modeling. This is split off because it needs to be done 2x. 1st
        for modeling the PA, then again for the DPD"
        """
        # Hidden Layers
        model.add(Dense(units=self.n_neurons, input_dim=2, trainable=trainable))
        self.add_activation(model)
        for _ in range(self.n_hidden_layers - 1):
            model.add(Dense(units=self.n_neurons, trainable=trainable))
            self.add_activation(model)
        # Output Layer
        model.add(Dense(units=2, trainable=trainable))

    def add_activation(self, model):
        if self.activation_function is 'l_relu':
            model.add(LeakyReLU())
        else:
            model.add(Activation(self.activation_function))

    def use_dpd(self, pa_input):
        nn_input = np.transpose(np.stack((pa_input.real, pa_input.imag)))
        nn_output = self.dpd_nn.predict(nn_input)
        # Unpack the output to complex data
        nn_pa_output = 1j * nn_output[..., 1]
        nn_pa_output += nn_output[..., 0]
        return nn_pa_output

    def use_pa_model(self, pa_input):
        nn_input = np.transpose(np.stack((pa_input.real, pa_input.imag)))
        nn_output = self.pa_nn.predict(nn_input)

        # Unpack the output to complex data
        nn_pa_output = 1j * nn_output[..., 1]
        nn_pa_output += nn_output[..., 0]

        return nn_pa_output
