% AUTHOR:	Jan Winter, Sandy Buschmann, TU Berlin, FG Lichttechnik,
% 			j.winter@tu-berlin.de, www.li.tu-berlin.de
% LICENSE: 	free to use at your own risk. Kudos appreciated.



classdef OL490SpectrumGenerator < handle
    
    properties
        targetSpectrumCS2000Measurement % original measurement file
        targetSpectrum              % this is the requested spectrum to generate OL490 adapted data for
        desiredLv                   % these is the desired luminance
        ol490Spectrum               % these are the adapted spectra based on the calibration data for each dimLevel
        filePathToCalibrationData   % filePath to calibration data
        %olType                      % target, background or glare OL490
        correctionFactor            % correctionFactor (discrepancy between desired and measured Lv)
        spectralCorrectionFactor    % correctionFactor for discrepandy between desired and measured Spectrum
        ol490Calibration            % calibration data
        ol490Sweep                  % sweep to ol490Spectrum
    end
    
    methods
        %% constructor
        function obj = OL490SpectrumGenerator( targetSpectrumCS2000Measurement, desiredLv, filePathToCalibrationData )
            obj.targetSpectrumCS2000Measurement = targetSpectrumCS2000Measurement;
            obj.targetSpectrum = cs2000Spectrum_2_OL490Spectrum( obj.targetSpectrumCS2000Measurement );
            obj.desiredLv = desiredLv;
            obj.filePathToCalibrationData = filePathToCalibrationData;
            %obj.olType = olType;
            obj.correctionFactor = 1;
            obj.spectralCorrectionFactor = ones( size( obj.targetSpectrum ) );
        end
        
        %% generateSpectrum
        function obj = generateSpectrum( obj )
            
            % prepare data if required
            if( ~obj.ol490Calibration.calibrationDataPrepared )
                obj.ol490Calibration.prepareCalibrationData();
            end
            
            inputOutputMatrix = obj.ol490Calibration.inputOutputCalibrationMatrix;
            interpolatedSpectralDataMatrix = obj.ol490Calibration.interpolatedSpectralDataCalibrationMatrix;
            maxValueOfAllSpectra = obj.ol490Calibration.maxValueOfAllSpectra;
            
            desiredTargetSpectrum = obj.targetSpectrum;
            %experimental: add spectral correction
            %             OL490MAX = 49152;
            %             oldDesiredTargetSpectrum = obj.targetSpectrum .* obj.spectralCorrectionFactor;
            %             desiredTargetSpectrum = oldDesiredTargetSpectrum / max( oldDesiredTargetSpectrum ) * OL490MAX;
            %
            %calc maximum possible spectrum for targetSpectrum
            %ol490Spectrum = OL490Spectrum( obj.targetSpectrum );
            dimFactor = 1;
            [ ol490TargetSpectrum ] = generateOL490Spectrum( ...
                desiredTargetSpectrum,...
                interpolatedSpectralDataMatrix, ...
                inputOutputMatrix, ...
                maxValueOfAllSpectra, ...
                dimFactor...
                );
            
            %now calc spectrum with certain dimFactor to create desired Lv
            %maybe we have to do this iterative
            numberOfIterations = 0;
            maxNumberOfIterations = 10;
            dimFactor = obj.desiredLv / ol490TargetSpectrum.Lv;
            allowedError = 0.01;
            while( numberOfIterations <= maxNumberOfIterations )
                [ ol490TargetSpectrum ] = generateOL490Spectrum( ...
                    desiredTargetSpectrum,...
                    interpolatedSpectralDataMatrix, ...
                    inputOutputMatrix, ...
                    maxValueOfAllSpectra, ...
                    dimFactor...
                    );
                currentError = obj.desiredLv / ol490TargetSpectrum.Lv;
                if( abs( currentError - 1 ) <  allowedError )
                    break;
                end
                dimFactor = currentError * dimFactor;
                numberOfIterations = numberOfIterations + 1;
            end
            
            %visualize data
            from = 100;
            to = length( ol490TargetSpectrum.spectrum ) - 100;
            disp( sprintf( 'meanOfSpectrum: %5.0f stdOfSpectrum: %5.1f', mean( ol490TargetSpectrum.spectrum( from : to ) ), std( ol490TargetSpectrum.spectrum( from : to ) ) )  );
            xenonSpectrum = cs2000Spectrum_2_OL490Spectrum(obj.ol490Calibration.cs2000MeasurementCellArray{end} );
            plot( obj.targetSpectrum / max ( obj.targetSpectrum ), 'r');
            hold on;
            plot( ol490TargetSpectrum.spectrum / max ( ol490TargetSpectrum.spectrum ), 'gr');
            plot( xenonSpectrum / max ( xenonSpectrum ), 'b');
            hold off;
            legend( 'target', 'ol490', 'xenon' );
            
            %save spectrum
            obj.ol490Spectrum = ol490TargetSpectrum;
        end
        
        %% prepareSweep
        function prepareSweep( obj, sweepTime, sweepType, sweepMode, sweepSteps, minDimLevelRatio, maxDimLevelRatio )
            obj.ol490Sweep = OL490SweepGenerator( obj, sweepTime, sweepType, sweepMode, sweepSteps, minDimLevelRatio, maxDimLevelRatio );
            obj.ol490Sweep.generateSweep();
        end
        
        %% get.ol490Calibration
        function value = get.ol490Calibration( obj )
            if( isempty( obj.ol490Calibration ) )
                load( obj.filePathToCalibrationData );
                if( exist( 'ol490CalibrationBackground' ) )
                    obj.ol490Calibration = ol490CalibrationBackground;
                elseif( exist( 'ol490CalibrationTarget' ) )
                    obj.ol490Calibration = ol490CalibrationTarget;
                else
                    disp( 'no calibration file found' );
                end
                
                if( ~isempty( obj.ol490Calibration ) )
                fprintf( 'Using calibration file with date: %s\n', obj.ol490Calibration.calibrationDate );
                end
                
            end
            value = obj.ol490Calibration;
        end
        
        %% documentSpectralVariance
        function documentSpectralVariance( obj )
            
            % measure spectrum via CS2000
            disp( 'measuring' );
            CS2000_initConnection();
            [message1, message2, actualCS2000Measurement, colorimetricNames] = CS2000_measure();
            CS2000_terminateConnection();
            
            %prepare save
            currentTimeString = datestr( now, 'dd-mmm-yyyy_HH_MM_SS' );
            
            %normalize data
            obj.targetSpectrumCS2000Measurement.spectralData = obj.targetSpectrumCS2000Measurement.spectralData / max( obj.targetSpectrumCS2000Measurement.spectralData );
            actualCS2000Measurement.spectralData = actualCS2000Measurement.spectralData / max( actualCS2000Measurement.spectralData );
            
            figure();
            plot( obj.targetSpectrumCS2000Measurement, 'r' );
            hold on;
            plot( actualCS2000Measurement, 'gr' );
            hold off;
            legend( 'target', 'actual'  );
            %ylabel( 'L_{e,rel}(\lambda)' );
            y = ylabel('$$\mbox{L}_{e,rel}(\lambda)$$');
            set(y,'Interpreter','LaTeX','FontSize',14)
            %save variable to mat file which will be overwritten every time
            %fileName = sprintf( 'targetSpectralVariance_%s.mat', currentTimeString );
            %save( fileName, 'actualCS2000Measurement' );
            luminanceText = sprintf( 'Lv,act = %3.3f cd/m^2', actualCS2000Measurement.colorimetricData.Lv );
            luminanceTextRef = sprintf( 'Lv,tar = %3.3f cd/m^2', obj.desiredLv );
            t=text( 0.1, 0.1, luminanceText, 'Units', 'normalized' );
            t=text( 0.1, 0.2, luminanceTextRef, 'Units', 'normalized' );
            set( gca, 'YScale', 'lin' );
            disp( sprintf( 'measured luminance: %3.3f cd/m^2', actualCS2000Measurement.colorimetricData.Lv ) );
            
            actualMeasurement = cs2000Spectrum_2_OL490Spectrum( actualCS2000Measurement );
            relativeMeasurementSpectrum = actualMeasurement / max( actualMeasurement );
            relativeTargetSpectrum = obj.targetSpectrum / max( obj.targetSpectrum );
            obj.spectralCorrectionFactor = relativeMeasurementSpectrum ./ relativeTargetSpectrum;
            obj.correctionFactor = 1 / ( actualCS2000Measurement.colorimetricData.Lv / obj.desiredLv );
            disp( sprintf( 'correctionFactor: %1.2f', obj.correctionFactor ) );
        end
    end
end