function [ ScanParameters ] = read_ct_scan_parameters(filename)
%READ_CT_SCAN_PARAMETERS Read CT scan parameters from .txt file
%   scanParameters = read_ct_scan_parameters(filename) creates a data 
%   structure containing all the relevant parameters and metadata of a 
%   computed tomography scan, but no actual projection data. The parameters
%   are given in a .txt file specified by the ''filename'', and the .txt 
%   file itself should be in the format specified by the file 
%   'ct_scan_parameters_template.txt'.
%
%   All measures of distance in the CT scan parameters are given in 
%   millimeters, and all angles are in degrees.
%
%   This function is part of the HelTomo Toolbox, and was created primarily
%   for use with CT data measured in the Industrial Mathematics Computed 
%   Tomography Laboratory at the University of Helsinki.
%
%   Alexander Meaney, University of Helsinki
%   Created:            28.1.2019
%   Last edited:        2.8.2022


% Verify that the filename given specifies a .txt file
[~, ~, ext] = fileparts(filename);
if ~strcmp(ext, '.txt')
    error('Input must be a .txt file.')
end

% Read raw data from file
f       = fopen(filename, 'r');
rawData = textscan(f, '%s %s', 'delimiter', '=');
fclose(f);

% Create Map from raw data
dataMap = containers.Map(strtrim(rawData{1}), strtrim(rawData{2}));

% Create a struct for the scan parameter data
ScanParameters = struct;

% Read parameters from Map and enter into struct, converting into the 
% suitable data type when necessary. Some scan parameters are compulsory 
% information for CT reconstruction, in which case their presence is 
% checked.

if isKey(dataMap, 'ProjectName')
    ScanParameters.projectName = dataMap('ProjectName');
else
    error('Compulsory field ''ProjectName'' missing in scan parameter file.');
end

if isKey(dataMap, 'Scanner')
    ScanParameters.scanner = dataMap('Scanner');
end

if isKey(dataMap, 'Measurers')
    ScanParameters.measurers = dataMap('Measurers');
end

if isKey(dataMap, 'Date')
    ScanParameters.date = dataMap('Date');
end

if isKey(dataMap, 'DateFormat')
    ScanParameters.dateFormat = dataMap('DateFormat');
end

if isKey(dataMap, 'GeometryType')
    ScanParameters.geometryType = dataMap('GeometryType');
else
    error('Compulsory field ''GeometryType'' missing in scan parameter file.');
end

if isKey(dataMap, 'DistanceSourceDetector')
    ScanParameters.distanceSourceDetector = str2double(dataMap('DistanceSourceDetector'));
else
    error('Compulsory field ''DistanceSourceDetector'' missing in scan parameter file.');
end

if isKey(dataMap, 'DistanceSourceOrigin')
    ScanParameters.distanceSourceOrigin = str2double(dataMap('DistanceSourceOrigin'));
else
    error('Compulsory field ''DistanceSourceOrigin'' missing in scan parameter file.');
end

if isKey(dataMap, 'DistanceUnit')
    ScanParameters.distanceUnit = dataMap('DistanceUnit');
end

% Compute new geometric data field from data and add to scan parameters
ScanParameters.geometricMagnification  = ...
    ScanParameters.distanceSourceDetector / ...
    ScanParameters.distanceSourceOrigin;

if isKey(dataMap, 'NumberImages')
    ScanParameters.numberImages = str2double(dataMap('NumberImages'));
else
    error('Compulsory field ''NumberImages'' missing in scan parameter file.');
end

% Compute angle information and add to scan parameters

if isKey(dataMap, 'AngleFirst')
    angleFirst = str2double(dataMap('AngleFirst'));
else
    error('Compulsory field ''AngleFirst'' missing in scan parameter file.');
end

if isKey(dataMap, 'AngleInterval')
    angleInterval = str2double(dataMap('AngleInterval'));
else
    error('Compulsory field ''AngleInterval'' missing in scan parameter file.');
end    

if isKey(dataMap, 'AngleLast')
    angleLast = str2double(dataMap('AngleLast'));
else
    error('Compulsory field ''AngleLast'' missing in scan parameter file.');
end

angles                  = angleFirst : angleInterval : angleLast;
ScanParameters.angles   = angles;

if isKey(dataMap, 'Detector')
    ScanParameters.detector = dataMap('Detector');
end

if isKey(dataMap, 'DetectorType')
    ScanParameters.detectorType = dataMap('DetectorType');
else
    error('Compulsory field ''DetectorType'' missing in scan parameter file.');
end

if isKey(dataMap, 'Binning')
    ScanParameters.binning = dataMap('Binning');
end

if isKey(dataMap, 'PixelSize')
    ScanParameters.pixelSize = str2double(dataMap('PixelSize'));
else
    error('Compulsory field ''PixelSize'' missing in scan parameter file.');
end

if isKey(dataMap, 'PixelSizeUnit')
    ScanParameters.pixelSizeUnit = str2double(dataMap('PixelSizeUnit'));
end

if isKey(dataMap, 'ExposureTime')
    ScanParameters.exposureTime = dataMap('ExposureTime');
end

if isKey(dataMap, 'ExposureTimeUnit')
    ScanParameters.exposureTimeUnit = dataMap('ExposureTimeUnit');
end

if isKey(dataMap, 'Tube')
    ScanParameters.tube = dataMap('Tube');
end

if isKey(dataMap, 'Target')
    ScanParameters.target = dataMap('Target');
end

if isKey(dataMap, 'Voltage')
    ScanParameters.voltage = dataMap('Voltage');
end

if isKey(dataMap, 'VoltageUnit')
    ScanParameters.voltageUnit = dataMap('VoltageUnit');
end

if isKey(dataMap, 'Current')
    ScanParameters.current = dataMap('Current');
end

if isKey(dataMap, 'CurrentUnit')
    ScanParameters.currentUnit = dataMap('CurrentUnit');
end

if isKey(dataMap, 'XRayFilter')
    ScanParameters.xRayFilter = dataMap('XRayFilter');
end

if isKey(dataMap, 'XRayFilterThickness')
    ScanParameters.xRayFilterThickness = dataMap('XRayFilterThickness');
end

if isKey(dataMap, 'XRayFilterThicknessUnit')
    ScanParameters.xRayFilterThicknessUnit = dataMap('XRayFilterThicknessUnit');
end

end
