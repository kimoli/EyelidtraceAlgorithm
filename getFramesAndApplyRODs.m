function [rawFrames] = getFramesAndApplyRODs(data, metadata, thresh, calib, f, w)

rawFrames = {};
for i = 1:f
    wholeframe=data(:,:,1,i);   % make it a grayscale image in case it's not (this assumes all color channels have roughtly the same value)
    rawFrames{i,1} = wholeframe;
end
setappdata(0, 'originalFrames', rawFrames)

rodEffective = getappdata(0, 'rodEffective');
rodMasks = getappdata(0, 'rodMasks');

% apply masks if they were made
if ~isempty(rodEffective)
    
    % apply the ROD's based on the eyetraces that were used when the RODs were
    % drawn (derive the eyetrace based on the calibration and threshold
    % values at the time that the RODs were set)
    calib = getappdata(0, 'calibAtRODSetting');
    thresh = getappdata(0, 'threshAtRODSetting');
    
    [eyetrace, procFrames]=processGivenTrial(rawFrames, metadata, thresh, calib, f, w);

    [r, c] = size(rodEffective);
    for m = 1:r
        rodStart = rodEffective(m,1);
        rodStop = rodEffective(m,2);
        for i=1:f
            if eyetrace(i)>= rodStart && eyetrace(i)<= rodStop % only apply the ROD if it is a valid FEC to be doing so
                rawFrames{i,1}(rodMasks{m,1}==1)=255; % in grayscale images, 255 corresponds to white
            end
        end
    end
end

end