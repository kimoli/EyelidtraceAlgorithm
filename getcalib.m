function calib=getcalib(trace,varargin)
% function [scale,offset]=getcalib(trace,varargin)
% Return video calibration values for eyelid (scale and offset) in CAL vector. 
% [scale,offset]=getcalib(TRACE,{PRE,POST})
% Scale and offset are returned, which can be used to convert pixel counts to %FEC. 
% Code assumes that eye is fully
% open at beginning for at least PRE frames (default=40) and reaches full
% closure by POST (default 40 frames).

if nargin > 1
    pre=varargin{1};
    post=varargin{2};
else
    pre=40;
    post=40;
end

calib.offset=mean(trace(1:pre));
maxclosure=max(trace(pre:pre+post));
calib.scale=maxclosure-calib.offset;

end


% cal=[scale offset];