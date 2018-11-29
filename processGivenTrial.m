function [eyetrace, rawFrames, procFrames]=processGivenTrial(data, metadata, thresh, calib, f, w, rodEffective, rodMasks)

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


if ~isempty(rodEffective)
    [r,c] = size(rodEffective);
    for m = 1:r
        neweyetrace=zeros(1,length(f));
        rodStart = rodEffective(m,1);
        rodStop = rodEffective(m,2);
        
        for i=1:f
            if eyetrace(i)>= rodStart && eyetrace(i)<= rodStop % only apply the ROD if it is a valid FEC to be doing so
                procFrames{i,1}(rodMasks{m,1}==1)=1;
                tr=sum(procFrames{i,1}(:));
                neweyetrace(i)=(tr-calib.offset(1))./calib.scale;
                
                % squash values greater than 1 to 1 because FEC should not be sensitive
                % to different eyelid closednesses
                if neweyetrace(i)>1
                    neweyetrace(i) = 1;
                end
            else
                neweyetrace(i) = eyetrace(i);
            end
        end
    end
    eyetrace = neweyetrace;
end

end