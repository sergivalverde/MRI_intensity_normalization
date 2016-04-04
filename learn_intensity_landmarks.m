function [m_k] = learn_intensity_landmarks(training_image_path, i_min, i_max)
% ***************************************************************************************************
%  Intensity normalization of MRI scans. Function to learn the
%  intensity landmarks based on a set of several training images
%  
%  The function returns the learned landmarks for the minimum and
%  maximum intensities (i_min, i_max) and each of the histogram
%  deciles. 
%
%  Normalization method based on Nyul et al 2000:
%
%  - L. G. Nyul, J. K. Udupa, and X. Zhang, “New variants of a
%  method of MRI scale standardization,” IEEE Trans. Med. Imaging, no. 2, pp. 143–150, 2000.
%
%  - M. Shah, Y. Xiao, N. Subbanna, S. Francis, D. L. Arnold, D. L.
%  Collins, and T. Arbel, “Evaluating intensity normalization of
%  MRIs of human brain with multiple sclerosis,” Med. Image Anal., vol. 15, no. 2, pp. 267–282, 2011.
%    
%  svalverde@eia.udg.edu 2016
%  NeuroImage Computing Group. Vision and Robotics Insititute (University of Girona)
%
% ***************************************************************************************************
    
    num_images = size(training_image_path,1);
    
    % compute the landmarks for each training image. Landmarks are learned without using the histogram.
    for im=1:num_images
        
        % load the current training image
        im_path = cell2mat(training_image_path(im));
        current_scan = load_nifti(im_path);
        current_image = current_scan.img;
        template_brainmask = current_image > 0.05;
        template = current_image(template_brainmask == 1);
        
        % find the minimum and maximum percentiles (p1 and p99) and the deciles (p10...p90)
        Y = sort(template(:));        
        m(im,1) =  Y(ceil(0.01.*length(Y)));
        m(im,2) =  Y(ceil(0.1.*length(Y)));
        m(im,3) =  Y(ceil(0.2.*length(Y)));
        m(im,4) =  Y(ceil(0.3.*length(Y)));
        m(im,5) =  Y(ceil(0.4.*length(Y)));
        m(im,6) =  Y(ceil(0.5.*length(Y)));
        m(im,7) =  Y(ceil(0.6.*length(Y)));
        m(im,8) =  Y(ceil(0.7.*length(Y)));
        m(im,9) =  Y(ceil(0.8.*length(Y)));
        m(im,10) = Y(ceil(0.9.*length(Y)));
        m(im,11) = Y(ceil(0.99.*length(Y)));

        
        % map linearly the intensities with respect to i_max and i_min
        linear_rate(im) = ((i_max - i_min) / (length(Y) -1)) / ((m(im,11) - m(im,1)) / (length(Y)-1));
        m(im,:) = m(im,:) .* linear_rate(im);
    end
    
    
    
    % rounded means of each of the landmarks from the set of training images
    m_k.landmarks = mean(m,1)';
    
    % save additional info
    m_k.info.landmark_position = {'i_min', 'm10', 'm20', 'm30', 'm40', ...
                        'm50', 'm60', 'm70', 'm80', 'm90', 'i_max'};
    m_k.info.min_int = i_min;
    m_k.info.max_int = i_max;
    m_k.info.num_images = num_images;
    m_k.info.image_path = training_image_path;
    m_k.info.linear_rate = linear_rate;
    m_k.info.percentiles = m;   
end
