function [ A ] = create_ct_matrix_2d_fan_astra(CtData, xDim, yDim)
%CREATE_CT_MATRIX_2D_FAN_ASTRA Create 2D CT system matrix
%   A = create_ct_matrix_2d_fan_astra(CtData, xDim, yDim) computes the 
%   forward model, i.e. X-ray projection matrix, for the 2D fan-beam CT
%   project given in input parameter ''CtData''. The x- and y-dimensions of
%   the CT volume are given by parameters ''xDim'' and ''yDim'', 
%   respectively. The imaging geometry is created using the metadata in 
%   CtData. It is assumed that a flat detector has been used for the X-ray 
%   projection measurements.
%
%   Use of this function requires that the ASTRA Tomography Toolbox 
%   (https://www.astra-toolbox.com/) has been added to the MATLAB path. The
%   function has been verified to work with ASTRA version 2.0.0.
%
%   This function is part of the HelTomo Toolbox, and was created primarily
%   for use with CT data measured in the Industrial Mathematics Computed 
%   Tomography Laboratory at the University of Helsinki.
%
%   Alexander Meaney, University of Helsinki
%   Created:            11.11.2020
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
% Note: according to ASTRA documentation, xDim and yDim should be reversed,
% but the implementation below seems to produce the correct-sized image
volumeGeometry = astra_create_vol_geom(xDim, yDim);

% Create projection geometry
projectionGeometry = astra_create_proj_geom('fanflat', M, numDetectors, ...
                                            anglesRad, DSO, DOD);

% Create projector
projector = astra_create_projector('strip_fanflat', projectionGeometry, ...
                                   volumeGeometry);
                                        
% Create projection matrix
projectionMatrix = astra_mex_projector('matrix', projector);

% Obtain projection matrix as a MATLAB sparse matrix
A = astra_mex_matrix('get', projectionMatrix);

fprintf('done.\n');

% Memory cleanup
astra_mex_data2d('delete', volumeGeometry);
astra_mex_data2d('delete', projectionGeometry);
astra_mex_projector('delete', projector);
astra_mex_matrix('delete', projectionMatrix);
clearvars -except A

end

