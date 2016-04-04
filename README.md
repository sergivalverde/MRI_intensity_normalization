# MRI intensity normalization

Intensity normalization of multi-channel MRI images using the method proposed by [Nyul et al. 2000](http://ieeexplore.ieee.org/lpdocs/epic03/wrapper.htm?arnumber=836373).
In the original paper, the authors suggest a method where a set of standard histogram landmarks are learned from a set of MRI images. These landmarks are then used to equalize the histograms of the images to normalize. In both learning and transformation, the histograms are used to find the intensity landmarks. In our implmentation, the landmarks are computed based on the total range of intensities instead of the histograms. 

## How it works:

The normalization is carried out in two steps:

### Learning the landmark parameters:

From a set of training images, the landmark parameters are learned using the function `learn_intensity_parameters`. Intensity parameters `ì_min` and  `i_max` have to be set by the user. These two values establish the minimum and maximum intensities of the standard intensity scale.

```
train_im_path{1} = '/path/to/images/1/t1.nii';
train_im_path{2} = '/path/to/images/2/t1.nii';
...
train_im_path{n} = '/path/to/images/n/t1.nii';

i_min = min_intensity;
i_max = max_intensity;

% learn the parameters
m_k = learn_intensity_landmarks(train_im_path, i_min, i_max);
```

The output struct `m_k` contains the standard landmarks learned from the input images. These landmarks refer to the minimum intensity, the signal intensity deciles {d10,...,d90},  and the maximum intensity of interest.  

	
### Apply the transformation function to each of the images to normalize

The output struct `m_k` is used to map the intensities of each of the input images with respect to the standard scale. The original paper implements a function that maps linearly the input intensities into the standard histogram. However, the authors suggest that other mapping functions can be also used. Here, input intensities are mapped using a spline function.

```
input_image = '/path/to/input/image'
out_name = '/path/to/input/image/normalized_scan'

apply_intensity_transformation(input_image, out_name, m_k);
```

## Notes:

+ Input images have to be skull-stripped for optimal results. If images are not skull-stripped but background intensity is `< 0.05`, the method should also work. With background intensities higher than this threshold the landmarks may be altered in some unexpected way due to the skull  

+ The current method uses the `nifti_tools` repository available [here](https://github.com/sergivalverde/nifti_tools). Add it to your Matlab path or initialize the included submodule after cloning the project as:

```
git submodule init
git submodule update
```


## Credits:

Sergi Valverde / [NeuroImage Computing Group](http://atc.udg.edu/nic/index.html). Vision and Robotics Insititute [VICOROB](http://vicorob.udg.edu) 
(University of Girona)
