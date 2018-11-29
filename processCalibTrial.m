function [calib]=processCalibTrial(rawFrames, metadata, thresh, f, w, varargin)

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

if nargin>5
    calib=getcalib_knowFEC1(eyetrace, varargin{1}); % this line gets the calibration values for the day
else
    calib = getcalib(eyetrace);
end


end