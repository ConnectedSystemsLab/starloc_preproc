import numpy as np
from numba import njit, objmode

@njit(cache=True)
def get_mean(x, axis=0):
    return np.sum(x, axis=axis)/x.shape[axis]

@njit(cache=True)
def cov_matrix(x):
    """ Calculates the spatial covariance matrix (Rxx) for a given set of input data (x=inputData).
        Assumes rows denote Vrx axis.

    Args:
        x (ndarray): A 2D-Array with shape (rx, adc_samples) slice of the output of the 1D range fft

    Returns:
        Rxx (ndarray): A 2D-Array with shape (rx, rx)
    """

    #if x.ndim > 2:
    #    raise ValueError("x has more than 2 dimensions.")

    #if x.shape[0] > x.shape[1]:
    #    warnings.warn("cov_matrix input should have Vrx as rows. Needs to be transposed", RuntimeWarning)
    #    x = x.T

    _, num_adc_samples = x.shape
    x_T = x.T
    Rxx = x @ np.conjugate(x_T)
    Rxx = np.divide(Rxx, num_adc_samples)

    return Rxx

@njit(cache=True)
def forward_backward_avg(Rxx):
    """ Performs forward backward averaging on the given input square matrix

    Args:
        Rxx (ndarray): A 2D-Array square matrix containing the covariance matrix for the given input data

    Returns:
        R_fb (ndarray): The 2D-Array square matrix containing the forward backward averaged covariance matrix
    """
    #assert np.size(Rxx, 0) == np.size(Rxx, 1)

    # --> Calculation
    #M = np.size(Rxx, 0)  # Find number of antenna elements
    M = Rxx.shape[0]
    #Rxx = np.matrix(Rxx)  # Cast np.ndarray as a np.matrix

    # Create exchange matrix
    J = np.eye(M)  # Generates an identity matrix with row/col size M
    J = np.fliplr(J)  # Flips the identity matrix left right
    #J = np.matrix(J)  # Cast np.ndarray as a np.matrix

    R_fb = 0.5 * (Rxx + J * np.conjugate(Rxx) * J)

    return R_fb

@njit(cache=True)
def gen_steering_vec(ang_est_range, ang_est_resolution, num_ant):
    """Generate a steering vector for AOA estimation given the theta range, theta resolution, and number of antennas

    Defines a method for generating steering vector data input --Python optimized Matrix format
    The generated steering vector will span from -angEstRange to angEstRange with increments of ang_est_resolution
    The generated steering vector should be used for all further AOA estimations (bartlett/capon)

    Args:
        ang_est_range (int): The desired span of thetas for the angle spectrum.
        ang_est_resolution (float): The desired resolution in terms of theta
        num_ant (int): The number of Vrx antenna signals captured in the RDC

    Returns:
        num_vec (int): Number of vectors generated (integer divide angEstRange/ang_est_resolution)
        steering_vectors (ndarray): The generated 2D-array steering vector of size (num_vec,num_ant)

    Example:
        >>> #This will generate a numpy array containing the steering vector with 
        >>> #angular span from -90 to 90 in increments of 1 degree for a 4 Vrx platform
        >>> _, steering_vec = gen_steering_vec(90,1,4)

    """
    num_vec = ((2 * ang_est_range+1) / ang_est_resolution + 1)
    num_vec = int(round(num_vec))
    steering_vectors = np.zeros((num_vec, num_ant), dtype='complex64')
    for kk in range(num_vec):
        for jj in range(num_ant):
            mag = -1 * np.pi * jj * np.sin((-ang_est_range - 1 + kk * ang_est_resolution) * np.pi / 180)
            real = np.cos(mag)
            imag = np.sin(mag)

            steering_vectors[kk, jj] = np.complex(real, imag)

    return (num_vec, steering_vectors)

@njit(cache=True)
def aoa_bartlett(steering_vec, sig_in, axis):
    """Perform AOA estimation using Bartlett Beamforming on a given input signal (sig_in). Make sure to specify the correct axis in (axis)
    to ensure correct matrix multiplication. The power spectrum is calculated using the following equation:

    .. math::
        P_{ca} (\\theta) = a^{H}(\\theta) R_{xx}^{-1} a(\\theta)

    This steers the beam using the steering vector as weights:

    .. math::
        w_{ca} (\\theta) = a(\\theta)

    Args:
        steering_vec (ndarray): A 2D-array of size (numTheta, num_ant) generated from gen_steering_vec
        sig_in (ndarray): Either a 2D-array or 3D-array of size (num_ant, numChirps) or (numChirps, num_vrx, num_adc_samples) respectively, containing ADC sample data sliced as described
        axis (int): Specifies the axis where the Vrx data in contained.

    Returns:
        doa_spectrum (ndarray): A 3D-array of size (numChirps, numThetas, numSamples)

    Example:
        >>> # In this example, dataIn is the input data organized as numFrames by RDC
        >>> frame = 0
        >>> dataIn = np.random.rand((num_frames, num_chirps, num_vrx, num_adc_samples))
        >>> aoa_bartlett(steering_vec,dataIn[frame],axis=1)
    """
    n_theta = steering_vec.shape[0]
    n_rx = sig_in.shape[1]
    n_range = sig_in.shape[2]
    y = np.zeros((sig_in.shape[0], n_theta, n_range), dtype='complex64')
    for i in range(sig_in.shape[0]):
        y[i] = np.conjugate(steering_vec) @ sig_in[i]
    # y = np.conjugate(steering_vec) @ sig_in
    return y 

