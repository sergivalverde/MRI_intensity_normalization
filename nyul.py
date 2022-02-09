import nibabel as nib
import numpy as np
from scipy.interpolate import interp1d


def nyul_apply_standard_scale(input_image,
                              standard_hist,
                              input_mask=None,
                              interp_type='linear'):
    """

    Based on J.Reinhold code:
    https://github.com/jcreinhold/intensity-normalization

    Use Nyul and Udupa method ([1,2]) to normalize the intensities
    of a MRI image passed as input.

    Args:
        input_image (np.ndarray): input image to normalize
        standard_hist (str): path to output or use standard histogram landmarks
        input_mask (nii): optional brain mask

    Returns:
        normalized (np.ndarray): normalized input image

    References:
        [1] N. Laszlo G and J. K. Udupa, “On Standardizing the MR Image
            Intensity Scale,” Magn. Reson. Med., vol. 42, pp. 1072–1081,
            1999.
        [2] M. Shah, Y. Xiao, N. Subbanna, S. Francis, D. L. Arnold,
            D. L. Collins, and T. Arbel, “Evaluating intensity
            normalization on MRIs of human brain with multiple sclerosis,”
            Med. Image Anal., vol. 15, no. 2, pp. 267–282, 2011.
    """

    # load learned standard scale and the percentiles
    standard_scale, percs = np.load(standard_hist)

    # apply transformation to image
    return do_hist_normalization(input_image,
                                 percs,
                                 standard_scale,
                                 input_mask,
                                 interp_type=interp_type)


def get_landmarks(img, percs):
    """
    get the landmarks for the Nyul and Udupa norm method for a specific image

    Based on J.Reinhold code:
    https://github.com/jcreinhold/intensity-normalization

    Args:
        img (nibabel.nifti1.Nifti1Image): image on which to find landmarks
        percs (np.ndarray): corresponding landmark percentiles to extract

    Returns:
        landmarks (np.ndarray): intensity values corresponding to percs in img
    """
    landmarks = np.percentile(img, percs)
    return landmarks


def nyul_train_standard_scale(img_fns,
                              mask_fns=None,
                              i_min=1,
                              i_max=99,
                              i_s_min=1,
                              i_s_max=100,
                              l_percentile=10,
                              u_percentile=90,
                              step=10):
    """
    determine the standard scale for the set of images

    Based on J.Reinhold code:
    https://github.com/jcreinhold/intensity-normalization


    Args:
        img_fns (list): set of NifTI MR image paths which are to be normalized
        mask_fns (list): set of corresponding masks (if not provided, estimated)
        i_min (float): minimum percentile to consider in the images
        i_max (float): maximum percentile to consider in the images
        i_s_min (float): minimum percentile on the standard scale
        i_s_max (float): maximum percentile on the standard scale
        l_percentile (int): middle percentile lower bound (e.g., for deciles 10)
        u_percentile (int): middle percentile upper bound (e.g., for deciles 90)
        step (int): step for middle percentiles (e.g., for deciles 10)

    Returns:
        standard_scale (np.ndarray): average landmark intensity for images
        percs (np.ndarray): array of all percentiles used
    """

    # compute masks is those are not entered as a parameters
    mask_fns = [None] * len(img_fns) if mask_fns is None else mask_fns

    percs = np.concatenate(([i_min],
                            np.arange(l_percentile, u_percentile+1, step),
                            [i_max]))
    standard_scale = np.zeros(len(percs))

    # process each image in order to build the standard scale
    for i, (img_fn, mask_fn) in enumerate(zip(img_fns, mask_fns)):
        print('processing scan ', img_fn)
        img_data = nib.load(img_fn).get_data()  # extract image as numpy array
        mask = nib.load(mask_fn) if mask_fn is not None else None  # load mask as nibabel object
        mask_data = img_data > img_data.mean() \
            if mask is None else mask.get_data()  # extract mask as numpy array
        masked = img_data[mask_data > 0]  # extract only part of image where mask is non-emtpy
        landmarks = get_landmarks(masked, percs)
        min_p = np.percentile(masked, i_min)
        max_p = np.percentile(masked, i_max)
        f = interp1d([min_p, max_p], [i_s_min, i_s_max])  # create interpolating function
        landmarks = np.array(f(landmarks))  # interpolate landmarks
        standard_scale += landmarks  # add landmark values of this volume to standard_scale
    standard_scale = standard_scale / len(img_fns)  # get mean values
    return standard_scale, percs


def do_hist_normalization(input_image,
                          landmark_percs,
                          standard_scale,
                          mask=None,
                          interp_type='linear'):
    """
    do the Nyul and Udupa histogram normalization routine with a given set of
    learned landmarks

    Based on J.Reinhold code:
    https://github.com/jcreinhold/intensity-normalization

    Args:
        img (np.ndarray): image on which to find landmarks
        landmark_percs (np.ndarray): corresponding landmark points of standard scale
        standard_scale (np.ndarray): landmarks on the standard scale
        mask (np.ndarray): foreground mask for img
        interp_type (str): type of interpolation

    Returns:
        normalized (np.ndarray): normalized image
    """

    mask_data = input_image > input_image.mean() if mask is None else mask
    masked = input_image[mask_data > 0]  # extract only part of image where mask is non-emtpy
    landmarks = get_landmarks(masked, landmark_percs)
    
    f = interp1d(landmarks, standard_scale, kind=interp_type, fill_value='extrapolate')  # define interpolating function

    # apply transformation to input image
    return f(input_image)
