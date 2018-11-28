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

% Last Modified by GUIDE v2.5 28-Nov-2018 16:59:40

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

% have the user select a video file to examine
disp('Please select a calibration file')
file = uigetfile('.mp4', 'Please select calibration file.');
while strcmpi(file(end-8:end), 'calib.mp4')==0
    disp('Please select a calibration file (must end in calib.mp4)')
    file = uigetfile('.mp4', 'Please select calibration file.');
end
setappdata(0, 'filename', file)

disp('Loading file')
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

calib=processCalibTrial(data, metadata, thresh, f, w); % this line gets the calibration values for the day
setappdata(0,'calib',calib) % save calib to the hidden figure so that it is accessible to all parts of the GUI

% second run though eyetrace value extraction, same video but now calibrated
[eyetrace, rawFrames, procFrames]=processGivenTrial(data, metadata, thresh, calib, f, w);

% save the frames and the eyetrace to the hidden figure
setappdata(0, 'rawFrames', rawFrames)
setappdata(0, 'procFrames', procFrames)
setappdata(0, 'eyetrace', eyetrace)

% start up the rest of the GUI
disp('Initializing GUI display')

startframe = 1; % making this a variable in case I want to change it later
setappdata(0, 'startframe', startframe)

initThreshCheckAdjGUIDisplay(startframe, handles, rawFrames, procFrames, ...
    eyetrace, thresh, file)

disp('GUI setup complete')

% set up potential variables for later in the code
setappdata(0, 'rodMasks', {})
setappdata(0, 'rodPatches', {})
setappdata(0, 'rodApplies', [])




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

disp('Processing calibration file')
% for calibration processing, have to do one run through without specific calibration data
calib=processCalibTrial(calibData, calibMetadata, newThresh, f, w); % this line gets the calibration values for the day
setappdata(0,'calib',calib) % update hidden figure calib info

% fetch data and metadata for the video currently being examined
data = getappdata(0, 'currentData');
metadata = getappdata(0, 'currentMetadata');

% apply new calibration parameters to video
[eyetrace, rawFrames, procFrames]=processGivenTrial(data, metadata, newThresh, calib, f, w);

% update the hidden figure's frames and eyetrace records
setappdata(0, 'rawFrames', rawFrames)
setappdata(0, 'procFrames', procFrames)
setappdata(0, 'eyetrace', eyetrace)

% Re-initialize the GUI
disp('Initializing GUI display')

startframe = getappdata(0, 'startframe');

file = getappdata(0, 'filename');
initThreshCheckAdjGUIDisplay(startframe, handles, rawFrames, procFrames, ...
    eyetrace, newThresh, file)

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

% run though eyetrace value extraction
[eyetrace, rawFrames, procFrames]=processGivenTrial(data, metadata, thresh, calib, f, w);

% save the frames and the eyetrace to the hidden figure
setappdata(0, 'rawFrames', rawFrames)
setappdata(0, 'procFrames', procFrames)
setappdata(0, 'eyetrace', eyetrace)

% start up the rest of the GUI
disp('Initializing GUI display')

startframe = getappdata(0, 'startframe');

initThreshCheckAdjGUIDisplay(startframe, handles, rawFrames, procFrames, ...
    eyetrace, thresh, file)

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

calib=getappdata(0, 'calib'); % use the established calibration information

% run though eyetrace value extraction
[eyetrace, rawFrames, procFrames]=processGivenTrial(data, metadata, thresh, calib, f, w);

% save the frames and the eyetrace to the hidden figure
setappdata(0, 'rawFrames', rawFrames)
setappdata(0, 'procFrames', procFrames)
setappdata(0, 'eyetrace', eyetrace)

% start up the rest of the GUI
disp('Initializing GUI display')

startframe = getappdata(0, 'startframe');
file = getappdata(0, 'filename');

initThreshCheckAdjGUIDisplay(startframe, handles, rawFrames, procFrames, ...
    eyetrace, thresh, file)

disp('GUI setup complete')


