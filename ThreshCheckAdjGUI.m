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

% Last Modified by GUIDE v2.5 27-Nov-2018 11:14:12

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

disp('Loading file')
[data,metadata]=loadCompressed(file);

w = 1; % how many pixels around the current pixel should be filtered together
thresh=metadata.cam.thresh; % just set up using the threshold from calibration

[m,n,c,f]=size(data);

disp('Processing calibration file')
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

calib=getcalib(eyetrace); % this line gets the calibration values for the day
setappdata(0,'calib',calib) % save calib to the hidden figure so that it is accessible to all parts of the GUI

% second run though eyetrace value extraction, same video but now calibrated
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
end

% save the frames and the eyetrace to the hidden figure
setappdata(0, 'rawFrames', rawFrames)
setappdata(0, 'procFrames', procFrames)
setappdata(0, 'eyetrace', eyetrace)

% start up the rest of the GUI
disp('Initializing GUI display')

startframe = 1; % making this a variable in case I want to change it later

axes(handles.rawFrame)
imshow(rawFrames{startframe,1})

axes(handles.MaskedFilteredThreshdFrame)
imshow(procFrames{startframe,1})

axes(handles.eyelidtracePlot)
plot(eyetrace')
hold on
a = scatter([startframe], eyetrace(startframe), 'MarkerEdgeColor', [0 0 1]);
setappdata(0, 'framePointer', a)

set(handles.FrameNumber, 'string', num2str(startframe))

set(handles.currentThresholdDisplay, 'string', num2str(thresh))

set(handles.outputFEC, 'string', num2str(eyetrace(startframe)))

set(handles.currentFileLabel, 'string', file)

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


% --- Executes on button press in loadFileButton.
function loadFileButton_Callback(hObject, eventdata, handles)
% hObject    handle to loadFileButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
