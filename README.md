# Spherical harmonics expansion NN for asteroids in MATLAB

## General
This code is part of my Aerospace Engineering thesis "Study of the feasibility of using neural networks for asteroid geometry expansion in spherical harmonics".
In this MATLAB code, you generate a dataset of asteroids, train a MLP or CNN neural network and get in return the graphical and numerical metrics. To create the random asteroids, it has been used the spherical harmonics of the 433 Eros asteroid obtained from the [NEAR mission](https://sbn.psi.edu/pds/resource/nearbrowse.html).

The parameters that you can change are:

- **n_asteroids**: The total number of asteroids to generate.
- **max_order**: The max order of the spherical harmonics of the i-th asteroid to generate (usually "m" in bilbiographies). 
- **length_matrix_coef**: Grade and order of the (n+1)x(n+1) matrices C and S used to calculate the radial component "r" in spherical coordinates of the asteroid geometries (must be <= max_order).
- **grid_lambda**: Number of points of the linspace used to create the longitude angle of the mesh.
- **grid_phi**: Number of points of the linspace used to create the latitude angle of the mesh.
- **frac_eros**: Fraction of the Eros like asteroids (n_asteroids/frac_eros). By introducing asteroids that are like the 433 Eros, the neural networks will be robust to stranger geometries.
- **percent**: Percent of variation of the Eros like asteroids (+- percent on the C and S coefficients).
- **factor_train**: Percent of the n_asteroids used to train.
- **frac_validation**: Number of validation asteroids used to train.
- **epochs**: Number of training epochs.
- **n_plots**: Number of random asteroids within the data_test to plot graphical metrics.
- **len**: len is the n-by-n mesh that plots the asteroids (can be different than the mesh of the train asteroids).
