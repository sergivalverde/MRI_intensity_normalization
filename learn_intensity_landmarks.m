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
    

    % options
    bin_size = 256;

    num_images = size(training_image_path,1);
    
    % compute the landmarks for each training image
    for im=1:num_images
     
        % load the current training image
        im_path = cell2mat(training_image_path(im));
        current_scan = load_nifti(im_path);
        current_image = current_scan.img;
        template_brainmask = current_image > 0.05;
        template = current_image(template_brainmask == 1);
        
        % compute the histogram and the percentiles
        [h_template, template_centers] = hist(template, bin_size);
        histograms(im,:) = h_template;
        histogram_centers(im,:) = template_centers;
        
        % compute the landmark locations 
        cum_template = cumsum(h_template);
        percents = ceil(cum_template ./ length(template(:)) * 100);
        percentiles(im,:) = percents; 
        round_percents = ceil(percents ./ 10) * 10; %force deciles to exist when
                                                    %no available
                                                    
        % map deciles with image intensities       
        m(im,1) = template_centers(find(percents >= 1 & percents < 5,1,'first'));
        m(im,2) = template_centers(find(round_percents == 10,1,'last'));
        m(im,3) = template_centers(find(round_percents == 20,1,'last'));
        m(im,4) = template_centers(find(round_percents == 30,1,'last'));
        m(im,5) = template_centers(find(round_percents == 40,1,'last'));
        m(im,6) = template_centers(find(round_percents == 50,1,'last'));
        m(im,7) = template_centers(find(round_percents == 60,1,'last'));
        m(im,8) = template_centers(find(round_percents == 70,1,'last'));
        m(im,9) = template_centers(find(round_percents == 80,1,'last'));
        m(im,10)= template_centers(find(round_percents  == 90,1,'last'));
        m(im,11)= template_centers(find(percents > 90 & percents < 100,1, 'last'));
        
        % map linearly the intensities with respect to i_max and i_min
        linear_rate(im) = ((i_max - i_min) / (length(h_template) -1)) / ...
            ((m(im,11) - m(im,1)) / (length(h_template)-1));
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
    m_k.info.binsize = bin_size;
    m_k.info.histograms = histograms;
    m_k.info.histogram_centers = histogram_centers;
    m_k.info.percentiles = percentiles;
    m_k.info.linear_rate = linear_rate;
       
end
