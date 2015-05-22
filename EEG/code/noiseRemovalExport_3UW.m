%% DSS export - eye blink and muscolar activity noise removal: this
% noise should be condition independent, therefore we concatenate all the
% trials and all the conditions
% This function downsamples the EEG data before the exportation
function noiseRemovalExport_3UW(modelParams, subjectsIdx, applyDss)
    rejectedChannels = [];
    conditionLabel = 'fwd_rev';
    for subIndex=subjectsIdx
        subIndex
        
        clear trialStartIdx
        eegConcat = zeros(0,34,length(modelParams.filesNum)); % samples x elec x trials
        % Concatenate
        for file_index = modelParams.filesNum
            file_index
            filename = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
                        '/stimuli/slowForRevPart1_' num2str(file_index) '.mat'];
            filename = strcat(filename(1:end-4), ['_preprocessed' modelParams.bandPassfilter '.mat']);
            load(filename); % 'eegData', 'startSample', 'endSample', 'fs', 'mastoids', 'localTrig'

            eegData = eegData(1:34,:);
            
            % Removing badChannels
            eegData = removeBadChannels(modelParams, eegData, subIndex, rejectedChannels);

            % Mick's bad channels removal
            tmp = eegData';
            for l = 1:34
                tmp(:,l) = tmp(:,l)/rms(tmp(:,l));
            end
            tmpTtmp = tmp'*tmp;
            stdTmp = std(tmpTtmp);
            disp(['Bad chans: ',num2str(find(stdTmp<=0.55*mean(stdTmp)))])
            badChans = find(stdTmp<0.55*mean(stdTmp));
            % Spline interpolate bad channels
            load(char(modelParams.elecPosFile(subIndex)))
            eegData = interpolate(eegData',modelParams.fsOrig,chanlocs,badChans)';

            % Removing polinomial trends
%                 eeg = nt_detrend([eegData;mastoids],50);%,w,basis);
%                 eegData = eeg(1:34,:);
%                 mastoids = eeg(129:130,:);
%                 clear eeg

            % Export
            if ~applyDss
                fs = modelParams.downFs;
                filename = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
                            '/' (modelParams.subjectNames{subIndex}) '_' conditionLabel ...
                            '_' num2str(file_index) '.mat'];
                filename = strcat(filename(1:end-4), ['_preprocessed' modelParams.bandPassfilter '_afterNoiseRemoval.mat']);

                save(filename, 'eegData', 'startSample', 'endSample', 'fs', 'sylCode', 'startIdx')
            else
                file_index
%                     eegConcat(size(eegConcat,1)+1,) = 
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


function eegInterp = interpolate(eeg,Fs,chanLocs,badChans)

    if ~isempty(badChans)

        % Format data for EEGLAB
        EEG.setname = 'NAME';
        EEG.data = eeg';
        EEG.srate = Fs;
        EEG.nbchan = size(eeg,2);
        EEG.pnts = size(eeg,1);
        EEG.xmin = 0;
        EEG.xmax = 60;
        EEG.trials = 1;
        EEG.chanlocs = chanLocs; 
        EEG.ref = 'common';
        EEG.epoch = [];
        EEG.event = [];
        EEG.reject = [];
        EEG.stats = [];
        EEG.etc = [];
        EEG.specdata = [];
        EEG.specicaact = [];
        EEG.icaact = [];
        EEG.icawinv = [];
        EEG.icasphere  = [];
        EEG.icaweights = [];
        EEG.icachansind = [];

        % Interpolate bad channels
        iEEG = eeg_interp(EEG,badChans);

        eegInterp = iEEG.data';

    else

        eegInterp = eeg;

    end

end
