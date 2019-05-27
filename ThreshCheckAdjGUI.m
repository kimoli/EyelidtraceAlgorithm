% for this to work right now, you need to start in the compressed video
% directory of the day you want to process

function varargout = ThreshCheckAdjGUI(varargin)
% THRESHCHECKADJGUI MATLAB code for ThreshCheckAdjGUI.fig
%      THRESHCHECKADJGUI, by itself, creates a new THRESHCHECKADJGUI or raises the existing
%      singleton*.
%
%      H = THRESHCHECKADJGUI returns the handle to a new THRESHCHECKADJGUI or the handle to
%      the existing singleton*.
%
%      THRESHCHECKADJGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in THRESHCHECKADJGUI.M with the given input arguments.
%
%      THRESHCHECKADJGUI('Property','Value',...) creates a new THRESHCHECKADJGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ThreshCheckAdjGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ThreshCheckAdjGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ThreshCheckAdjGUI

% Last Modified by GUIDE v2.5 29-Nov-2018 18:00:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ThreshCheckAdjGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ThreshCheckAdjGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ThreshCheckAdjGUI is made visible.
function ThreshCheckAdjGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ThreshCheckAdjGUI (see VARARGIN)

% Choose default command line output for ThreshCheckAdjGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% set up potential variables for later in the code
setappdata(0, 'rodMasks', {})
setappdata(0, 'rodPatches', {})
setappdata(0, 'rodEffective', [])
setappdata(0, 'FEC1Frame', [])
setappdata(0, 'calibAtRODSetting', [])
setappdata(0, 'threshAtRODSetting', [])

% tell user to select directory
dname = uigetdir('L:\\users\okim\behavior', 'Select an animal and a day.'); % this assumes that the user is working on ALBUS
cd(dname)

% check the trialdata.mat file to determine if you need to set a different
% calib baseline value
loadMe = dir('trialdata.mat');
baslinecalibtrial = 0;
if ~isempty(loadMe)
    load(loadMe.name)
    baselines = nan(size(trials.eyelidpos,1),1);
    for i = 1:size(trials.eyelidpos,1)-1 % do not check the calibration trial, which is the last trial in the structure
        baselines(i,1) = mean(trials.eyelidpos(i,1:40));
    end
    [mval, idx] = min(baselines);
    if mval<0
        baslinecalibtrial = idx;
        disp('FOUND BASELINE<0')
    end
end
setappdata(0, 'baslinecalibtrial', baslinecalibtrial)
setappdata(0, 'trialdata', trials)
setappdata(0, 'newTrialdata', [])

goHere = strcat(dname, '\compressed');
cd(goHere)


% start working on the calibration file
calibfileinfo = dir('*calib.mp4');
file = calibfileinfo.name;

disp('Loading calibration file')
[data,metadata]=loadCompressed(file);
% save calibration trial information to the hidden figure so you can keep
% using it to derive the calibration data
setappdata(0, 'calibData', data)
setappdata(0, 'calibMetadata', metadata)
setappdata(0, 'currentData', data)
setappdata(0, 'currentMetadata', metadata)

w = 1; % how many pixels around the current pixel should be filtered together
setappdata(0, 'w', w) % saving this now in case it gets changed at a later date as it will apply throughout the code and I don't want it to be set in multiple locations

thresh=metadata.cam.thresh; % just set up using the threshold from calibration
setappdata(0, 'originalThresh', thresh) % saving this to hidden figure as it might be useful to revert back to later

[m,n,c,f]=size(data);

disp('Processing calibration file')
% for calibration processing, have to do one run through without specific calibration data

for i = 1:f
    wholeframe=data(:,:,1,i);   % make it a grayscale image in case it's not (this assumes all color channels have roughtly the same value)
    rawFrames{i,1} = wholeframe;
end
setappdata(0, 'originalFrames', rawFrames)
setappdata(0, 'calibFrames', rawFrames)
setappdata(0, 'rawFrames', rawFrames)

disp(['Baseline trial:', num2str(baslinecalibtrial)])
calib=processCalibTrial(rawFrames, metadata, thresh, f, w, baslinecalibtrial); % this line gets the calibration values for the day
setappdata(0,'calib',calib) % save calib to the hidden figure so that it is accessible to all parts of the GUI
setappdata(0,'origcalib',calib) % save a copy of the original calibration so that you can revert back to it later if the threshold gets changed

