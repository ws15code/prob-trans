% Author:  Giovanni Di Liberto
% Date:    03/03/2015
% Project: WS15 - pilot 1
%
% This code performs the preprocessing of the EEG data

function modelParams = preprocessEEG(modelParams, subjectsIdx, rejectedChannels)
    load(['filters/' modelParams.bandPassfilter]);
    conditionLabel = {'slow';'fast'};
    
    for subIndex=subjectsIdx
        % Given a subject - for each input file
        for file_index = [47:50] % modelParams.filesNum
            for condition = 1:2
                % Dealing with the eeg
                % Loading eeg file
                if strcmp(modelParams.fileFormat(subIndex,:), 'mat')
                    filename = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
                        '/' (modelParams.subjectNames{subIndex}) '_' cell2mat(conditionLabel(condition)) ...
                        '_' num2str(file_index) '.mat'];
                    disp(['Preprocessing ' filename]);
                    load(filename); % eeg, localTrig

                    % Referencing (before filtering)
%                     reference = 1;
%                     if (reference == 1)
%                         eeg(1:128,:) = eeg(1:128,:)-repmat(squeeze(mean(eeg(1:128,:),1)),[modelParams.nElectrodes(subIndex) 1]); 
%                     elseif (reference == 0)
%                         eeg(1:128,:) = eeg(1:128,:)-repmat(squeeze(mean(eeg(135:136,:),1)),[modelParams.nElectrodes(subIndex) 1]); 
%                     end
                
%                     [z,idx]=nt_pca(eeg'); %         [z,idx]=nt_pca(eegSignal, 0:3, 128);
%                     eeg = z';
%                     y=nt_sns(z,8);
%                     y=y';
        
                    % Band-pass filter
                    disp('Filtering raw data');
                    eegData = filtfilthd(Hd,double(eeg)')'; % No need for detrending

                    % Chopping off the eeg data before the first
                    % presentation of a phoneme (removing artifacts of the
                    % filtering operation)
                    startSample = find(localTrig>=101 & localTrig<=128,1);
                    endSample = find(localTrig>=101 & localTrig<=128,1,'last')+round(modelParams.fs*0.8); % Indeed, a single phoneme is shorter than 1 second
                    eegData = eegData(:,startSample:endSample);
                    localTrig = localTrig(startSample:endSample);
                else
                    disp('Input file format not valid')
                end

                % Convert data to microvolts for BioSemi system
                factor = 524e3/2^24;
                eegData = factor*eegData;

                % Only want EEG from channels 1-128 or 1-160 (recording electrodes)
                mastoids = eegData(135:136,:); % extra channel 7-8 (respectively mastroid left-right)
                eegData = eegData(1:128,:); 

                % Removing badChannels
                eegData = removeBadChannels(modelParams, eegData, subIndex, rejectedChannels);

                % Downsampling % The later the better
%                 eegData = resample(double(eegData)', modelParams.downFs, modelParams.fs, 0)';
%                 mastoids = resample(double(mastoids)', modelParams.downFs, modelParams.fs, 0)';
%                 eegData = downsample(double(eegData)', modelParams.fs/modelParams.downFs)';
%                 mastoids = downsample(double(mastoids)', modelParams.fs/modelParams.downFs)';
%                 localTrig = downsample(double(localTrig)', modelParams.fs/modelParams.downFs)';
% 
%                 fs = modelParams.downFs;
                fs = modelParams.fs;
                save(strcat(filename(1:end-4), ['_preprocessed' modelParams.bandPassfilter '.mat']), 'eegData', 'startSample', 'endSample', 'fs', 'mastoids', 'localTrig');
            end
        end
    end
end

% Written by Ed Lalor based on EEGlab - 04/09/09.
% Edited by Giovanni Di Liberto - 12/05/14
function [eeg_interped, run_std] = removeBadChannels(modelParams, eeg, subIndex, rejectedChannels)
    % Get it into EEGlab format.
    load(char(modelParams.elecPosFile(subIndex)))

    EEG.data = eeg;
    EEG.chanlocs = chanlocs;
    EEG.nbchan = length(EEG.chanlocs);
    EEG.setname = 'cane';
    EEG.icawinv = [];
    EEG.icaweights = [];
    EEG.icasphere  = [];
    EEG.icaact = [];
    EEG.pnts = size(eeg,2);
    EEG.trials = 1;
    EEG.srate = 512;
    EEG.epoch = [];
    EEG.specdata = [];
    EEG.icachansind = [];
    EEG.specicaact = [];
    EEG.reject = [];
    EEG.stats = [];
    EEG.ref = 'averef';
    EEG.etc = [];
    EEG.event = [];

    EEG.xmax = size(eeg,2);
    EEG.xmin = 1;

    std_chans = zeros(1,size(eeg,1));

    for i = 1:size(eeg,1) 
        std_chans(i) = std(eeg(i,:));
    end

    mean(std_chans);

    if ~exist('rejectedChannels','var') || isempty(rejectedChannels)
        % Identify bad channels
        badchans = [];

        for i = 1:size(eeg,1) 
            if std(eeg(i,:)) > 3*mean(std_chans)  % If the standard deviation of the channel is more than 3 times the mean of the standard deviations of all the channels
                badchans = [badchans i];
            end
        end

        clear std_chans

        for i = 1:size(eeg,1) 
            if ~isempty(find(badchans==i, 1))
                continue
            end
            std_chans(i) = std(eeg(i,:));
        end

        mean(std_chans);

        for i = 1:size(eeg,1) 
            if std(eeg(i,:)) < mean(std_chans)/3  % If the standard deviation of the channel is less than a third of the mean of the standard deviations of all the channels % This is quite severe. Look at James' idea of re-referencing to Cz, sort by radial distance, fit curve and subtract it. Then do this thing of the std again
                badchans = [badchans i];
            end
        end
    else
        badchans = rejectedChannels;
    end

    if (~isempty(badchans))
        disp(['badChannels: ' num2str(badchans)])
        iEEG = eeg_interp(EEG, badchans); % it requires eeglab (I think :) )
        eeg_interped = iEEG.data;
        eeg_interped = eeg_interped(1:size(eeg,1),:);
    else
        eeg_interped = eeg;
    end

    for i = 1:size(eeg,1) 
        std_chans(i) = std(eeg_interped(i,:));
    end

    run_std = mean(std_chans);
end
