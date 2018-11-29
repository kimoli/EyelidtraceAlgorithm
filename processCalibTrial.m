function [calib]=processCalibTrial(rawFrames, metadata, thresh, f, w)

% for calibration processing, have to do one run through without specific calibration data
calib.scale=1;
calib.offset=[0; 0];

eyetrace=zeros(1,length(f));
for i=1:f
    binimage=medfilt2(rawFrames{i,1},[w w]) > thresh*256;
    eyeimage=binimage.*metadata.cam.mask;
    tr=sum(eyeimage(:));
    eyetrace(i)=(tr-calib.offset(1))./calib.scale;
end

calib=getcalib(eyetrace); % this line gets the calibration values for the day


end