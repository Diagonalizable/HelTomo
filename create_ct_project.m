function [ CtData ] = create_ct_project(projectName, reconMode, varargin)
%CREATE_CT_PROJECT Pre-process tomography data for reconstruction
%   CtData = create_ct_project(projectName, reconMode) processes a set of 
%   X-ray projection images and creates a data structure which contains the
%   sinogram(s) and imaging parameters of a CT scan. A scan parameter txt 
%   file specified by ''projectName'' must exist for the project and it 
%   should be in the  format specified by the example file 
%   'ct_scan_parameters_template.txt'. The input parameter ''projectName'' 
%   should also be the initial part of the filename of all the project 
%   files.
%
%   The input parameter ''reconMode'' determines whether a 2D or 3D 
%   sinogram is created, designated by ''2D'' and ''3D'', respectively. If 
%   a 3D sinogram is created, the slice orientation follows the convention 
%   of the ASTRA Tomography Toolbox.
%
%   ctData = create_ct_project(projectName, reconMode, argumentName, 
%   argumentValue) calls the function using the optional input parameter 
%   pairs specified by ''ArgumentName'' and ''ArgumentValue''. The 
%   following optional parameters exist:
%
%   'FreeRay'   This argument determines the area that is used to determine
%               the intensity of the X-ray when it passes unattenuated to
%               the detector. The format is [row1 row2 column2 column2].
%               The default values are [1 128 1 128]. This only applied
%               data collected using an energy-integrating detector.
%
%   'CorFix'    This argument corrects for a misplaced center of rotation. 
%               The value must an integer. Center of rotation correction 
%               shifts the projections by a number of pixels equal to the 
%               argument value, using circular boundary conditions. A 
%               positive value shifts the projections right and a negative
%               value shifts the projections left. The default value is 0 
%               (no correction). 
%
%   'Binning'   This argument specifies a binning factor applied to the
%               projection images. Binning increases signal-to-noise ratio
%               but reduces spatial resolution. The value must be a member 
%               of the set {1, 2, 4, 8, 16, 32}. The default value is 1 (no
%               binning).
%
%   'Save'      This argument specifies whether the created data structure
%               is saved into a .mat file in the current folder. The 
%               possible values are 1 (yes) and 0 (no). The default value 
%               is 0.
%
%   'Filename'  This argument specifies the name of the .mat file the data
%               structure will be saved into. Specifying this input 
%               parameter will have no effect if the 'Save' input 
%               parameter has the value 0. If this input parameter is not 
%               specified, a filename will be generated automatically.
%
%   NOTE: center of rotation correction is performed before binning.
%
%   NOTE: binning is performed before extracting the center row of the
%   projections for a 2D sinogram.
%
%   All measures of distance in the CT scan parameters are given in 
%   millimeters, and all angles are in degrees.
%
%   This function is part of the HelTomo Toolbox, and was created primarily
%   for use with CT data measured in the Industrial Mathematics Computed 
%   Tomography Laboratory at the University of Helsinki.
%
%   Alexander Meaney, University of Helsinki
%   Created:            23.10.2019
%   Last edited:        4.8.2022


% Process optional input parameters

% Default values
freeRay         = [1 128 1 128];
corFix          = 0;
binning         = 1;
saveToDisk      = 0;
outputFilename  = '';   

% The output filename will be automatically generated later in the code if 
% it is not explicitly given by the user.

for iii = 1 : 2 : length(varargin)
    switch lower(varargin{iii})
        case 'freeray'
            freeRay = varargin{iii + 1};
        case 'corfix'
            corFix = varargin{iii + 1};
        case 'binning'
            binning = varargin{iii + 1};
        case 'save'
            saveToDisk = varargin{iii + 1};
        case 'filename'
            outputFilename = varargin{iii + 1};
        otherwise
            error('Unknown input parameter name: %s.', varargin{iii});
    end
end

% Validate input parameters

if ~ismember(upper(reconMode), {'2D' '3D'})
    error('Input parameter ''reconMode'' must be ''2D'' or ''3D''.');
end

if ~isnumeric(freeRay) || ~isequal(size(freeRay), [1 4]) || sum(freeRay > 0) ~= 4
    error('Input parameter ''FreeRay'' must be a 1x4 matrix with positive integer elements.');
end

if freeRay(1) >= freeRay(2) || freeRay(3) >= freeRay(4)
    error('Input parameter ''FreeRay'' must be of the form [row1 row2 column1 column2], where row1 < row2 and column1 < column2.'); 
end

if ~isscalar(corFix) || floor(corFix) ~= corFix 
    error('Input parameter ''CorFix'' must be an integer.');
end

