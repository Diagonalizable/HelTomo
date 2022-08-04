function [ A ] = create_ct_operator_3d_cone_astra_cuda(CtData, xDim, yDim, zDim)
%CREATE_CT_OPERATOR_3D_CONE_ASTRA_CUDA Create 3D CT forward model (GPU)
%   A = create_ct_operator_3d_cone_astra_cuda(CtData, xDim, yDim, zDim)
%   computes the forward model, i.e. X-ray projection operator, for the 3D 
%   cone-beam CT data given in input parameter ''CtData''. The x-, y-, and 
%   z-dimensions of the CT volume are given by parameters ''xDim'', 
%   ''yDim'', and ''zDim'', respectively. The imaging geometry is created 
%   using the metadata in CtData. It is assumed that a flat panel detector 
%   has been used for the X-ray projection measurements.
%
%   The forward model is an operator that behaves like a matrix, for
%   example in operations like A*x and and A.'*x, but no explicit matrix is
%   actually created.
%
%   Use of this function requires that the ASTRA Tomography Toolbox 
%   (https://www.astra-toolbox.com/) and the Spot Linear-Operator Toolbox 
%   (https://www.cs.ubc.ca/labs/scl/spot/) have been added to the MATLAB 
%   path. The computer must also be equipped with a CUDA-enabled GPU to
%   create the operator. The function has been verified to work with ASTRA
%   version 2.0.0.
%
%   This function is part of the HelTomo Toolbox, and was created primarily
%   for use with CT data measured in the Industrial Mathematics Computed 
%   Tomography Laboratory at the University of Helsinki.
%
%   Alexander Meaney, University of Helsinki
%   Created:            30.1.2019
%   Last edited:        3.8.2022

% Validate input parameters

if ~isscalar(xDim) || xDim < 1 || floor(xDim) ~= xDim
    error('Parameter ''xDim'' must be a positive integer.');
end

if ~isscalar(yDim) || yDim < 1 || floor(yDim) ~= yDim
    error('Parameter ''yDim'' must be a positive integer.');
end

if ~isscalar(zDim) || zDim < 1 || floor(zDim) ~= zDim
    error('Parameter ''zDim'' must be a positive integer.');
end

% Create shorthands for needed variables
DSD             = CtData.parameters.distanceSourceDetector;
DSO             = CtData.parameters.distanceSourceOrigin;
M               = CtData.parameters.geometricMagnification;
angles          = CtData.parameters.angles;
rows            = CtData.parameters.projectionRows;
cols            = CtData.parameters.projectionCols;
effPixel        = CtData.parameters.effectivePixelSizePost;

% Distance from origin to detector
DOD             = DSD - DSO;

% Distance from source to origin specified in terms of effective pixel size
DSO             = DSO / effPixel;

% Distance from origin to detector specified in terms of effective pixel size
DOD             = DOD /effPixel;

% ASTRA uses angles in radians
anglesRad       = deg2rad(angles);

% ASTRA code begins here
fprintf('Creating geometries and data objects in ASTRA... ');

% Create volume geometry, i.e. reconstruction geometry
% Note: according to ASTRA documentation, xDim and yDim should be reversed,
% but the implementation below seems to produce the correct-sized image
volumeGeometry = astra_create_vol_geom(xDim, yDim, zDim);

% Create projection geometry
projectionGeometry = astra_create_proj_geom('cone', M, M, ...
                                            rows, cols, ...
                                            anglesRad, DSO, DOD);

% Create the Spot operator for ASTRA using the GPU.
A = opTomo('cuda', projectionGeometry, volumeGeometry);
fprintf('done.\n');

% Memory cleanup
astra_mex_data3d('delete', volumeGeometry);
astra_mex_data3d('delete', projectionGeometry);
clearvars -except A


end