% second run though eyetrace value extraction, same video but now calibrated
[eyetrace, procFrames]=processGivenTrial(rawFrames, metadata, thresh, calib, f, w);

% save the frames and the eyetrace to the hidden figure
setappdata(0, 'procFrames', procFrames)
setappdata(0, 'eyetrace', eyetrace)

% start up the rest of the GUI
disp('Initializing GUI display')

startframe = 1; % making this a variable in case I want to change it later
setappdata(0, 'startframe', startframe)

origTrace = trials.eyelidpos(end,:);
initThreshCheckAdjGUIDisplay(startframe, handles, rawFrames, procFrames, ...
    eyetrace, thresh, file, origTrace, [])

disp('GUI setup complete')



% UIWAIT makes ThreshCheckAdjGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ThreshCheckAdjGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function FrameSlider_Callback(hObject, eventdata, handles)
% hObject    handle to FrameSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% update the displayed frame number
frameSelected = int32(get(handles.FrameSlider, 'Value'));
set(handles.FrameNumber, 'string', num2str(frameSelected))

% update the displayed point on the eyetrace plot
axes(handles.eyelidtracePlot)
eyetrace = getappdata(0, 'eyetrace');
a = getappdata(0, 'framePointer');
delete(a)
hold on
a = scatter([frameSelected], eyetrace(frameSelected), 'MarkerEdgeColor', [0 0 1]);
setappdata(0, 'framePointer', a)

% update the frames shown
rawFrames = getappdata(0, 'rawFrames');
axes(handles.rawFrame)
imshow(rawFrames{frameSelected,1})

procFrames = getappdata(0, 'procFrames');
axes(handles.MaskedFilteredThreshdFrame)
imshow(procFrames{frameSelected,1})

% update displayed FEC value
set(handles.outputFEC, 'string', num2str(eyetrace(frameSelected)))

% put the ROD patch(es) on the top layer if it exists
rodPatches = getappdata(0, 'rodPatches');
if ~isempty(rodPatches)
    for rp = 1:length(rodPatches)
        XY = rodPatches{rp,1};
        patch(XY(:,1),XY(:,2),'g','FaceColor','none','EdgeColor','g','Tag','rodpatch');
    end
end



% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function FrameSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FrameSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function FrameNumber_Callback(hObject, eventdata, handles)
% hObject    handle to FrameNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% update slider position
frameSelected = str2double(get(hObject, 'string'));
%disp(frameSelected)
set(handles.FrameSlider, 'Value', frameSelected);

% update the displayed point on the eyetrace plot
axes(handles.eyelidtracePlot)
eyetrace = getappdata(0, 'eyetrace');
a = getappdata(0, 'framePointer');
delete(a)
hold on
a = scatter([frameSelected], eyetrace(frameSelected), 'MarkerEdgeColor', [0 0 1]);
setappdata(0, 'framePointer', a)

% update the frames shown
rawFrames = getappdata(0, 'rawFrames');
axes(handles.rawFrame)
imshow(rawFrames{frameSelected,1})

procFrames = getappdata(0, 'procFrames');
axes(handles.MaskedFilteredThreshdFrame)
imshow(procFrames{frameSelected,1})

% update displayed FEC value
set(handles.outputFEC, 'string', num2str(eyetrace(frameSelected)))



% Hints: get(hObject,'String') returns contents of FrameNumber as text
%        str2double(get(hObject,'String')) returns contents of FrameNumber as a double


% --- Executes during object creation, after setting all properties.
function FrameNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FrameNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function newThresholdEditTextBox_Callback(hObject, eventdata, handles)
% hObject    handle to newThresholdEditTextBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of newThresholdEditTextBox as text
%        str2double(get(hObject,'String')) returns contents of newThresholdEditTextBox as a double


% --- Executes during object creation, after setting all properties.
function newThresholdEditTextBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to newThresholdEditTextBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ApplyThresholdButton.
function ApplyThresholdButton_Callback(hObject, eventdata, handles)
% hObject    handle to ApplyThresholdButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

newThresh = str2double(get(handles.newThresholdEditTextBox, 'string'));

% fetch necessary variables from hidden figure, etc
calibData = getappdata(0, 'calibData');
calibMetadata = getappdata(0, 'calibMetadata');
w = getappdata(0, 'w');
[m,n,c,f]=size(calibData);
rawFrames = getappdata(0, 'rawFrames'); % need to have the masked calib trial frames saved separately at some point

