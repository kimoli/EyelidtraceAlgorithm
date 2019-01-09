function [calib]=processCalibTrial(rawFrames, metadata, thresh, f, w, baslinecalibtrial, varargin)



eyetrace=zeros(1,length(f));
tr = nan(1,f);
for i=1:f
    binimage=medfilt2(rawFrames{i,1},[w w]) > thresh*256;
    eyeimage=binimage.*metadata.cam.mask;
    tr(i)=sum(eyeimage(:));
    eyetrace(i)=(tr(i)-0)./1;
end

rodEffective = getappdata(0, 'rodEffective');
rodMasks = getappdata(0, 'rodMasks');

if ~isempty(rodEffective)
    [r, c] = size(rodEffective);
    for m = 1:r
        rodStart = rodEffective(m,1);
        if rodStart == 0
            rodStart = -1;
        end
        rodStop = rodEffective(m,2);
        if rodStop == 1
            rodStop = 5;
        end
        %disp(['......ROD from ', num2str(rodStart), ' to ', num2str(rodStop)])
        for i=1:f
            if eyetrace(i)>= rodStart && eyetrace(i)<= rodStop % only apply the ROD if it is a valid FEC to be doing so
                rawFrames{i,1}(rodMasks{m,1}==1)=255; % in grayscale images, 255 corresponds to white
                %disp(['........',num2str(eyetrace(i))])
                %disp('........ applying ROD mask')
            end
        end
    end
    
    eyetrace=zeros(1,length(f));
    tr = nan(1,f);
    for i=1:f
        binimage=medfilt2(rawFrames{i,1},[w w]) > thresh*256;
        eyeimage=binimage.*metadata.cam.mask;
        tr(i)=sum(eyeimage(:));
        eyetrace(i)=(tr(i)-0)./1;
    end
end

disp(['processCalibTrial tr max:', num2str(max(tr))])
if nargin>6
    disp(['tr value at frame before new offset applied: ', num2str(tr(varargin{1}))])
    maxtrFromCalib = tr(varargin{1}); % need to save this here in case load and process another file to re-establish the offset
end
calibEyetrace = eyetrace; % need to save this here in case another eyetrace gets loaded for resetting the calib.offset

if baslinecalibtrial>0
    disp('non-calib trial being used to esablish calib.offset')
    % change the calibration baseline to the correct one
    trialnum = num2str(baslinecalibtrial);
    while length(trialnum)<3
        trialnum = strcat('0', trialnum);
    end
    
    
    % fetch the trial with the better baseline value
    newbaselinetrialinfo = dir(strcat('*',trialnum,'.mp4'));
    [bldata,~]=loadCompressed(newbaselinetrialinfo.name);
    eyetrace=zeros(1,length(f));
    tr = nan(1,f);
    for i = 1:f
        wholeframe=bldata(:,:,1,i);   % make it a grayscale image in case it's not (this assumes all color channels have roughtly the same value)
        rawFramesNewBL{i,1} = wholeframe;
        binimage=medfilt2(wholeframe,[w w]) > thresh*256;
        eyeimage=binimage.*metadata.cam.mask;
        tr(i)=sum(eyeimage(:));
        eyetrace(i)=(tr(i)-0)./1;
    end
    if ~isempty(rodEffective)
        [r, c] = size(rodEffective);
        for m = 1:r
            rodStart = rodEffective(m,1);
            if rodStart == 0
                rodStart = -1;
            end
            rodStop = rodEffective(m,2);
            if rodStop == 1
                rodStop = 5;
            end
            %disp(['......ROD from ', num2str(rodStart), ' to ', num2str(rodStop)])
            
            for i=1:f
                if eyetrace(i)>= rodStart && eyetrace(i)<= rodStop % only apply the ROD if it is a valid FEC to be doing so
                    rawFramesNewBL{i,1}(rodMasks{m,1}==1)=255; % in grayscale images, 255 corresponds to white
                    %disp(['........',num2str(eyetrace(i))])
                    %disp('........ applying ROD mask')
                end
            end
        end
        
        eyetrace=zeros(1,length(f));
        tr = nan(1,f);
        for i=1:f
            binimage=medfilt2(rawFramesNewBL{i,1},[w w]) > thresh*256;
            eyeimage=binimage.*metadata.cam.mask;
            tr(i)=sum(eyeimage(:));
            eyetrace(i)=(tr(i)-0)./1;
        end
    end
    
    offset=mean(eyetrace(1:40));
    
    if nargin>6
        disp('using provided FEC1 frame and offset')
        calib = getcalib_knowFEC1_givenOffset(calibEyetrace, maxtrFromCalib, offset);
    else
        disp('using offset calculated from non-calib file')
        calib = getcalib_givenOffset(calibEyetrace, offset);
    end
elseif baslinecalibtrial==0
    if nargin>6
        disp('using provided FEC1 frame')
        %disp(['varargin frame ', num2str(varargin{1})])
        calib=getcalib_knowFEC1(calibEyetrace, maxtrFromCalib); % this line gets the calibration values for the day
    elseif nargin == 6
        calib = getcalib(calibEyetrace);
    end
end

disp(['offset: ', num2str(calib.offset)])
disp(['scale: ', num2str(calib.scale)])
disp(['processCalibTrial tr max-offset:', num2str(max(tr)-calib.offset)])

end