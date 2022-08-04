function [ corrected ] = correct_cor(CtData, n)
%CORRECT_COR Correct misplaced center of rotation in CT data
%   corrected = correct_cor(CtData, n) returns a copy of the computed 
%   tomography dataset ''CtData'' where the center of rotation has been 
%   shifted by n pixels, using circular boundary conditions. The input 
%   parameter ''n'' must be an integer. A positive value shifts the 
%   projections right and a negative value shifts the projections left. 
%   This function works for both 2D and 3D datasets.
%
%   This function is part of the HelTomo Toolbox, and was created primarily
%   for use with CT data measured in the Industrial Mathematics Computed 
%   Tomography Laboratory at the University of Helsinki.
%
%   Alexander Meaney, University of Helsinki
%   Created:            1.7.2019
%   Last edited:        4.8.2022

% Validate input parameter ''n''
if ~isscalar(n) || floor(n) ~= n
    error('Parameter ''n'' must be an integer.');
end

% Create a new ct project for corrected data
corrected       = struct;
corrected.type  = CtData.type;

% Copy existing parameters into a new struct
parameters      = CtData.parameters;

% Create new, empty sinogram
sinogram        = zeros(size(CtData.sinogram));

% Create shifted sinogram
if strcmpi(CtData.type, '2D')
    sinogram    = circshift(CtData.sinogram, n, 2);
elseif strcmp(CtData.type, '3D')
    % Loop through images, shift individually and place into new sinogram
    for iii = 1 : parameters.numberImages
        I = squeeze(CtData.sinogram(:, iii, :));
        I = circshift(I, n);
        sinogram(:, iii, :) = I;
    end
else
    error('Invalid CT data type found, must be of type ''2D'' or ''3D''.');
end    
    
% Attach new scan parameters and sinogram to the new ct project
corrected.parameters    = parameters;
corrected.sinogram      = sinogram;

end
