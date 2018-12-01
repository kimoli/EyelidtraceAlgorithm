function [data,metadata,encoder]=loadCompressed(vidfile)
	% [DATA,{METADATA}]=loadCompressed(VIDFILE)
	% Convert compressed AVI to Matlab native 4D uint8 video format and, if available, load corresponding metadata

	[p,n,e]=fileparts(vidfile);

	metafile=fullfile(p,[n '_meta.mat']);

	if exist(metafile)
		load(metafile)
    else
        metadata=NaN;
    end
    
    metafile_encoder = fullfile(p,[n '_encoder.mat']);
    
    if exist(metafile_encoder)
        load(metafile_encoder)
    else
        encoder = NaN;
    end

	vidobj=VideoReader(vidfile);
	data=vidobj.read;