if ~isscalar(binning) || ~ismember(binning, [1 2 4 8 16 32])
    error('Input parameter ''Binning'' must be a member of the set {1, 2, 4, 8, 16, 32}.');
end

if ((freeRay(2)-freeRay(1)+1)/binning) ~= floor((freeRay(2)-freeRay(1)+1)/binning) || ...
        ((freeRay(4)-freeRay(3)+1)/binning) ~= floor((freeRay(4)-freeRay(3)+1)/binning)
   error('Choose input parameters FreeRay and Binning so that binning does not lead to a non-integer background image size.');
end

if ~ismember(saveToDisk, [0 1])
    error('Input parameter ''Save'' must 1 (save to disk) or 0 (no save).');
end


% Create CT dataset

fprintf('Creating CT project ''%s''.\n', projectName);

% Create empty structure to which all data will be attached
CtData          = struct;
CtData.type     = reconMode;

fprintf('Reading CT scan parameter file... ');

% Read CT scan parameters and metadata
parameterFile   = strcat(projectName, '.txt');
parameters      = read_ct_scan_parameters(parameterFile);

if ~ismember(upper(parameters.detectorType), {'EID'})
    error('Unknown detector type. Expected ''EID'', found: %s.', parameters.detectorType);
end

fprintf('done.\n');


% Energy-integrating detector data

if strcmpi(parameters.detectorType, 'EID')
    fprintf('Found CT scan collected with an energy-integrating X-ray detector.\n')
    fprintf('Determining CT scan parameters and metadata... ');

    % Determine image size from first projection and add to parameters
    filename        = strcat(projectName, '0001.tif');
    I               = imread(filename);
    [rows, cols]    = size(I);

    % Add new fields to parameter data
    
    parameters.detectorRows           = rows;
    parameters.detectorCols           = cols;
    parameters.freeRayAtDetector      = freeRay;
    parameters.binningPost            = binning;
    parameters.pixelSizePost          = parameters.pixelSize * binning;
    parameters.effectivePixelSizePost = parameters.pixelSizePost /...
                                        parameters.geometricMagnification;

    if strcmpi(reconMode, '2D')
        parameters.numDetectorsPost   = cols / binning;
    elseif strcmpi(reconMode, '3D')
        parameters.projectionRows = rows / binning;
        parameters.projectionCols = cols / binning;
    else
        error('Unknown error due to reconstruction mode mismatch.\n.');
    end
    
    fprintf('done.\n');

    % Initialize empty sinogram using ASTRA geometry
    if strcmpi(reconMode, '2D')
        sinogram = zeros(parameters.numberImages, parameters.numDetectorsPost);
        % Center row of projections
        centerRow = (parameters.detectorRows / binning) / 2;
    elseif strcmpi(reconMode, '3D')
        sinogram = zeros(parameters.projectionCols, ...
                         parameters.numberImages, ...
                         parameters.projectionRows);
    else
        error('Unknown error due to reconstruction mode mismatch.\n.');
    end    
   
    % Read each image, compute log transform, and place into sinogram
    fprintf('Creating %s sinogram...\n', CtData.type);
    for iii = 1 : parameters.numberImages
        fprintf('Processing image %d/%d... ', iii, parameters.numberImages);

        % Load image
        filename        = strcat(projectName, sprintf('%04d', iii), '.tif'); 
        I               = double(imread(filename));

        % Extract background intensity area
        background      = I(freeRay(1):freeRay(2), freeRay(3):freeRay(4));

        % Fix misplaced center of rotation, if this option has been used
        if corFix ~= 0
            I = circshift(I, corFix, 2);
        end

        % Execute image binning, if this option has been used
        if binning ~= 1
            I           = bin_pixels(I, binning);
            background  = bin_pixels(background, binning);
        end

        bkgdIntensity   = mean(background(:));    

        % Log-transform of projection
        I = -log( I ./ bkgdIntensity );
        
        % Insert projection data into sinogram
        if strcmpi(reconMode, '2D')
            detectorData = I(centerRow, :);
            sinogram(iii, :) = detectorData;
        elseif strcmpi(reconMode, '3D')
            % Transpose for ASTRA
            I = I';
            sinogram(:, iii, :) = I;
        else
            error('Unknown error due to reconstruction mode mismatch.\n.');
        end   

        fprintf('done.\n');
    end
    fprintf('Sinogram completed.\n');
    
    % Attach sinogram to data structure
    CtData.sinogram = sinogram;
    
else
    
    error('Unknown error due to detector type inconsistency.\n.');
    
end
    
    
% Attach CT scan parameters to data structure
CtData.parameters = parameters;

% Save data structure in file
if saveToDisk == 1
    save_ct_project(CtData, outputFilename);
end

fprintf('CT project creation completed.\n');

end

