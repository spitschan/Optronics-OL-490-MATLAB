function [ ol490TargetSpectrum ] = generateOL490Spectrum( targetSpectrum, interpolatedSpectralDataCalibrationMatrix, inputOutputCalibrationMatrix, interpolatedMaxValuesForDimLevelSpectra, dimFactor )
% generateOL490Spectrum
%   targetSpectrum - requested spectrum, vector with 1024 columns
%   interpolatedSpectralDataCalibrationMatrix - matrix generated with OL490-class
%   inputOutputCalibrationMatrix       - matrix generated with OL490-class
%   dimFactor     - number between 0 and 1 [p.e. 0.543], default is 1
%   ol490Spectrum    - adapted vector with ol490-values, from 0 till 49152
%   interpolatedMaxValuesForDimLevelSpectra     - values to recalculate real value of percentual value (needed for Lv)

OL490MAX = 49152;
if nargin < 5
    dimFactor = 1;
else
    if dimFactor > 1
        dimFactor = 1;
    end
end

% targetSpectrum,
% interpolatedSpectralDataCalibrationMatrix,
% inputOutputCalibrationMatrix,
% interpolatedMaxValuesForDimLevelSpectra,
% dimFactor

%userSpectrum preparation
%list with smallest value differences between
%interpolatedSpectralDataCalibrationMatrix and targetSpectrum
%between 400nm - 680 nm values are necessary for adaption, the other values
%will influence the final adaption negatively too much (51 equals 20nm and 256 equals 100nm)
targetSpectrumRelative = targetSpectrum ./ OL490MAX;
numberOfSpectralLines = size( targetSpectrum );
numberOfDimLevels = size( interpolatedSpectralDataCalibrationMatrix, 1 );
indexFromSpectralLine = 51;     % 400nm
indexToSpectralLine = ( numberOfSpectralLines - 256 );      % 680nm
numberOfInterestingSpectralLines = length( indexFromSpectralLine : indexToSpectralLine );
smallestDifferencesBetweenTargetAndCalibrationSpectrum = zeros( numberOfInterestingSpectralLines, 1 );

%find minimum between targetSpectrum and dimLevelCalibration
for spectralLineIndex = indexFromSpectralLine : indexToSpectralLine
    currentDimLevels = interpolatedSpectralDataCalibrationMatrix( :, spectralLineIndex );
    currentTargetSpectralLine = targetSpectrumRelative( spectralLineIndex );
    diffTargetSpectralLine2CalibrationDimValue = abs( currentDimLevels - currentTargetSpectralLine );
    smallestDifference = min( diffTargetSpectralLine2CalibrationDimValue );
    smallestDifferenceTarget2CalibrationDimValue( spectralLineIndex - indexFromSpectralLine + 1 ) = smallestDifference;
end

% what is this for???
maxDifference = max( smallestDifferenceTarget2CalibrationDimValue );
targetSpectrumRelative = (( 1 - maxDifference) * dimFactor ) .* targetSpectrumRelative ;

% targetSpectrum adaption
%searches the smallest differences between the user value and the real
%spectral values from the 0L490 and consider the Input/Output-function
%from the OL490

spectralRadianceData = zeros( size( targetSpectrumRelative, 1 ), 1 ); % we save the radiance values for the OL490 dim value
ol490DimValueSpectrumCorrected = zeros( size( targetSpectrumRelative, 1 ), 1 );
for spectralLineIndex = 1 : numberOfSpectralLines
    
    %find best dimValue for current spectral line
    currentDimLevels = interpolatedSpectralDataCalibrationMatrix( :, spectralLineIndex );
    currentTargetSpectralLine = targetSpectrumRelative( spectralLineIndex );
    diffTargetSpectralLine2CalibrationDimValue = abs( currentDimLevels - currentTargetSpectralLine );
    [smallestDifference, indexOfSmallestDifference] = min( diffTargetSpectralLine2CalibrationDimValue );
    smallestDifferenceTarget2CalibrationDimValue( spectralLineIndex ) = smallestDifference;
    
    %     valueOne = abs( spectralPercent( 1, spectralLineIndex ) - userPercent( spectralLineIndex ) );
    %     valuePointerOne = 1;
    %     for percentPointer = 2 : size( spectralPercent, 1 )
    %         valueTwo = abs( spectralPercent( percentPointer , spectralLineIndex) - userPercent( spectralLineIndex ) );
    %         if (valueTwo < valueOne)
    %             valueOne = valueTwo;
    %             valuePointerOne = percentPointer;
    %         end
    %     end
    ol490DimValueForSpectralLine = ( indexOfSmallestDifference - 1 ) / 1000;
    %helper = ( valuePointerOne - 1) / 1000;
    
    currentInputOutputCalibrationDimValues = inputOutputCalibrationMatrix( :, spectralLineIndex );
    diffTargetSpectralLine2InputOutputCalibrationDimValue = abs( ol490DimValueForSpectralLine - currentInputOutputCalibrationDimValues );
    [smallestDifference, indexOfSmallestDifference] = min( diffTargetSpectralLine2InputOutputCalibrationDimValue );
    %smallestDifferencesBetweenTargetAndCalibrationSpectrum( spectralLineIndex ) = smallestDifference;
    
    %     valueOne = abs( helper - ioReal( 1, spectralLineIndex ) );
    %     valuePointerTwo = 1;
    %     for percentPointer = 2 : size(ioReal,1)
    %         valueTwo = abs(helper - ioReal( percentPointer, nmPointer));
    %         if (valueTwo < valueOne)
    %             valueOne = valueTwo;
    %             valuePointerTwo = percentPointer;
    %         end
    %     end
    
    ol490DimValueForSpectralLineCorrected = ( indexOfSmallestDifference - 1 ) / 1000 * OL490MAX;
    
    %helper = ( ( valuePointerTwo - 1) / 1000) * OL490MAX;
    %ol490DimValueSpectrumCorrected( spectralLineIndex ) = str2double( sprintf( '%0.0f', ol490DimValueForSpectralLineCorrected) );
    ol490DimValueSpectrumCorrected( spectralLineIndex ) = round( ol490DimValueForSpectralLineCorrected );
    
    %get spectral radiance of dimValue
    %spectralRadianceData( nmPointer ) = spectralPercent( valuePointerOne, nmPointer ) * maxValues( valuePointerOne );

end
%ol490Spectrum = realValues';

%hack:
ol490DimValueSpectrumCorrected(1:51) = 0;
ol490DimValueSpectrumCorrected = ol490DimValueSpectrumCorrected / max(ol490DimValueSpectrumCorrected) * OL490MAX;

%calc luminance for current spectrum
Lv = calcPhotopicLuminanceFromSpectrum( spectralRadianceData' );
disp( sprintf( 'luminance of spectrum %3.3f cd/m^2', Lv ) );

ol490TargetSpectrum = OL490TargetSpectrum( ol490DimValueSpectrumCorrected', dimFactor, Lv );