@njit(cache=True)
def aoa_capon(x, steering_vector):
    """Perform AOA estimation using Capon (MVDR) Beamforming on a rx by chirp slice

    Calculate the aoa spectrum via capon beamforming method using one full frame as input.
    This should be performed for each range bin to achieve AOA estimation for a full frame
    This function will calculate both the angle spectrum and corresponding Capon weights using
    the equations prescribed below.

    .. math::
        P_{ca} (\\theta) = \\frac{1}{a^{H}(\\theta) R_{xx}^{-1} a(\\theta)}

        w_{ca} (\\theta) = \\frac{R_{xx}^{-1} a(\\theta)}{a^{H}(\\theta) R_{xx}^{-1} a(\\theta)}

    Args:
        x (ndarray): Output of the 1d range fft with shape (num_ant, numChirps)
        steering_vector (ndarray): A 2D-array of size (numTheta, num_ant) generated from gen_steering_vec
        magnitude (bool): Azimuth theta bins should return complex data (False) or magnitude data (True). Default=False

    Raises:
        ValueError: steering_vector and or x are not the correct shape

    Returns:
        A list containing numVec and steeringVectors
        den (ndarray: A 1D-Array of size (numTheta) containing azimuth angle estimations for the given range
        weights (ndarray): A 1D-Array of size (num_ant) containing the Capon weights for the given input data

    Example:
        >>> # In this example, dataIn is the input data organized as numFrames by RDC
        >>> Frame = 0
        >>> dataIn = np.random.rand((num_frames, num_chirps, num_vrx, num_adc_samples))
        >>> for i in range(256):
        >>>     scan_aoa_capon[i,:], _ = dss.aoa_capon(dataIn[Frame,:,:,i].T, steering_vector, magnitude=True)

    """

    #if steering_vector.shape[1] != x.shape[0]:
    #    raise ValueError("'steering_vector' with shape (%d,%d) cannot matrix multiply 'input_data' with shape (%d,%d)" \
    #    % (steering_vector.shape[0], steering_vector.shape[1], x.shape[0], x.shape[1]))

    Rxx = cov_matrix(x)
    # Rxx = forward_backward_avg(Rxx)
    Rxx_inv = np.linalg.inv(Rxx).astype(np.complex64)
    # Calculate Covariance Matrix Rxx
    first = Rxx_inv @ steering_vector.T
    #den = np.reciprocal(np.einsum('ij,ij->i', steering_vector.conj(), first.T))
    den = np.zeros(first.shape[1], dtype=np.complex64)
    steering_vector_conj = steering_vector.conj()
    first_T = first.T
    for i in range(first_T.shape[0]):
        for j in range(first_T.shape[1]):
            den[i] += steering_vector_conj[i,j] * first_T[i,j]
    den = np.reciprocal(den)

    #weights = np.matmul(first, den)
    weights = first @ den

    #if magnitude:
    #    return np.abs(den), weights
    #else:
    #    return den, weights
    return den, weights

@njit(cache=True)
def aoa_apes(x, steering_vector):
    steering_vector_ = steering_vector
    num_sample = x.shape[1]
    num_ante = x.shape[0]
    num_angle = steering_vector_.shape[0]

    Rxx = cov_matrix(x)
    g_theta = np.zeros_like(steering_vector) # angle * antenna
    for idx in range(num_angle):
        g_theta[idx,:] = np.sum(steering_vector_[idx] * x.T, axis=0) / num_sample
    Q_theta = np.zeros((num_angle, num_ante, num_ante), dtype=np.complex64)
    Q_theta_inv = np.zeros((num_angle, num_ante, num_ante), dtype=np.complex64)
    for idx in range(num_angle):
        Q_theta[idx] = Rxx - np.reshape(g_theta[idx],(-1,1)) @ np.reshape(g_theta[idx].conj(),(1,-1))
        Q_theta_inv[idx] = np.linalg.inv(Q_theta[idx])
    den = np.zeros(num_angle, dtype=np.complex64)
    for idx in range(num_angle):
        den[idx] = (steering_vector_[idx].conj() @ Q_theta_inv[idx] @ g_theta[idx]) / \
                   (steering_vector_[idx].conj() @ Q_theta_inv[idx] @ steering_vector_[idx])
    return den

