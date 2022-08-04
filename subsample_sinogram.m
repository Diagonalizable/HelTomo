function [ CtDataSubsampled ] = subsample_sinogram(CtData, anglesReduced)
%SUBSAMPLE_SINOGRAM Subsample angular range of sinogram
%   CtDataSubsampled = subsample_sinogram(CtData, anglesReduced) returns a 
%   version of a computed tomography project, given by parameter 
%   ''CtData'', in which the sinogram contains only the projections for 
%   the angles given in ''anglesReduced''. The parameter ''anglesReduced'' 
%   must be a vector containing the desired angles in degrees. Any 
%   projection directions found in ''anglesReduced'' but not in ''CtData'' 
%   are ignored. This function works for both 2D and 3D datasets.
%
%   This function is part of the HelTomo Toolbox, and was created primarily
%   for use with CT data measured in the Industrial Mathematics Computed 
%   Tomography Laboratory at the University of Helsinki.
%
%   Alexander Meaney, University of Helsinki
%   Created:            1.7.2019
%   Last edited:        3.8.2022


% Validate input parameter ''anglesReduced''
if ~isvector(anglesReduced) || ~isreal(anglesReduced)
    error('Parameter ''anglesReduced'' must be a real-valued vector.');
end

% Create a new ct project for the subsampled data
CtDataSubsampled      = struct;
CtDataSubsampled.type = CtData.type;

% Create subsampled angle indices
ind = ismembertol(CtData.parameters.angles, anglesReduced);

% Create sub-sampled sinogram
if strcmpi(CtData.type, '2D')
    sinogram        = CtData.sinogram(ind, :);
elseif strcmpi(CtData.type, '3D')
    sinogram        = CtData.sinogram(:, ind, :);
else
    error('Invalid CT data type found, must be of type ''2D'' or ''3D''.');
end

% Copy existing parameters into a new struct and change angle data
parameters              = CtData.parameters;
parameters.numberImages = sum(ind);
parameters.angles       = parameters.angles(ind);

% Attach new scan parameters and sinogram to the new ct project
CtDataSubsampled.sinogram     = sinogram;
CtDataSubsampled.parameters   = parameters;

end
