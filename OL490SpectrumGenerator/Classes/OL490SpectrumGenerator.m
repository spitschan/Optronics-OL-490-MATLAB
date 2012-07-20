%author Jan Winter TU Berlin
%email j.winter@tu-berlin.de

classdef OL490SpectrumGenerator < handle

properties
	targetSpectrum              % this is the requested spectrum to generate OL490 adapted data for
	dimLevels                   % these is (are) the desired dimLevel (s) in range 0 : 1
	ol490AdaptedSpectra         % these are the adapted spectra based on the calibration data for each dimLevel
    filePathToCalibrationData   % filePath to calibration data
end

methods
	%% constructor
	function obj = OL490SpectrumGenerator( targetSpectrum, dimLevels, filePathToCalibrationData )
		obj.targetSpectrum = targetSpectrum;
		obj.dimLevels = dimLevels;
        obj.filePathToCalibrationData = filePathToCalibrationData;
    end
	
	%% get dimLevel for luminance
	%% TODO: implement this - return closest match for requested luminance
	function [ obj, adjustedSpectrum ] = adjustedSpectrumForLuminance( obj, luminance )
	end
	
	%% create adapted spectrum on demand
	%function value = get.ol490AdaptedSpectrum( obj )
    function obj = createAdjustedSpectra( obj )
		
		%if( isempty( obj.ol490AdaptedSpectrum ) )
			%% TODO: add latest code from marian
            
            % load calibration data
            load obj.filePathToCalibrationData;
            
            %create adjustedSpectrum for each dimLevel
            numberOfDimLevels = length( obj.dimLevels );
            ol490AdaptedSpectra = cell( numberOfDimLevels, 1 );
            for currentDimLevelIndex = 1 : numberOfDimLevels
                currentDimLevel = obj.dimLevels( currentDimLevelIndex );
                adjustedSpectrumForDimLevel = spec_adaption( obj.targetSpectrum, spectral_percent, io_real  );
                adjustedSpectrum = OL490AdjustedSpectrum( adjustedSpectrumForDimLevel, currentDimLevel, obj.filePathToCalibrationData  );
                ol490AdaptedSpectra{ currentDimLevelIndex } = adjustedSpectrum;
            end
            
            obj.ol490AdaptedSpectra = ol490AdaptedSpectra;
            
		%end
	
		%value = obj.ol490AdaptedSpectrum;
	end
end
end