@njit(cache=True)
def aoa_aic_num(x):
    x_ = x
    num_ante = x_.shape[0]
    num_sample = x_.shape[1]
    Rxx = cov_matrix(x)
    eig_va, eig_ve = np.linalg.eigh(Rxx)
    eigs = np.sort(eig_va)[::-1]
    AIC = np.zeros(num_ante)
    for k in range(num_ante):
        AIC[k] = -2*(num_ante-k)*num_sample*(np.sum(np.log(eigs)[k:])/(num_ante - k) -
                                             np.log(np.sum(eigs[k:])/(num_ante - k))) + 2*k*(2*num_ante-k)
    ans = np.argmin(AIC)
    return ans

@njit(cache=True)
def aoa_mdl_num(x):
    x_ = x
    num_ante = x_.shape[0]
    num_sample = x_.shape[1]
    Rxx = cov_matrix(x)
    eig_va, eig_ve = np.linalg.eigh(Rxx)
    eigs = np.sort(eig_va)[::-1]
    MDL = np.zeros(num_ante)
    for k in range(num_ante):
        MDL[k] = -(num_ante - k)*num_sample*(np.sum(np.log(eigs)[k:])/(num_ante - k) -
                                             np.log(np.sum(eigs[k:])/(num_ante - k))) + 0.5*k*(2*num_ante - k)*np.log(num_sample)
    ans = np.argmin(MDL)
    return ans

@njit(cache=True)
def aoa_music(x, steering_vector):
    x_ = x
    steering_vector_ = steering_vector
    num_sample = x_.shape[1]
    num_ante = x_.shape[0]
    num_angle = steering_vector_.shape[0]

    Rxx = cov_matrix(x)
    num_sig = aoa_aic_num(x_)
    eig_va, eig_ve = np.linalg.eigh(Rxx)
    eigs_ve_sort = np.argsort(eig_va)[::-1]
    G = np.zeros((num_ante, num_ante - num_sig), dtype=np.complex64)
    for i in range(num_ante - num_sig):
        G[:,i] = eig_ve[:,eigs_ve_sort[num_sig+i]]
    music_spec = np.zeros(num_angle, dtype=np.complex64)
    for i in range(num_angle):
        music_spec[i] = steering_vector_[i].conj() @ G @ G.conj().T @ steering_vector_[i]
    music_spec = np.reciprocal(music_spec)
    return music_spec

@njit(cache=True)
def aoa_music_2d(x, M_x, M_y, d, lam):
    x_ = x
    num_sample = x_.shape[1]
    num_ante = x_.shape[0]
    num_sig = 1
    M = M_x*M_y
    S = x_ @ np.conjugate(x_.T)/num_sample
    eig_va, eig_ve = np.linalg.eigh(S)
    eigs_ve_sort = np.argsort(eig_va)[::-1]
    E_N = np.zeros((num_ante, num_ante - num_sig), dtype=np.complex64)
    for i in range(num_ante - num_sig):
        E_N[:,i] = eig_ve[:,eigs_ve_sort[num_sig+i]]
    theta_hat = np.arange(0, 90, 0.5)
    phi_hat = np.arange(0, 360, 1)
    music_spec = np.zeros((len(theta_hat), len(phi_hat)), dtype=np.complex64)
    for i in range(len(theta_hat)):
        for j in range(len(phi_hat)):
            theta_ = theta_hat[i]
            phi_ = phi_hat[j]
        
            a_x = np.exp(-1j*2*np.pi*d/lam*np.arange(0, M_x, 1)*np.cos(np.deg2rad(theta_)*np.cos(np.deg2rad(phi_)))).T
            a_y = np.exp(-1j*2*np.pi*d/lam*np.arange(0, M_y, 1)*np.cos(np.deg2rad(theta_)*np.sin(np.deg2rad(phi_)))).T
            a = np.kron(a_x, a_y)
            music_spec[i, j] = a.conj().T @ E_N @ E_N.conj().T @ a
    return np.abs(music_spec)

