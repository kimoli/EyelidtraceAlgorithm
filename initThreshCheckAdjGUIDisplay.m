function initThreshCheckAdjGUIDisplay(startframe, handles, rawFrames, procFrames, ...
    eyetrace, thresh, file, origTrial, newTrial)

axes(handles.rawFrame)
imshow(rawFrames{startframe,1})

axes(handles.MaskedFilteredThreshdFrame)
imshow(procFrames{startframe,1})


axes(handles.eyelidtracePlot)
hold off
plot(eyetrace', 'Color', [0 0 0])
hold on
plot(origTrial', 'Color', [0 0 0], 'LineStyle', ':')
plot(newTrial', 'Color', [1 0 0], 'LineStyle', '--')
a = scatter(startframe, eyetrace(startframe), 'MarkerEdgeColor', [0 0 1]);
ylim([0 1.05])
setappdata(0, 'framePointer', a)

set(handles.FrameNumber, 'string', num2str(startframe))

set(handles.currentThresholdDisplay, 'string', num2str(thresh))

set(handles.outputFEC, 'string', num2str(eyetrace(startframe)))

set(handles.currentFileLabel, 'string', file)

set(handles.FrameSlider, 'min', 1);
set(handles.FrameSlider, 'max', length(eyetrace));
set(handles.FrameSlider, 'Value', startframe);
set(handles.FrameSlider, 'SliderStep', [1/length(eyetrace) 10/length(eyetrace)])

end