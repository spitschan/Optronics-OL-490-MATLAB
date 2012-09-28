
%load 'C:\Dokumente und Einstellungen\Buschmann\Desktop\spektren\kaarst_47_direkt.mat'
load 'C:\Dokumente und Einstellungen\jaw\Desktop\spektren\neuss_HPS_direkt.mat'
%load HPS_350_09_26.mat
%m = measurements{1};
s=cs2000Spectrum_2_OL490Spectrum(m);
ol490Spec = OL490SpectrumGenerator( s, 1.0, 'C:\Dokumente und Einstellungen\jaw\Desktop\Development\calibrationData.mat' )
ol490Spec.generateSpectrum();


ol490Controller = OL490Controller( 0, 3 );
ol490Controller.init();
ol490Controller.openShutter();
ol490Controller.sendSpectrum( ol490Spec.ol490Spectrum.spectrum );


ec = ExperimentController();
ec.calib_background();


ec = ExperimentController();
ec.init();
ec.sendFullOutputToBackgroundOL490();
im1 = zeros( 684, 608, 3 );
im1 (300:380, 300:380, :) = 255;
imwrite( im1, 'im1.bmp' );
imFile1 = fopen( 'im1.bmp' );
imData1 = fread( imFile1, inf, 'uchar' );
fclose( imFile1 );
%ec.initLightCrafter();
ec.sendImage( imData1 );
ec.sendPositionCalibrationImage();
ec.cleanup();
