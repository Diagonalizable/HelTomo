function save_ct_project(CtData, varargin)
%SAVE_CT_PROJECT Save X-ray tomography project in external .mat file.
%   save_ct_project(CtData) saves the data structure given in ''CtData'', 
%   containing the sinogram and imaging parameters of a CT scan, into an
%   external .mat file. The output filename will be generated automatically
%   from the CT metadata.
%
%   save_ct_project(ctData, filename) saves the data structure given in
%   ''CtData'' into an external .mat file which will be named as the input
%   parameter ''filename''. If the parameter is an empty string, the output 
%   filename will be generated automatically from the CT scan metadata.
%
%   This function is part of the HelTomo Toolbox, and was created primarily
%   for use with CT data measured in the Industrial Mathematics Computed 
%   Tomography Laboratory at the University of Helsinki.
%
%   Alexander Meaney, University of Helsinki
%   Created:            28.6.2019
%   Last edited:        2.8.2028


% Validate input parameters

if length(varargin) > 1
    error('Too many input parameters.');
end

if length(varargin) == 1
    if ~ischar(varargin{1})
        error('Second input parameters must be a character array.');
    end
end

% Create output filename

if length(varargin) == 1 && length(varargin{1}) > 1
    outputFilename = varargin{1};
else
    if length(CtData.parameters.projectName) < 1
        firstPart = 'unknown';
    else
        firstPart = CtData.parameters.projectName;
    end

    outputFilename = strcat(firstPart, 'ct_project_', ...
                            lower(CtData.type), '_binning_', ...
                            num2str(CtData.parameters.binningPost));
end

% Write to disk

fprintf('Saving CT project... ');

save(outputFilename, 'CtData', '-v7.3');

fprintf('CT project saved as %s.mat.\n', outputFilename);

end

