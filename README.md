# SIPS_2019
This repo contains the main code used to produce the results in https://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=9020606

I originally intended to clean up this code. It became a mess with deadlines, and I have been unable to find much time to revisit it.

All code is provided "as is" with no support.

## Notes
I have not tried to rerun the code. However, there are a few observations I can make to try to illuminate what Chance from 2018 might have been doing

* Set up a python virtual environment for this project. I created a requirements.txt in the code directory for setting up the correct pip. 
* Set up the python/matlab interface. I made a guide on this here: https://www.chancetarver.com/post/python-and-matlab/
* The main experiement is the "nn_exp_main.py." This will call many of the other files. I think I likely had some experiements starting from other files, but this seems to be the main one that launched the NN training.
* The main file of the code is "linear_nn.py." This handles the NN training for the DPD and PA NNs.


