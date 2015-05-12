% The function importAfterICA loads the ICA processed data, breaks it
% into trials, and save the eegData.
function importEEGAfterICA(modelParams, subjectsIdx)
    conditionLabel = {'noTask';'task'};
    for subIndex=subjectsIdx
        subIndex
        
        % Loading eeg data after ICA
        filenameExp = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
                            '/' (modelParams.subjectNames{subIndex}) '_importAfterICA.set'];
                        
        eeg=pop_loadset(filenameExp);%'/home/diliberg/Documents/Ernest Hemingway/eeg/NM/NM_aespa_speech_eegData2.set');
        eegRes = double(eeg.data);
        clear eeg
        
        % Loading cut idxs
        filenameExp = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
                            '/' (modelParams.subjectNames{subIndex}) '_exportBeforeICAIdx.mat'];
        load(filenameExp); % 'trialStartIdx', 'trialEndIdx', 'fs', 'startSample', 'endSample', 'localTrig'
        
        % Separating data channels from mastroids
        mastoidsAll = eegRes(end-1:end,:);
        eegDataAll = eegRes(1:end-2,:);
        clear eegRes
        
        % Split
        for file_index = modelParams.filesNum
            disp(sprintf('\b.'))
            for condition = 1:2
                % Chop the eeg data off
                idxStart = trialStartIdx(file_index, condition);
                idxEnd = trialEndIdx(file_index, condition);
            
                mastoids = mastoidsAll(:,idxStart:idxEnd);
                eegData = eegDataAll(:,idxStart:idxEnd);
                localTrig = localTrigConcat(idxStart:idxEnd);
                
                % Save
                filename = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
                            '/' (modelParams.subjectNames{subIndex}) '_' cell2mat(conditionLabel(condition)) ...
                            '_' num2str(file_index) '.mat'];
                filename = strcat(filename(1:end-4), ['_preprocessed' modelParams.bandPassfilter '_afterICA.mat']);
                
                save(filename, 'eegData', 'startSample', 'endSample', 'fs', 'mastoids', 'localTrig');
            end
        end
    end
end