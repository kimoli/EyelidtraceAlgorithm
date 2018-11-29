function [calib]=processCalibTrial(data, metadata, thresh, f, w, rodEffective, rodMasks)

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

calib=getcalib(eyetrace); % this line gets the calibration values for the day


end