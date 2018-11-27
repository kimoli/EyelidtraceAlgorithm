function [calib]=processCalibTrial(data, metadata, thresh, f, w)

% for calibration processing, have to do one run through without specific calibration data
calib.scale=1;
calib.offset=[0; 0];

eyetrace=zeros(1,length(f));
for i=1:f
    wholeframe=data(:,:,1,i);   % make it a grayscale image in case it's not (this assumes all color channels have roughtly the same value)
    binimage=medfilt2(wholeframe,[w w]) > thresh*256;
    eyeimage=binimage.*metadata.cam.mask;
    tr=sum(eyeimage(:));
    eyetrace(i)=(tr-calib.offset(1))./calib.scale;
end

calib=getcalib(eyetrace); % this line gets the calibration values for the day


end