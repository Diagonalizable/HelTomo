function [ A ] = create_ct_operator_2d_fan_astra(CtData, xDim, yDim)
%CREATE_CT_OPERATOR_2D_FAN_ASTRA Create 2D CT forward model
%   A = create_ct_operator_2d_fan_astra(ctData, xDim, yDim) computes the 
%   forward model, i.e. X-ray projection operator, for the 2D fan-beam CT
%   project given in input parameter ''CtData''. The x- and y-dimensions of
%   the CT volume are given by parameters ''xDim'' and ''yDim'', 
%   respectively. The imaging geometry is created using the metadata in 
%   CtData. It is assumed that a flat detector has been used for the X-ray 
%   projection measurements.
%
%   The forward model is an operator that behaves like a matrix, for
%   example in operations like A*x and and A.'*x, but no explicit matrix is
%   actually created.
%
%   Use of this function requires that the ASTRA Tomography Toolbox 
%   (https://www.astra-toolbox.com/) and the Spot Linear-Operator Toolbox 
%   (https://www.cs.ubc.ca/labs/scl/spot/) have been added to the MATLAB 
%   path. The operator is created using the CPU. The function has been
%   verified to work with ASTRA version 2.0.0.
%
%   This function is part of the HelTomo Toolbox, and was created primarily
%   for use with CT data measured in the Industrial Mathematics Computed 
%   Tomography Laboratory at the University of Helsinki.
%
%   Alexander Meaney, University of Helsinki
%   Created:            1.7.2019
%   Last edited:        1.8.2022

% Validate input parameters

if ~isscalar(xDim) || xDim < 1 || floor(xDim) ~= xDim
    error('Parameter ''xDim'' must be a positive integer.');
end

if ~isscalar(yDim) || yDim < 1 || floor(yDim) ~= yDim
    error('Parameter ''yDim'' must be a positive integer.');
end

% Create shorthands for needed variables
DSD             = CtData.parameters.distanceSourceDetector;
DSO             = CtData.parameters.distanceSourceOrigin;
M               = CtData.parameters.geometricMagnification;
angles          = CtData.parameters.angles;
numDetectors    = CtData.parameters.numDetectorsPost;
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
volumeGeometry = astra_create_vol_geom(yDim, xDim);

% Create projection geometry
projectionGeometry = astra_create_proj_geom('fanflat', M, numDetectors, ...
                                            anglesRad, DSO, DOD);

% Create the Spot operator for ASTRA using the CPU.
A = opTomo('strip_fanflat', projectionGeometry, volumeGeometry);
fprintf('done.\n');

% Memory cleanup
astra_mex_data2d('delete', volumeGeometry);
astra_mex_data2d('delete', projectionGeometry);
clearvars -except A

end

