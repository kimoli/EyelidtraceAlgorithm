appdata = get(0,'ApplicationData');
fns = fieldnames(appdata);
for ii = 1:numel(fns)
  rmappdata(0,fns{ii});
end
appdata = get(0,'ApplicationData'); %make sure it's gone
if isempty(fieldnames(appdata))
    disp('APPDATA SUCCESSFULLY CLEARED')
else
    disp('!! APPDATA NOT CLEARED !!')
end
clear all