disp('Processing calibration file')
% for calibration processing, have to do one run through without specific calibration data
baslinecalibtrial=getappdata(0, 'baslinecalibtrial');
FEC1Frame = getappdata(0, 'FEC1Frame');
if isempty(FEC1Frame)
    calib=processCalibTrial(rawFrames, calibMetadata, newThresh, f, w, baslinecalibtrial); % this line gets the calibration values for the day
else
    calib=processCalibTrial(rawFrames, calibMetadata, newThresh, f, w, baslinecalibtrial, FEC1Frame); % this line gets the calibration values for the day
end
setappdata(0,'calib',calib) % update hidden figure calib info

% fetch data and metadata for the video currently being examined
data = getappdata(0, 'currentData');
metadata = getappdata(0, 'currentMetadata');

% apply new calibration parameters to video
[eyetrace, procFrames]=processGivenTrial(rawFrames, metadata, newThresh, calib, f, w);

% update the hidden figure's frames and eyetrace records
setappdata(0, 'procFrames', procFrames)
setappdata(0, 'eyetrace', eyetrace)

% Re-initialize the GUI
disp('Initializing GUI display')

startframe = getappdata(0, 'startframe');

file = get(handles.currentFileLabel, 'string');

origTrials = getappdata(0, 'trialdata');
newTrials = getappdata(0, 'newTrialdata');

trialnum = str2double(file(end-6:end-4));
if isnan(trialnum) % is calibration trial, assume that calibration trial is the last one in the traildata table
    trialnum = size(origTrials.eyelidpos,1);
end

if isempty(newTrials)
    newTrialTrace = [];
else
    newTrialTrace = newTrials.eyelidpos(trialnum, :);
end
initThreshCheckAdjGUIDisplay(startframe, handles, rawFrames, procFrames, ...
    eyetrace, newThresh, file, origTrials.eyelidpos(trialnum, :), ...
    newTrialTrace)

disp('GUI setup complete')



% --- Executes on button press in loadFileButton.
function loadFileButton_Callback(hObject, eventdata, handles)
% hObject    handle to loadFileButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% have the user select a video file to examine
disp('Please select a video file')
file = uigetfile('.mp4', 'Please select a video file.');
while strcmpi(file(end-3:end), '.mp4')==0
    disp('Please select a video file (must end in .mp4)')
    file = uigetfile('.mp4', 'Please select a video file.');
end
setappdata(0, 'filename', file)

disp('Loading file')
[data,metadata]=loadCompressed(file);
% save trial information to the hidden figure so you can keep
% using it if you change the threshold later
setappdata(0, 'currentData', data)
setappdata(0, 'currentMetadata', metadata)

w = getappdata(0, 'w'); % how many pixels around the current pixel should be filtered together

thresh=str2double(get(handles.currentThresholdDisplay, 'string')); % use the same threshold as was being used for the previous video

[m,n,c,f]=size(data);

calib=getappdata(0, 'calib'); % use the established calibration information

[rawFrames] = getFramesAndApplyRODs(data, metadata, f, w);
setappdata(0, 'rawFrames', rawFrames)

% run though eyetrace value extraction
[eyetrace, procFrames]=processGivenTrial(rawFrames, metadata, thresh, calib, f, w); % it sucks that the video has to get processed twice but I can't think of a better solution right now

% save the frames and the eyetrace to the hidden figure
setappdata(0, 'procFrames', procFrames)
setappdata(0, 'eyetrace', eyetrace)

% start up the rest of the GUI
disp('Initializing GUI display')

startframe = getappdata(0, 'startframe');

origTrials = getappdata(0, 'trialdata');
newTrials = getappdata(0, 'newTrialdata');

trialnum = str2double(file(end-6:end-4));
if isnan(trialnum) % is calibration trial, assume that calibration trial is the last one in the traildata table
    trialnum = size(origTrials.eyelidpos,1);
end

if isempty(newTrials)
    newTrialTrace = [];
else
    newTrialTrace = newTrials.eyelidpos(trialnum, :);
end
initThreshCheckAdjGUIDisplay(startframe, handles, rawFrames, procFrames, ...
    eyetrace, thresh, file, origTrials.eyelidpos(trialnum, :), ...
    newTrialTrace)

disp('GUI setup complete')


% --- Executes on button press in revertThresholdButton.
function revertThresholdButton_Callback(hObject, eventdata, handles)
% hObject    handle to revertThresholdButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

