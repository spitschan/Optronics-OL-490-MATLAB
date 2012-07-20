%author Jan Winter TU Berlin
%email j.winter@tu-berlin.de

classdef OL490AdjustedSpectrum < handle
    %% properties
    properties
        spectrum                    % handle to OL490
        dimValue                    % number of repetitions per light level
        luminance                   % calculated luminance based on calibration data
        filePathToCalibrationData   % filePath to calibration data
    end
    methods
        %% constructor
        function obj = OL490AdjustedSpectrum( spectrum, dimValue, filePathToCalibrationData )
            obj.spectrum = spectrum;
            obj.dimValue = dimValue;
            obj.filePathToCalibrationData = filePathToCalibrationData;
        end
        
        %% calculate luminances
        
        function value = get.luminance( obj )
		
		if( isempty( obj.luminance ) )			
		%% TODO: implement this calculate this based on the calibration
        %% data
        %load calibration data 
        load obj.filePathToCalibrationData;
        
		end
	
		value = obj.luminance;
	end
        
    end
end