%% ICA export - eye blink and muscolar activity noise removal: this
% noise should be condition independent, therefore we concatenate all the
% trials and all the conditions
% This function downsamples the EEG data before the exportation
function exportEEG4ICA(modelParams, subjectsIdx)
    conditionLabel = {'noTask';'task'};
    for subIndex=subjectsIdx
        subIndex
        
        clear trialStartIdx
        eegConcat = [];
        localTrigConcat = [];
        % Concatenate
        for file_index = modelParams.filesNum
            disp(sprintf('\b.'))
            for condition = 1:2
                filename = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
                            '/' (modelParams.subjectNames{subIndex}) '_' cell2mat(conditionLabel(condition)) ...
                            '_' num2str(file_index) '.mat'];
                filename = strcat(filename(1:end-4), ['_preprocessed' modelParams.bandPassfilter '.mat']);
                load(filename); % 'eegData', 'startSample', 'endSample', 'fs', 'mastoids', 'localTrig'

                % Downsample
                eegData = downsample(eegData', modelParams.fsOrig/modelParams.downFs)';
                mastoids = downsample(mastoids', modelParams.fsOrig/modelParams.downFs)';
                localTrig = downsample(localTrig', modelParams.fsOrig/modelParams.downFs)';
                
                trialStartIdx(file_index, condition) = size(eegConcat,2)+1;
                eegConcat = [eegConcat, [eegData;mastoids]];
                localTrigConcat = [localTrigConcat, localTrig];
                trialEndIdx(file_index, condition) = size(eegConcat,2);
            end
        end

        % Export
        fs = modelParams.downFs;
        filenameExp = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
                            '/' (modelParams.subjectNames{subIndex}) '_exportBeforeICA.mat'];
        save(filenameExp, 'eegConcat');
        
        filenameExp = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
                            '/' (modelParams.subjectNames{subIndex}) '_exportBeforeICAIdx.mat'];
        save(filenameExp, 'trialStartIdx', 'trialEndIdx', 'fs', 'startSample', 'endSample', 'localTrigConcat');
    end
end

% 
% % Removing badChannels
%                 eegData = removeBadChannels(modelParams, eegData, subIndex, rejectedChannels);
% 
%                 % Mick's bad channels removal
%                 tmp = eegData';
%                 for l = 1:128
%                     tmp(:,l) = tmp(:,l)/rms(tmp(:,l));
%                 end
% %                 tmp = zscore(tmp);
%                 tmpTtmp = tmp'*tmp;
%                 stdTmp = std(tmpTtmp);
%                 disp(['Bad chans: ',num2str(find(stdTmp<=0.55*mean(stdTmp)))])
%                 badChans = find(stdTmp<0.55*mean(stdTmp));
%                 % Spline interpolate bad channels
%                 load(char(modelParams.elecPosFile(subIndex)))
%                 eegData = interpolate(eegData',modelParams.fsOrig,chanlocs,badChans)';
% 
%                
%                 
%                 % Removing polinomial trends
% %                 eeg = nt_detrend([eegData;mastoids],50);%,w,basis);
% %                 eegData = eeg(1:128,:);
% %                 mastoids = eeg(129:130,:);
% %                 clear eeg


%% DSS export