originalThresh = getappdata(0, 'originalThresh');
set(handles.currentThresholdDisplay, 'string', num2str(originalThresh));

% get info from the hidden figure
data = getappdata(0, 'currentData');
metadata = getappdata(0, 'currentMetadata');
w = getappdata(0, 'w'); % how many pixels around the current pixel should be filtered together

thresh=str2double(get(handles.currentThresholdDisplay, 'string')); % use the same threshold as was being used for the previous video

[m,n,c,f]=size(data);

calib=getappdata(0, 'origcalib'); % use the established calibration information

rawFrames = getappdata(0, 'rawFrames');
% run though eyetrace value extraction
[eyetrace, procFrames]=processGivenTrial(rawFrames, metadata, thresh, calib, f, w);

% save the frames and the eyetrace to the hidden figure
setappdata(0, 'procFrames', procFrames)
setappdata(0, 'eyetrace', eyetrace)

% start up the rest of the GUI
disp('Initializing GUI display')

startframe = getappdata(0, 'startframe');
file = get(handles.currentFileLabel, 'string');

origTrials = getappdata(0, 'trialdata');
newTrials = getappdata(0, 'newTrialdata');

trialnum = str2double(file(end-6:end-4));
if isnan(trialnum) % is calibration trial, assume that calibration trial is the last one in the traildata table
    trialnum = size(origTrials.eyelidpos,1);
end

if isempty(newTrials)
    newTrialTrace = [];
else
    newTrialTrace = newTrials.eyelidpos(trialnum, :);
end
initThreshCheckAdjGUIDisplay(startframe, handles, rawFrames, procFrames, ...
    eyetrace, thresh, file, origTrials.eyelidpos(trialnum, :), ...
    newTrialTrace)

disp('GUI setup complete')


% --- Executes on button press in newMaxFECFrameButton.
function newMaxFECFrameButton_Callback(hObject, eventdata, handles)
% hObject    handle to newMaxFECFrameButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('... RESETTING CALIB.SCALE ...')

file = get(handles.currentFileLabel, 'string');
if strcmpi(file(end-8:end), 'calib.mp4')
    % get the current frame
    thisFrame = str2double(get(handles.FrameNumber, 'string'));
    setappdata(0, 'FEC1Frame', thisFrame)
    
    % get the current threshold
    thresh = str2double(get(handles.currentThresholdDisplay, 'string'));
    
    % fetch necessary variables from hidden figure, etc
    calibData = getappdata(0, 'calibData');
    calibMetadata = getappdata(0, 'calibMetadata');
    rawFrames = getappdata(0, 'rawFrames');
    w = getappdata(0, 'w');
    [m,n,c,f]=size(calibData);
    
    disp('Processing calibration file')
    baslinecalibtrial = getappdata(0, 'baslinecalibtrial');
    disp(['FEC1 frame ', num2str(thisFrame)])
    calib=processCalibTrial(rawFrames, calibMetadata, thresh, f, w, baslinecalibtrial, thisFrame); % this line gets the calibration values for the day
    setappdata(0,'calib',calib) % save calib to the hidden figure so that it is accessible to all parts of the GUI
    
    % second run though eyetrace value extraction, same video but now calibrated
    [eyetrace, procFrames]=processGivenTrial(rawFrames, calibMetadata, thresh, calib, f, w);
    
    % save the frames and the eyetrace to the hidden figure
    setappdata(0, 'procFrames', procFrames)
    setappdata(0, 'eyetrace', eyetrace)

    % update the hidden figure's frames and eyetrace records
    setappdata(0, 'procFrames', procFrames)
    setappdata(0, 'eyetrace', eyetrace)
    
    % Re-initialize the GUI
    disp('Initializing GUI display')
    
    startframe = getappdata(0, 'startframe');
    
    origTrials = getappdata(0, 'trialdata');
    newTrials = getappdata(0, 'newTrialdata');
    
    trialnum = str2double(file(end-6:end-4));
    if isnan(trialnum) % is calibration trial, assume that calibration trial is the last one in the traildata table
        trialnum = size(origTrials.eyelidpos,1);
    end
    
    if isempty(newTrials)
        newTrialTrace = [];
    else
        newTrialTrace = newTrials.eyelidpos(trialnum, :);
    end
    initThreshCheckAdjGUIDisplay(startframe, handles, rawFrames, procFrames, ...
        eyetrace, thresh, file, origTrials.eyelidpos(trialnum, :), ...
        newTrialTrace)
    
    disp('GUI setup complete')

