function [rawFrames] = getFramesAndApplyRODs(data, metadata, thresh, calib, f, w)

rawFrames = {};
for i = 1:f
    wholeframe=data(:,:,1,i);   % make it a grayscale image in case it's not (this assumes all color channels have roughtly the same value)
    rawFrames{i,1} = wholeframe;
end
setappdata(0, 'originalFrames', rawFrames)
[eyetrace, procFrames]=processGivenTrial(rawFrames, metadata, thresh, calib, f, w);

rodEffective = getappdata(0, 'rodEffective');
rodMasks = getappdata(0, 'rodMasks');

% apply masks if they were made
if ~isempty(rodEffective)
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