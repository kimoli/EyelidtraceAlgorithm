% ultimately want to re-threshold this video

cd('L:\users\okim\behavior\OK135\170630\compressed')

% open a video file and apply the threshold to the first frame with a
% median filter
[data,metadata]=loadCompressed('OK135_170630_s01_calib.mp4');

w = 1; % how many pixels around the current pixel should be filtered together
thresh=metadata.cam.thresh; % just set up using the threshold from calibration

[m,n,c,f]=size(data);

%% for the calibration processing, have to do one run through without specific calibration data
calib.scale=1;
calib.offset=[0; 0];

eyetrace=zeros(1,length(f));
for i=1:f
    wholeframe=data(:,:,1,i);   % make it a grayscale image in case it's not (this assumes all color channels have roughtly the same value)
    % binimage=im2bw(medfilt2(wholeframe,[w w]),thresh);
    binimage=medfilt2(wholeframe,[w w]) > thresh*256;
    % binimage=im2bw(wholeframe,thresh);
    eyeimage=binimage.*metadata.cam.mask;
    tr=sum(eyeimage(:));
    % tr=sum(sum(eyeimage));
    eyetrace(i)=(tr-calib.offset(1))./calib.scale;
end

calib=getcalib(eyetrace);

%% second run though eyetrace value extraction, same video but now calibrated
eyetrace=zeros(1,length(f));
rawFrames = {};
filtThreshFrames = {};
for i=1:f
    wholeframe=data(:,:,1,i);   % make it a grayscale image in case it's not (this assumes all color channels have roughtly the same value)
    rawFrames{i,1} = wholeframe;
    % binimage=im2bw(medfilt2(wholeframe,[w w]),thresh);
    binimage=medfilt2(wholeframe,[w w]) > thresh*256;
    % binimage=im2bw(wholeframe,thresh);
    eyeimage=binimage.*metadata.cam.mask;
    filtThreshFrames{i,1} = eyeimage;
    tr=sum(eyeimage(:));
    % tr=sum(sum(eyeimage));
    eyetrace(i)=(tr-calib.offset(1))./calib.scale;
end


%% show a frame from intermedate in baseline, at 50% eyelid closure, and at full eyelid closure
figure
subplot(4,2,1)
imshow(rawFrames{20,1})
title('fr 20')
subplot(4,2,2)
imshow(filtThreshFrames{20,1})
title('fr 20')

subplot(4,2,3)
imshow(rawFrames{54,1})
title('fr 54')
subplot(4,2,4)
imshow(filtThreshFrames{54,1})
title('fr 54')

subplot(4,2,5)
imshow(rawFrames{59,1})
title('fr 59 - experimenter says closed')
subplot(4,2,6)
imshow(filtThreshFrames{59,1})
title('fr 59')

subplot(4,2,7)
imshow(rawFrames{84,1})
title('fr 84 - algo says closed')
subplot(4,2,8)
imshow(filtThreshFrames{84,1})
title('fr 84')

% based on these frames, might be reasonable to show frames 50-60 for
% viewer appraisal

%% try showing frames 50:2:60 for viewer to appraise
figure
subplot(3,6,1)
imshow(rawFrames{50,1})
title('50')
subplot(3,6,7)
imshow(filtThreshFrames{50,1})

subplot(3,6,2)
imshow(rawFrames{52,1})
title('52')
subplot(3,6,8)
imshow(filtThreshFrames{52,1})

subplot(3,6,3)
imshow(rawFrames{54,1})
title('54')
subplot(3,6,9)
imshow(filtThreshFrames{54,1})

subplot(3,6,4)
imshow(rawFrames{56,1})
title('56')
subplot(3,6,10)
imshow(filtThreshFrames{56,1})

subplot(3,6,5)
imshow(rawFrames{58,1})
title('58')
subplot(3,6,11)
imshow(filtThreshFrames{58,1})

subplot(3,6,6)
imshow(rawFrames{60,1})
title('60')
subplot(3,6,12)
imshow(filtThreshFrames{60,1})

subplot(3,6, [13,14,15,16,17,18])
hold on
plot([52 52], [0 1], 'Color', [0 0 0], 'LineStyle', ':')
plot([54 54], [0 1], 'Color', [0 0 0], 'LineStyle', ':')
plot([56 56], [0 1], 'Color', [0 0 0], 'LineStyle', ':')
plot([58 58], [0 1], 'Color', [0 0 0], 'LineStyle', ':')
plot([50:60], eyetrace(50:60))


%% try to use a different threshold and see what looks different
thresh = 0.5;

calib.scale=1;
calib.offset=[0; 0];

eyetrace=zeros(1,length(f));
for i=1:f
    wholeframe=data(:,:,1,i);   % make it a grayscale image in case it's not (this assumes all color channels have roughtly the same value)
    % binimage=im2bw(medfilt2(wholeframe,[w w]),thresh);
    binimage=medfilt2(wholeframe,[w w]) > thresh*256;
    % binimage=im2bw(wholeframe,thresh);
    eyeimage=binimage.*metadata.cam.mask;
    tr=sum(eyeimage(:));
    % tr=sum(sum(eyeimage));
    eyetrace(i)=(tr-calib.offset(1))./calib.scale;
end

calib=getcalib(eyetrace);

eyetrace2=zeros(1,length(f));
rawFrames = {};
filtThreshFrames2 = {};
for i=1:f
    wholeframe=data(:,:,1,i);   % make it a grayscale image in case it's not (this assumes all color channels have roughtly the same value)
    rawFrames2{i,1} = wholeframe;
    % binimage=im2bw(medfilt2(wholeframe,[w w]),thresh);
    binimage=medfilt2(wholeframe,[w w]) > thresh*256;
    % binimage=im2bw(wholeframe,thresh);
    eyeimage=binimage.*metadata.cam.mask;
    filtThreshFrames2{i,1} = eyeimage;
    tr=sum(eyeimage(:));
    % tr=sum(sum(eyeimage));
    eyetrace2(i)=(tr-calib.offset(1))./calib.scale;
end

figure
subplot(3,6,1)
imshow(rawFrames2{50,1})
title('50')
subplot(3,6,7)
imshow(filtThreshFrames2{50,1})

subplot(3,6,2)
imshow(rawFrames2{52,1})
title('52')
subplot(3,6,8)
imshow(filtThreshFrames2{52,1})

subplot(3,6,3)
imshow(rawFrames2{54,1})
title('54')
subplot(3,6,9)
imshow(filtThreshFrames2{54,1})

subplot(3,6,4)
imshow(rawFrames2{56,1})
title('56')
subplot(3,6,10)
imshow(filtThreshFrames2{56,1})

subplot(3,6,5)
imshow(rawFrames2{58,1})
title('58')
subplot(3,6,11)
imshow(filtThreshFrames2{58,1})

subplot(3,6,6)
imshow(rawFrames2{60,1})
title('60')
subplot(3,6,12)
imshow(filtThreshFrames2{60,1})

subplot(3,6, [13,14,15,16,17,18])
hold on
plot([52 52], [0 1], 'Color', [0 0 0], 'LineStyle', ':')
plot([54 54], [0 1], 'Color', [0 0 0], 'LineStyle', ':')
plot([56 56], [0 1], 'Color', [0 0 0], 'LineStyle', ':')
plot([58 58], [0 1], 'Color', [0 0 0], 'LineStyle', ':')
plot([50:60], eyetrace2(50:60))