else
    disp('ONLY PERMITTED TO SET FEC 1 FRAME ON THE CALIBRATION TRIAL')
end




% --- Executes on button press in newRODButton.
function newRODButton_Callback(hObject, eventdata, handles)
% hObject    handle to newRODButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

file = get(handles.currentFileLabel, 'string');
if strcmpi(file(end-8:end), 'calib.mp4')
    % Place rectangle on the processed frame so you can easily select the part
    % with an artifact
    % h=imrect(handles.MaskedFilteredThreshdFrame);
    h=imellipse(handles.MaskedFilteredThreshdFrame);
    
    % fcn = makeConstrainToRectFcn('imrect',get(handles.cameraAx,'XLim'),get(handles.cameraAx,'YLim'));
    fcn = makeConstrainToRectFcn('imellipse',...
        get(handles.MaskedFilteredThreshdFrame,'XLim'),...
        get(handles.MaskedFilteredThreshdFrame,'YLim'));
    setPositionConstraintFcn(h,fcn);
    
    % metadata.cam.winpos=round(wait(h));
    XY=round(wait(h));  % only use for imellipse
    rodPos=round(getPosition(h));
    newRODMask=createMask(h);
    hp=findobj(handles.MaskedFilteredThreshdFrame,'Tag','rodpatch');
    delete(hp)
    delete(h);
    handles.rodpatch=patch(XY(:,1),XY(:,2),'g','FaceColor','none','EdgeColor','g','Tag','rodpatch');
    handles.XY=XY;
    rodPatches = getappdata(0, 'rodPatches');
    rodPatches{end+1,1} = XY;
    setappdata(0, 'rodPatches', rodPatches)
    
    rodMasks = getappdata(0, 'rodMasks');
    rodMasks{end+1,1} = newRODMask;
    setappdata(0, 'rodMasks', rodMasks)
    
    % ask the user when they would like the mask to apply
    prompt = 'Enter ROD onset FEC (0-1):';
    start = input(prompt);
    while start>1 && start<0
        start = input(prompt);
    end
    
    prompt = 'Enter ROD offset FEC (0-1, >= onset FEC):';
    stop = input(prompt);
    while stop>1 && stop<0 && stop<start
        stop = input(prompt);
    end
    
    rodEffective = getappdata(0, 'rodEffective');
    rodEffective(end+1,1) = start;
    rodEffective(end, 2) = stop;
    setappdata(0, 'rodEffective', rodEffective)
else
    disp('ONLY PERMITTED TO SET RODs ON THE CALIBRATION TRIAL')
end


% --- Executes on button press in applyRODsButton.
function applyRODsButton_Callback(hObject, eventdata, handles)
% hObject    handle to applyRODsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

