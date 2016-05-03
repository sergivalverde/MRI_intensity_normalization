function apply_intensity_transformation(input_path, output_path, m_k, methodT)
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
% **************************************************************************************************       

    num_images = size(input_path,2);
    for im=1:num_images

    % load the input image
    im_path = cell2mat(input_path(im));
    imOut_path = cell2mat(output_path(im));
    current_scan = load_nifti(im_path);
    current_image = current_scan.img;
    template_brainmask = current_image > 0.05;
    template = current_image(template_brainmask == 1);


    % find the minimum and maximum percentiles (p1 and p99) and the deciles (p10...p90)
    Y = sort(template(:));

    minT=min(Y);

    T.values(1) = Y(ceil(0.01.*length(Y)));

    T.values(2) = Y(ceil(0.1.*length(Y)));
    T.values(3) = Y(ceil(0.2.*length(Y)));
    T.values(4) = Y(ceil(0.3.*length(Y)));
    T.values(5) = Y(ceil(0.4.*length(Y)));
    T.values(6) = Y(ceil(0.5.*length(Y)));
    T.values(7) = Y(ceil(0.6.*length(Y)));
    T.values(8) = Y(ceil(0.7.*length(Y)));
    T.values(9) = Y(ceil(0.8.*length(Y)));
    T.values(10) = Y(ceil(0.9.*length(Y)));

    T.values(11) = Y(ceil(0.99.*length(Y)));    

    maxT=max(Y);

    % apply the transformation to the current image

    mask=(current_image<T.values(1));

    SscaleExtremeMin= m_k.landmarks(1) + ( minT - T.values(1) ) / ( T.values(2)-T.values(1) ) * (m_k.landmarks(2) - m_k.landmarks(1));
    SscaleExtremeMax= m_k.landmarks(10)+ ( maxT - T.values(10) ) / ( T.values(11)-T.values(10) ) * (m_k.landmarks(11) - m_k.landmarks(10));
     
    if strcmp(methodT,'linear')

	 %normalized_scan = interp1( [minT T.values maxT], [SscaleExtremeMin m_k.landmarks SscaleExtremeMax], current_image) ;
	 normalized_scan = interp1( [ T.values maxT ],[ m_k.landmarks SscaleExtremeMax ], current_image) ;

    elseif strcmp(methodT,'spline')
	%normalized_scan = spline( [minT T.values maxT], [SscaleExtremeMin m_k.landmarks SscaleExtremeMax], current_image);
	normalized_scan = spline( [ T.values maxT ],[ m_k.landmarks SscaleExtremeMax ], current_image);
    else
	error('Invalid value for Method')
 
    end

	normalized_scan(mask)=0;

    % save the normalized scan
    current_scan.img = normalized_scan;
    save_nifti(current_scan, imOut_path);
     end  
end