@njit(cache=True)
def aoa_esprit(x, steering_vector):
    x_ = x
    steering_vector_ = steering_vector
    num_sample = x_.shape[1]
    num_ante = x_.shape[0]
    num_angle = steering_vector_.shape[0]

    Rxx = cov_matrix(x) # antenna * antenna
    num_sig = aoa_aic_num(x_)
    eig_va, eig_ve = np.linalg.eigh(Rxx)
    eig_ve_sort = np.argsort(eig_va)[::-1]
    S = np.zeros((num_ante, num_sig), dtype=np.complex64)
    for i in range(num_sig):
        S[:, i] = eig_ve[:, eig_ve_sort[i]] # antenna * sig
    A = steering_vector_.T # antenna * angle
    T_mat = np.linalg.pinv(A) @ S
    S1 = A[:num_ante-1] @ T_mat # antenna-1 * sig
    S2 = A[1:] @ T_mat # antenna-1 * sig
    # S1 = S[:num_ante-1]
    # S2 = S[1:]
    S12 = np.concatenate((S1, S2), axis=1) # antenna-1 * 2sig
    _, U = np.linalg.eig(S12.conj().T @ S12) # 2sig * 2sig
    U12, U22 = U[:num_sig, num_sig:], U[num_sig:, num_sig:]
    phi_TLS = -1 * U12 @ np.linalg.inv(U22)
    eig_tls_va, _ = np.linalg.eig(phi_TLS)
    # theta = np.arcsin(-1/np.pi * np.angle(eig_tls_va))
    # theta_ref = np.arcsin(-1/np.pi * np.angle(A[1]))
    esprit_spec = np.zeros(num_angle)
    # print(esprit_spec)
    wei_temp = np.zeros(num_angle)
    for idx in range(num_sig):
        if abs(eig_tls_va[idx]) == 0:
            eig_tls_va_temp = 0
        else:
            eig_tls_va_temp = eig_tls_va[idx]/abs(eig_tls_va[idx])
        for idy in range(num_angle):
            wei_temp[idy] = abs(eig_tls_va_temp - A[1][idy]) + 1e-4
        esprit_spec += 20 * np.exp(-1*wei_temp**2) / sum(np.exp(-1*wei_temp**2))
    return esprit_spec

@njit(cache=True)
def aoa_sub(x, steering_vector):
    x_ = x.T # num_sample * antenna
    steering_vector_ = steering_vector.T # antenna * angle
    num_sample = x_.shape[0]
    num_ante = x_.shape[1]
    num_angle = steering_vector_.shape[1]

    num_sig = min(aoa_mdl_num(x_.T), 4)
    sub_spec = np.ones(num_angle)
    resi = x_
    for idx in range(num_sig):
        if_break = False
        # PCA for complex
        resi_mean = np.sum(resi, axis=0) / num_sample
        resi_pca = resi - resi_mean
        cov_resi_pca = resi_pca.T @ resi_pca
        eig_va, eig_ve = np.linalg.eigh(cov_resi_pca)
        eig_ve_sort = eig_ve[np.argsort(eig_va)[::-1]]
        noise_space = eig_ve_sort[:,-(num_ante-num_sig):]
        # Angle estimation
        pos_poss = np.zeros(num_angle)
        for idy in range(num_angle):
            steering_factor = steering_vector_[:,idy] @ steering_vector_[:,idy].conj()
            if np.abs(steering_factor) != 0:
                pos_poss[idy] = np.real(steering_vector_.conj()[:,idy] @ noise_space @ noise_space.conj().T @ steering_vector_[:,idy])
            else:
                pos_poss[idy] = 1-1e-5
        neg_poss = -1*np.log(pos_poss)
        sub_spec += 100 * neg_poss / np.sum(neg_poss)
        esti_angle = np.argmin(neg_poss)
        # Null space calculation
        steering_vector_conj = np.ascontiguousarray(steering_vector_[:,esti_angle].conj())
        row_vec = np.array([1])
        esti_angle_vec = np.reshape(steering_vector_conj, (row_vec.shape[0],steering_vector_conj.shape[0]))
        u, s, vh = np.linalg.svd(esti_angle_vec, full_matrices=True)
        M, N = u.shape[0], vh.shape[1]
        null_space = (vh[1:, :].T.conj()).conj().T
        # null_space = linalg.null_space(np.reshape(steering_vector_.conj()[:,esti_angle], (1,-1))).conj().T
        # Vector projection
        resi = resi @ (null_space.conj().T)
        steering_vector_temp1 = null_space @ steering_vector_
        steering_vector_temp2 = np.zeros((num_ante-idx-1,num_angle), dtype=np.complex64)
        for idy in range(num_angle):
            norm_factor_pre = sum(np.abs(steering_vector_temp1[:,idy])**2)
            norm_factor = np.sqrt(norm_factor_pre)
            if norm_factor != 0.0:
                steering_vector_temp2[:, idy] = steering_vector_temp1[:, idy] / norm_factor
            else:
                steering_vector_temp2[:, idy] = steering_vector_temp1[:, idy] * 0
            #
            # for idz in range(num_ante-idx-1):
            #     if np.isnan(steering_vector_temp2[idz][idy]):
            #         print('error', idx, idy)
            #         print(norm_factor)
            #         print(steering_vector_temp2[:,idy])


        steering_vector_ = steering_vector_temp2
    return sub_spec