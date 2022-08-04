function [ recon ] = tomorecon_2d_fan_fbp_astra_cuda(CtData, xDim, yDim, varargin)
%TOMORECON_2D_FAN_FBP_ASTRA_CUDA Analytical 2D fan-beam GPU reconstruction.
%   recon = tomorecon_2d_fan_fbp_astra_cuda(CtData, xDim, yDim) computes 
%   the analytical 2D reconstruction of the fan-beam CT data in ''CtData'' 
%   using the FBP algorithm. The x- and y-dimensions of the reconstruction 
%   are specified by the input parameters ''xDim'' and ''yDim'', 
%   respectively. It is assumed that a flat detector has been used for the 
%   X-ray projection measurements.
%
%   recon = tomorecon_2d_fan_fbp_astra_cuda(CtData, xDim, yDim, energyBin)
%   is used if a photon counting detector (PCD) has been used to collect 
%   the X-ray data. The input parameter ''energyBin'' is a string 
%   specifying the energy bin that will be reconstructed. Its allowed
%   values are 'total', 'low' and 'high'.
%
%   Use of this function requires that the ASTRA Tomography Toolbox 
%   (https://www.astra-toolbox.com/) and the Spot Linear-Operator Toolbox 
%   (https://www.cs.ubc.ca/labs/scl/spot/) have been added to the MATLAB 
%   path. The computer must also be equipped with a CUDA-enabled GPU to
%   compute the reconstruction. The function has been verified to work with
%   ASTRA version 2.0.0.
%
%   This function is part of the HelTomo Toolbox, and was created primarily
%   for use with CT data measured in the Industrial Mathematics Computed 
%   Tomography Laboratory at the University of Helsinki.
%
%   Alexander Meaney, University of Helsinki
%   Created:            1.7.2019
%   Last edited:        3.8.2022

% Validate input parameters

if ~isscalar(xDim) || xDim < 1 || floor(xDim) ~= xDim
    error('Parameter ''xDim'' must be a positive integer.');
end

if ~isscalar(yDim) || yDim < 1 || floor(yDim) ~= yDim
    error('Parameter ''yDim'' must be a positive integer.');
end

% Validate CT data type
if ~strcmpi(CtData.type, '2D')
    error('ctData must be of type ''2D''.');
end

% If the data is from a PCD, the energy bin must be specified
if strcmpi(CtData.parameters.detectorType, 'PCD')
    if length(varargin) ~= 1
        error('For PCD data, specify energy bin to reconstruct (total, high, or low).');
    end
    if ~ismember(lower(varargin{1}), {'total', 'high', 'low'})
        error('For PCD data, specify energy bin to reconstruct (total, high, or low).');
    end
    if strcmpi(varargin{1}, 'total')
        sinogram = CtData.sinogramTotal;
    elseif strcmpi(varargin{1}, 'high')
        sinogram = CtData.sinogramHigh;
    elseif strcmpi(varargin{1}, 'low')
        sinogram = CtData.sinogramLow;
    else
        error('Unknown error occurred in sinogram identification.');
    end
else
    % EID data
    sinogram = CtData.sinogram;
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

% Create 2D data object for reconstruction
reconstructionObject = astra_mex_data2d('create', '-vol', ...
                                        volumeGeometry, 0);

% Create 2D data object for sinogram
projectionsObject = astra_mex_data2d('create', '-sino', ...
                                     projectionGeometry, sinogram);

fprintf('done.\n');

% Create and initialize reconstruction algorithm
fprintf('Creating reconstruction algorithm in ASTRA... ');
cfg                         = astra_struct('FBP_CUDA');
cfg.ReconstructionDataId    = reconstructionObject;
cfg.ProjectionDataId        = projectionsObject;
reconstructionAlgorithm     = astra_mex_algorithm('create', cfg);
fprintf('done.\n');

% Run reconstruction algorithm
fprintf('Running reconstruction algorithm in ASTRA... ');
astra_mex_algorithm('run', reconstructionAlgorithm);
fprintf('done.\n');

% Get reconstruction as a matrix
recon = astra_mex_data2d('get', reconstructionObject);

% Memory cleanup
astra_mex_data2d('delete', volumeGeometry);
astra_mex_data2d('delete', projectionGeometry);
astra_mex_data2d('delete', reconstructionObject);
astra_mex_data2d('delete', projectionsObject);
astra_mex_algorithm('delete', reconstructionAlgorithm);
astra_clear;
clearvars -except recon

end