% --- Executes on button press in newMaxFECFrameButton.
function newMaxFECFrameButton_Callback(hObject, eventdata, handles)
% hObject    handle to newMaxFECFrameButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

file = get(handles.currentFileLabel, 'string');
if strcmpi(file(end-8:end), 'calib.mp4')
    % get the current frame
    thisFrame = str2double(get(handles.FrameNumber, 'string'));
    
    % get the current threshold
    thresh = str2double(get(handles.currentThresholdDisplay, 'string'));
    
    % fetch necessary variables from hidden figure, etc
    calibData = getappdata(0, 'calibData');
    calibMetadata = getappdata(0, 'calibMetadata');
    w = getappdata(0, 'w');
    [m,n,c,f]=size(calibData);
    
    disp('Processing calibration file')
    % for calibration processing, have to do one run through without specific calibration data
    % for calibration processing, have to do one run through without specific calibration data
    calib.scale=1;
    calib.offset=[0; 0];
    
    eyetrace=zeros(1,length(f));
    for i=1:f
        wholeframe=calibData(:,:,1,i);   % make it a grayscale image in case it's not (this assumes all color channels have roughtly the same value)
        binimage=medfilt2(wholeframe,[w w]) > thresh*256;
        eyeimage=binimage.*calibMetadata.cam.mask;
        tr=sum(eyeimage(:));
        eyetrace(i)=(tr-calib.offset(1))./calib.scale;
    end

    
    calib.offset=mean(eyetrace(1:40));
    maxclosure=eyetrace(thisFrame);
    calib.scale=maxclosure-calib.offset;
    
    setappdata(0,'calib',calib) % update hidden figure calib info
    
    % apply new calibration parameters to video
    [eyetrace, rawFrames, procFrames]=processGivenTrial(calibData, calibMetadata, thresh, calib, f, w);
    
    % update the hidden figure's frames and eyetrace records
    setappdata(0, 'rawFrames', rawFrames)
    setappdata(0, 'procFrames', procFrames)
    setappdata(0, 'eyetrace', eyetrace)
    
    % Re-initialize the GUI
    disp('Initializing GUI display')
    
    startframe = getappdata(0, 'startframe');
    
    initThreshCheckAdjGUIDisplay(startframe, handles, rawFrames, procFrames, ...
        eyetrace, thresh, file)
    
    disp('GUI setup complete')

else
    disp('ONLY PERMITTED TO SET FEC 1 FRAME ON THE CALIBRATION TRIAL')
end




% --- Executes on button press in newRODButton.
function newRODButton_Callback(hObject, eventdata, handles)
% hObject    handle to newRODButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


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


% --- Executes on button press in applyRODsButton.
function applyRODsButton_Callback(hObject, eventdata, handles)
% hObject    handle to applyRODsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% not sure if this is the most efficient way to do this but right now I
% just need to see if this is a good idea
procFrames = getappdata(0, 'procFrames');
rodMasks = getappdata(0, 'rodMasks');
calib = getappdata(0, 'calib');
rodEffective = getappdata(0, 'rodEffective');
eyetrace = getappdata(0, 'eyetrace');
data = getappdata(0, 'calibData');

[m,n,c,f]=size(data);

[r, c] = size(rodEffective);

for m = 1:r
    neweyetrace=zeros(1,length(f));
    rodStart = rodEffective(m,1);
    rodStop = rodEffective(m,2);
    
    for i=1:f
        if eyetrace(i)>= rodStart && eyetrace(i)<= rodStop % only apply the ROD if it is a valid FEC to be doing so
            procFrames{i,1}(rodMasks{1,1}==1)=1;
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

setappdata(0, 'procFrames', procFrames)
setappdata(0, 'eyetrace', neweyetrace)

currentFrame = str2double(get(handles.FrameNumber, 'string'));

axes(handles.eyelidtracePlot)
hold off
plot(neweyetrace')
hold on
a = scatter([currentFrame], neweyetrace(currentFrame), 'MarkerEdgeColor', [0 0 1]);
setappdata(0, 'framePointer', a)

