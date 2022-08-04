function [ A ] = bin_pixels(I, n)
%BIN_PIXELS Pixel binning operation on an image
%   A = bin_pixels(I, n) computes a binned version of image I using a pixel
%   binning factor of n.  Binning increases signal-to-noise ratio but 
%   reduces spatial resolution. The factor n must be an integer power of 2 
%   in the range 1 <= n <= 32. For an i x j image, the binning operation 
%   returns an i/n * j/n image, where each pixel has been summed from an 
%   n * n area of the original image.
%
%   This function is part of the HelTomo Toolbox, and was created primarily
%   for use with CT data measured in the Industrial Mathematics Computed 
%   Tomography Laboratory at the University of Helsinki.
%
%   Alexander Meaney, University of Helsinki
%   Created:            28.8.2017
%   Last edited:        1.8.2022

[rows, cols] = size(I);

% Check if downbinning is possible

if ~isscalar(n) || ~ismember(n, [1 2 4 8 16 32])
    error('Binning factor n must be a member of the set {1, 2, 4, 8, 16, 32}.');
end

if rem(rows, n) ~= 0 || rem(cols, n) ~= 0
    error('Binning factor and initial image size lead to non-integer image size.');
end

% Create binned image by summing values of non-overlapping n*n regions

A = reshape(I, [n rows*cols/n]);
A = sum(A, 1);
A = reshape(A, [rows/n cols]);

A = A.';
  
A = reshape(A, [n rows*cols/n^2]);
A = sum(A, 1);
A = reshape(A, [cols/n rows/n]);

A = A.';

end

