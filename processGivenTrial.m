function [eyetrace, rawFrames, procFrames]=processGivenTrial(data, metadata, thresh, calib, f, w)

eyetrace=zeros(1,length(f));
rawFrames = {};
procFrames = {};
for i=1:f
    wholeframe=data(:,:,1,i);   % make it a grayscale image in case it's not (this assumes all color channels have roughtly the same value)
    rawFrames{i,1} = wholeframe;
    binimage=medfilt2(wholeframe,[w w]) > thresh*256;
    eyeimage=binimage.*metadata.cam.mask;
    procFrames{i,1} = eyeimage;
    tr=sum(eyeimage(:));
    eyetrace(i)=(tr-calib.offset(1))./calib.scale;
    
    % squash values greater than 1 to 1 because FEC should not be sensitive
    % to different eyelid closednesses
    if eyetrace(i)>1
        eyetrace(i) = 1;
    end
end

end