file = get(handles.currentFileLabel, 'string');
if strcmpi(file(end-8:end), 'calib.mp4')
    % mask out the raw eyelid frame so that the mask will apply across all
    % later applications regardless of the changed eyelid position values
    rawFrames = getappdata(0, 'rawFrames');
    rodMasks = getappdata(0, 'rodMasks');
    calib = getappdata(0, 'calib');
    rodEffective = getappdata(0, 'rodEffective');
    eyetrace = getappdata(0, 'eyetrace');
    data = getappdata(0, 'calibData');
    
    [m,n,c,f]=size(data);
    
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
        
        for i=1:f
            if eyetrace(i)>= rodStart && eyetrace(i)<= rodStop % only apply the ROD if it is a valid FEC to be doing so
                rawFrames{i,1}(rodMasks{m,1}==1)=255; % in grayscale images, 255 corresponds to white
            end
        end
    end
    
    setappdata(0, 'rawFrames', rawFrames)
    setappdata(0, 'calibFrames', rawFrames)
    
    % recalibrate
    w = getappdata(0, 'w'); % how many pixels around the current pixel should be filtered together
    data = getappdata(0, 'calibData');
    metadata = getappdata(0, 'calibMetadata');
    thresh=str2double(get(handles.currentThresholdDisplay, 'string')); % just set up using the threshold from calibration
    
    [m,n,c,f]=size(data);
    
    disp('Processing calibration file')
    % for calibration processing, have to do one run through without specific calibration data
    baslinecalibtrial = getappdata(0, 'baslinecalibtrial');
    FEC1Frame = getappdata(0, 'FEC1Frame');
    if isempty(FEC1Frame)
        calib=processCalibTrial(rawFrames, metadata, thresh, f, w, baslinecalibtrial); % this line gets the calibration values for the day
    else
        calib=processCalibTrial(rawFrames, metadata, thresh, f, w, baslinecalibtrial, FEC1Frame); % this line gets the calibration values for the day
    end
    setappdata(0,'calib',calib) % save calib to the hidden figure so that it is accessible to all parts of the GUI
    
    % second run though eyetrace value extraction, same video but now calibrated
    [eyetrace, procFrames]=processGivenTrial(rawFrames, metadata, thresh, calib, f, w);
    
    % save the frames and the eyetrace to the hidden figure
    setappdata(0, 'procFrames', procFrames)
    setappdata(0, 'eyetrace', eyetrace)
    
    % save information important for applying RODs to later files
    setappdata(0, 'calibAtRODSetting', calib)
    setappdata(0, 'threshAtRODSetting', thresh)
    
    % start up the rest of the GUI
    disp('Initializing GUI display')
    
    startframe = str2double(get(handles.FrameNumber, 'string'));
    
    file = get(handles.currentFileLabel, 'string');
    
    origTrials = getappdata(0, 'trialdata');
    newTrials = getappdata(0, 'newTrialdata');
    
    trialnum = str2double(file(end-6:end-4));
    if isnan(trialnum) % is calibration trial, assume that calibration trial is the last one in the traildata table
        trialnum = size(origTrials.eyelidpos,1);
    end
    
    if isempty(newTrials)
        newTrialTrace = [];
    else
        newTrialTrace = newTrials.eyelidpos(trialnum, :);
    end
    initThreshCheckAdjGUIDisplay(startframe, handles, rawFrames, procFrames, ...
        eyetrace, thresh, file, origTrials.eyelidpos(trialnum, :), ...
        newTrialTrace)
    
    disp('GUI setup complete')
else
    disp('ONLY PERMITTED TO SET RODs ON THE CALIBRATION TRIAL')
end

