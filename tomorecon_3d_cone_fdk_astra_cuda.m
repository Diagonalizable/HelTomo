function [ recon ] = tomorecon_3d_cone_fdk_astra_cuda(CtData, xDim, yDim, zDim, varargin)
%TOMORECON_3D_CONE_FDK_ASTRA_CUDA Analytical 3D cone-beam reconstruction
%   recon = tomorecon_3d_cone_fdk_astra_cuda(ctData, xDim, yDim, zDim) 
%   computes the approximate analytical 3D reconstruction of the cone-beam 
%   CT data in ''CtData'' using the FDK algorithm. The x-, y-, and
%   z-dimensions of the reconstruction are given by ''xDim'', ''yDim'', and
%   ''zDim'', respectively. It is assumed that a flat panel detector has 
%   been used for the X-ray projection measurements.
%
%   recon = tomorecon_3d_cone_fdk_astra_cuda(CtData, xDim, yDim, energyBin)
%   is used if a photon counting detector (PCD) has been used to collect 
%   the X-ray data. The input parameter ''energyBin'' is a string 
%   specifying the energy bin that will be reconstructed. Its allowed
%   values are 'total', 'low', and 'high'.
%
%   Use of this function requires that the ASTRA Tomography Toolbox 
%   (https://www.astra-toolbox.com/) and the Spot Linear-Operator Toolbox 
%   (https://www.cs.ubc.ca/labs/scl/spot/) have been added to the MATLAB 
%   path. The computer must also be equipped with a CUDA-enabled GPU. The 
%   function has been verified to work with ASTRA version 2.0.0.
%
%   This function is part of the HelTomo Toolbox, and was created primarily
%   for use with CT data measured in the Industrial Mathematics Computed 
%   Tomography Laboratory at the University of Helsinki.
%
%   Alexander Meaney, University of Helsinki
%   Created:            30.1.2019
%   Last edited:        4.8.2022


% Validate input obligatory input parameters

if ~strcmpi(CtData.type, '3D')
    error('CtData must be of type ''3D''.');
end

if ~isscalar(xDim) || floor(xDim) ~= xDim || xDim < 1 || ...
   ~isscalar(yDim) || floor(yDim) ~= yDim || yDim < 1 || ...
   ~isscalar(zDim) || floor(zDim) ~= zDim || zDim < 1
    error('Input parameters ''xDim'', ''yDim'', and ''zDim'' must be positive integers.');
end

% If data is from a PCD, the energy bin must be specified
if strcmpi(CtData.parameters.detectorType, 'PCD')
    if length(varargin) ~= 1
        error('For PCD data, specify energy bin to reconstruct (total, high, or low),');
    end
    if ~ismember(lower(varargin{1}), {'total', 'high', 'low'})
        error('For PCD data, specify energy bin to reconstruct (total, high, or low),');
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

% Create 3D data object for reconstruction
reconstructionObject = astra_mex_data3d('create', '-vol', volumeGeometry, 0);

% Create 3D data object for sinogram
projectionsObject       = astra_mex_data3d('create', '-proj3d', projectionGeometry, sinogram);

fprintf('done.\n');

% Create and initialize reconstruction algorithm
fprintf('Creating reconstruction algorithm in ASTRA... ');
cfg                         = astra_struct('FDK_CUDA');
cfg.ReconstructionDataId    = reconstructionObject;
cfg.ProjectionDataId        = projectionsObject;
reconstructionAlgorithm     = astra_mex_algorithm('create', cfg);
fprintf('done.\n');

% Run reconstruction algorithm
fprintf('Running reconstruction algorithm in ASTRA... ');
astra_mex_algorithm('run', reconstructionAlgorithm);
fprintf('done.\n');

% Get reconstruction as a matrix
recon = astra_mex_data3d('get', reconstructionObject);

% Memory cleanup
astra_mex_data3d('delete', volumeGeometry);
astra_mex_data3d('delete', projectionGeometry);
astra_mex_data3d('delete', reconstructionObject);
astra_mex_data3d('delete', projectionsObject);
astra_mex_algorithm('delete', reconstructionAlgorithm);
astra_clear;
clearvars -except recon

end

