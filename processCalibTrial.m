function [calib]=processCalibTrial(rawFrames, metadata, thresh, f, w, baslinecalibtrial, varargin)

eyetrace=zeros(1,length(f));
for i=1:f
    binimage=medfilt2(rawFrames{i,1},[w w]) > thresh*256;
    eyeimage=binimage.*metadata.cam.mask;
    tr(i)=sum(eyeimage(:));
    eyetrace(i)=(tr(i)-0)./1;
end
disp(['processCalibTrial tr max:', num2str(max(tr))])

if baslinecalibtrial>0
    
    % change the calibration baseline to the correct one
    trialnum = num2str(baslinecalibtrial);
    while length(trialnum)<3
        trialnum = strcat('0', trialnum);
    end
    
    % fetch the trial with the better baseline value
    newbaselinetrialinfo = dir(strcat('*',trialnum,'.mp4'));
    [bldata,~]=loadCompressed(newbaselinetrialinfo.name);
    eyetrace=zeros(1,length(f));
    for i = 1:f
        wholeframe=bldata(:,:,1,i);   % make it a grayscale image in case it's not (this assumes all color channels have roughtly the same value)
        binimage=medfilt2(wholeframe,[w w]) > thresh*256;
        eyeimage=binimage.*metadata.cam.mask;
        tr=sum(eyeimage(:));
        eyetrace(i)=(tr-0)./1;
    end
    offset=mean(eyetrace(1:40));
    
    if nargin>6
        calib = getcalib_knowFEC1_givenOffset(eyetrace, varargin{1}, offset);
    else
        calib = getcalib_givenOffset(eyetrace, offset);
    end
elseif baslinecalibtrial==0
    if nargin>6
        %disp(['varargin frame ', num2str(varargin{1})])
        calib=getcalib_knowFEC1(eyetrace, varargin{1}); % this line gets the calibration values for the day
    elseif nargin == 6
        calib = getcalib(eyetrace);
    end
end

disp(['offset: ', num2str(calib.offset)])
disp(['scale: ', num2str(calib.scale)])
disp(['processCalibTrial tr max-offset:', num2str(max(tr)-calib.offset)])

end