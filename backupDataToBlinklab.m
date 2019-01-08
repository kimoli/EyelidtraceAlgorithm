% backup data processing output files to the C drive on OREK before plugging the
% external drive back into ALBUS (concerned about the transition from
% Windows 10 to Windows 7 corrupting the hard drive again)

% also check for differences between the trials and newTrials structures'
% information about the trial parameters

close all
clear all

baseDir = 'G:\data\behavior';
cd(baseDir)
folders = dir;
mice = folders(3:end);

backupDir = 'L:\users\okim\behavior';

for m = 1:length(mice)
    
    mouseFolder = strcat(baseDir, '\', mice(m,1).name);
    cd(mouseFolder)
    
    folders = dir;
    days = folders(3:end);
    
    for d = 1:length(days)
        
        % sometimes there is a condparams file or extra folder in the
        % directory that does not have daydata in it
        try
            dayFolder = strcat(mouseFolder, '\', days(d,1).name);
            cd(dayFolder)
            gotIntoDay = 1;
        catch ME
            gotIntoDay = 0;
        end
        
        if gotIntoDay
            noCRTrialFilename = strcat(mice(m,1).name, '_', ...
                days(d,1).name, '_noCRTrials.mat');
            
            if exist('newTrialdata.mat', 'file') == 2
                load('newTrialdata.mat')
                load('rodInfo.mat')
                saveTrials = 1;
                
                % double check to make sure that newTrialdata is consistent
                % with the old trialdata
                oldTrials = load('trialdata.mat');
                if strcmpi(cd,'E:\data\behavior\OK159\180228')
                    % there is a problem with this day that i need to
                    % revisit later
                elseif sum(oldTrials.trials.c_csnum-trials.c_csnum) ||...
                        sum(oldTrials.trials.c_usnum-trials.c_usnum) ||...
                        sum(oldTrials.trials.c_csdur-trials.c_csdur) ||...
                        sum(oldTrials.trials.c_usdur-trials.c_usdur) ||...
                        sum(oldTrials.trials.laser.dur-trials.laser.dur) ||...
                        sum(oldTrials.trials.laser.delay-trials.laser.delay) ||...
                        sum(oldTrials.trials.laser.amp-trials.laser.amp) ||...
                        sum(oldTrials.trials.laser.freq-trials.laser.freq) ||...
                        sum(oldTrials.trials.laser.pulsewidth-trials.laser.pulsewidth)
                    disp('!!DISCREPANCY BETWEEN TRIALDATA AND NEWTRIALDATA!!')
                    pause
                end
                
            else
                saveTrials = 0;
            end
            
            if exist(noCRTrialFilename, 'file')==2
                load(noCRTrialFilename)
                saveNoCRList = 1;
            else
                saveNoCRList = 0;
            end
            
            if exist('reCalib.mat', 'file')==2
                load('reCalib.mat')
                saveReCalib = 1;
            else
                saveReCalib = 0;
            end
            
            
            if saveTrials==1 || saveNoCRList == 1 || saveReCalib ==1
                %pause
                cd(backupDir)
                
                bckupMouseFolder = strcat(backupDir,'\',mice(m,1).name);
                if exist(mice(m,1).name, 'dir')==0
                    mkdir(mice(m,1).name)
                end
                cd(bckupMouseFolder)
                
                bckupDayFolder = strcat(bckupMouseFolder, '\', days(d,1).name);
                if exist(days(d,1).name, 'dir')==0
                    mkdir(days(d,1).name)
                end
                cd(bckupDayFolder)
                
                if saveTrials && exist('newTrialdata.mat', 'file') == 0
                    save('newTrialdata.mat', 'trials')
                    save('rodInfo.mat', 'rodMasks', 'rodPatches', 'rodEffective', 'calibAtRODSetting', 'threshAtRODSetting')
                end
                
                if saveNoCRList && exist(noCRTrialFilename, 'file') == 0
                    save(noCRTrialFilename, 'markedTrials')
                end
                
                if saveReCalib && exist('reCalib.mat', 'file') == 0
                    save('reCalib.mat', 'calib', 'offsetTrial', 'FEC1Frame')
                end
            end
            
            cd(mouseFolder)
        end
        
    end
    
end