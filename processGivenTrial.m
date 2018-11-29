function [eyetrace, procFrames]=processGivenTrial(rawFrames, metadata, thresh, calib, f, w)

eyetrace=zeros(1,length(f));
procFrames = {};
for i=1:f
    binimage=medfilt2(rawFrames{i,1},[w w]) > thresh*256;
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