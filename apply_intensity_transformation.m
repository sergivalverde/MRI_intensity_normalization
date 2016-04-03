function apply_intensity_transformation(input_path, output_path, m_k)
% **************************************************************************************************
%  Intensity normalization of MRI scans. Function to apply the
%  learned intensity landmarks (m_k) into the input image. 
%
%  Normalization method based on Nyul et al 2000
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
    num_bins = 256;
       
    % load the input image
    im_path = (input_path);
    current_scan = load_nifti(im_path);
    current_image = current_scan.img;
    template_brainmask = current_image > 0.05;
    template = current_image(template_brainmask == 1);
    
    % compute the histogram and the percentiles 
    [h_template,template_centers] = hist(template, num_bins);
    cum_template = cumsum(h_template);
    percents = ceil(cum_template ./ length(template(:)) * 100);
    round_percents = ceil(percents ./ 10) * 10;

    % map deciles to image intensities
    T.values(1) = template_centers(find(percents >= 1 & percents < 5,1,'first'));
    T.values(2) = template_centers(find(round_percents == 10,1,'last'));
    T.values(3) = template_centers(find(round_percents == 20,1,'last'));
    T.values(4) = template_centers(find(round_percents == 30,1,'last'));
    T.values(5) = template_centers(find(round_percents == 40,1,'last'));
    T.values(6) = template_centers(find(round_percents == 50,1,'last'));
    T.values(7) = template_centers(find(round_percents == 60,1,'last'));
    T.values(8) = template_centers(find(round_percents == 70,1,'last'));
    T.values(9) = template_centers(find(round_percents == 80,1,'last'));
    T.values(10)= template_centers(find(round_percents == 90,1,'last'));
    T.values(11)= template_centers(find(percents > 90 & percents < 100,1, 'last'));
    T.binsize = (T.values(11) - T.values(1)) / (length(h_template) -1);


    % apply the transformation between the learned model and the
    % current image
    normalized_scan = zeros(size(template));
    normalized_scan(template_brainmask == 1) = spline(T.values, m_k.landmarks, template(:));
                                                      
    % intensities > 100% are just mapped linearly to preserve the
    % same intensity transformation
    model_linear_rate = (m_k.info.max_int - m_k.info.min_int) / (m_k.info.binsize -1);
    normalized_scan(template > T.values(11)) = template(template > T.values(11)) .* model_linear_rate;
                                                      
    % save the normalized scan
    current_scan.img = normalized_scan;
    save_nifti(current_scan, output_path);
       
end