% 
% 
% currentFrame = str2double(get(handles.FrameNumber, 'string'));
% 
% axes(handles.eyelidtracePlot)
% hold off
% plot(neweyetrace')
% hold on
% a = scatter([currentFrame], neweyetrace(currentFrame), 'MarkerEdgeColor', [0 0 1]);
% setappdata(0, 'framePointer', a)



% --- Executes on button press in newTrialdataButton.
function newTrialdataButton_Callback(hObject, eventdata, handles)
% hObject    handle to newTrialdataButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



file = get(handles.currentFileLabel, 'string');
origTrials = getappdata(0, 'trialdata');
trialnum = str2double(file(end-6:end-4));
if isnan(trialnum) % is calibration trial, assume that calibration trial is the last one in the traildata table
    trialnum = size(origTrials.eyelidpos,1);
end

% use the ROD's, FEC1Frame, and calib structure to process all the trials
% from this day
disp('Generating new trialdata...')
% cycle through all the days
files = dir('*.mp4');
trials = [];
calib = getappdata(0, 'calib');
for i = 1:length(files)
    disp(strcat('...processing trial', num2str(i)))
    
    try
        [data,metadata,encoder]=loadCompressed(files(i,1).name);
        corrupted = 0;
    catch ME
        disp('......VIDEO FILE CORRUPTED')
        corrupted = 1;
    end
    
    if ~corrupted
        % get stored info from the GUI and the hidden figure
        [~,~,~,f]=size(data);
        w = getappdata(0, 'w');
        thresh=str2double(get(handles.currentThresholdDisplay, 'string'));
        
        % generate the wholeframes and apply the RODs to the frames
        [rawFrames] = getFramesAndApplyRODs(data, metadata, f, w);
        if isempty(rawFrames)
            disp('...rawframes empty')
            pause
        end
        
        % use processGivenTrial to do the rest
        [eyetrace, procFrames]=processGivenTrial(rawFrames, metadata, thresh, calib, f, w);
        if isempty(eyetrace)
            disp('...eyetrace empty')
            pause
        end
        
        % set up new trial table based on this trial's metadata, assumes that
        % eyetrace is the same across all trials. also assumes 200 ms camera
        % pretime and 5 ms frame duration
        trials.eyelidpos(i,1:length(eyetrace)) = eyetrace;
        maxtm = (length(eyetrace) - (0.200/0.005))*0.005;
        trials.tm(i,1:length(eyetrace)) = [-0.2:0.005:(maxtm-0.005)];
        trials.fnames{i,1} = files(i,1).name;
        trials.c_isi(i,1) = metadata.stim.c.isi;
        trials.c_csnum(i,1) = metadata.stim.c.csnum;
        trials.c_csdur(i,1) = metadata.stim.c.csdur;
        if isfield(metadata.stim.c, 'usnum')
            trials.c_usnum(i,1) = metadata.stim.c.usnum;
        else
            trials.c_usnum(i,1) = 3; % in the TDT ephys rig, there is no usnum field since the only US possible is the puff
        end
        trials.c_usdur(i,1) = metadata.stim.c.usdur;
        trials.laser.delay(i,1) = metadata.stim.l.delay;
        if isfield(metadata.stim.l, 'dur')
            trials.laser.dur(i,1) = metadata.stim.l.dur;
        else
            trials.laser.dur(i,1) = metadata.stim.l.traindur; % tdt version calls this traindur not dur
        end
        trials.laser.amp(i,1) = metadata.stim.l.amp;
        if isfield(metadata.stim.l, 'freq')
            trials.laser.freq(i,1) = metadata.stim.l.freq;
        else
            trials.laser.freq(i,1) = 1;
        end
        if isfield(metadata.stim.l, 'pulsewidth')
            trials.laser.pulsewidth(i,1) = metadata.stim.l.pulsewidth;
        else
            trials.laser.pulsewidth(i,1) = metadata.stim.l.dur;
        end
        trials.trialnum = i; % assumes that matlab is going through files in alphanumeric order
        trials.type{i,1} = metadata.stim.type;
        trials.session_of_day(i,1) = str2double(files(i,1).name(end-9:end-8)); % assumes that filename uses the same format as OKim in 2018
        if isstruct(encoder) % will happen on calibration trial as there is no encoder structure
            trials.encoder_displacement(i,1:length(encoder.displacement)) = encoder.displacement';
            trials.encoder_counts(i,1:length(encoder.counts)) = encoder.counts';
        else % assumes encoder sampling rate is same as eyelid
            trials.encoder_displacement(i,1:length(eyetrace)) = nan(1,length(eyetrace));
            trials.encoder_counts(i,1:length(eyetrace)) = nan(1,length(eyetrace));
        end
        
        try
            trials.ITI(i,1) = metadata.stim.c.ITI;
        catch ME
            trials.ITI(i,1) = NaN;
        end
    end
    
    
    if i == trialnum
        plotMeRawFrames = rawFrames;
        plotMeProcFrames = procFrames;
    end
    
    if isempty(trials)
        disp('...trials empty')
        pause
    end
end


setappdata(0, 'newTrialdata', trials)
returnhere = cd;
cd('..') % for saving to directory on C drive or on server
%cd('C:\Users\kimol\Documents\matlab output') % for when data is on external hard drive
save('newTrialdata.mat', 'trials')
rodMasks = getappdata(0, 'rodMasks');
rodPatches = getappdata(0, 'rodPatches');
rodEffective = getappdata(0, 'rodEffective');
calibAtRODSetting = getappdata(0, 'calibAtRODSetting');
threshAtRODSetting = getappdata(0, 'threshAtRODSetting');
save('rodInfo.mat', 'rodMasks', 'rodPatches', 'rodEffective', 'calibAtRODSetting', 'threshAtRODSetting')

offsetTrial = getappdata(0, 'baslinecalibtrial');
FEC1Frame = getappdata(0, 'FEC1Frame');
save('reCalib.mat', 'calib', 'offsetTrial', 'FEC1Frame')
cd(returnhere)
disp('Saved new trialdata')


trialnum = str2double(file(end-6:end-4));
if isnan(trialnum) % is calibration trial, assume that calibration trial is the last one in the traildata table
    trialnum = size(origTrials.eyelidpos,1);
end

if isempty(trials.eyelidpos)
    newTrialTrace = [];
else
    newTrialTrace = trials.eyelidpos(trialnum, :);
end
startframe = str2double(get(handles.FrameNumber, 'string'));
initThreshCheckAdjGUIDisplay(startframe, handles, plotMeRawFrames, plotMeProcFrames, ...
    eyetrace, thresh, file, origTrials.eyelidpos(trialnum, :), ...
    newTrialTrace)


