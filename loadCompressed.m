function [data,varargout]=loadCompressed(vidfile)
	% [DATA,{METADATA}]=loadCompressed(VIDFILE)
	% Convert compressed AVI to Matlab native 4D uint8 video format and, if available, load corresponding metadata

	[p,n,e]=fileparts(vidfile);

	metafile=fullfile(p,[n '_meta.mat']);

	if exist(metafile)
		load(metafile)
		varargout{1}=metadata;
	end

	vidobj=VideoReader(vidfile);
	data=vidobj.read;