% Author:  Giovanni Di Liberto
% Date:    19/01/2015
% Project: Vocoding Project
%
% For each subject (vector of integers), this method fits a linear
% regression model which maps the amplitude envelope representation of the
% speech signal to the correspondent recorded EEG

function epocsResult = epochsAvg(modelParams, subjectsIdx, reference, verbose)
    conditionLabel = {'slow';'fast'};

    disp('Running epochsAvg function')
    for subIndex = subjectsIdx
        % Resetting previous counters
        for condition = 1:2
            for ph = 1:28
                wSum(condition,ph).data = zeros(128,modelParams.fs*0.5); % 500 ms
            end
        end
        fileCount = 1;

        disp(['Subject ', num2str(subIndex)])

        % Given a subject - for each input file
        for fileIndex = modelParams.filesNum
            if (verbose > 1)
                disp(['Trial ', num2str(fileIndex)])
            else
                disp(sprintf('\b.'))
            end

            for condition = 1:2
                % Loading eeg
                filename = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
                        '/' (modelParams.subjectNames{subIndex}) '_' cell2mat(conditionLabel(condition)) ...
                        '_' num2str(fileIndex) '.' modelParams.fileFormat(subIndex,:)];
                load(strcat(filename(1:end-4), ['_preprocessed' modelParams.bandPassfilter '.mat']))
                
                % Reference each electrodes:
                if (reference == 1)
                    eegData = double(eegData-repmat(squeeze(mean(eegData,1)),[modelParams.nElectrodes(subIndex) 1])); 
                elseif (reference == 0)
                    eegData = double(eegData-repmat(squeeze(mean(mastoids,1)),[modelParams.nElectrodes(subIndex) 1])); 
                end

%                 if (verbose > 1)
%                     disp('Downsampling')
%                 end
% 
%                 eegData = downsample(eegData',modelParams.fs/modelParams.downFs)';

                trigs = diff(localTrig);
                trigs(trigs<0) = 0;
                for ph = 1:28
                    phIdxs(ph).idxs = find(trigs==ph+100);
%                     length(phIdxs(ph).idxs)
                end
                
                for ph = 1:28
                    for idx = phIdxs(ph).idxs
                        wSum(condition,ph).data = wSum(condition,ph).data + eegData(:,idx:idx+modelParams.fs*0.5-1);
                    end
                end
            end
            
            fileCount = fileCount + 1;
        end

        % Trial average
        for ph = 1:28
            epocsResult.trialsAvg(subIndex,1).data(ph,:,:) = (wSum(1,ph).data / length(modelParams.filesNum));
            epocsResult.trialsAvg(subIndex,2).data(ph,:,:) = (wSum(2,ph).data / length(modelParams.filesNum));
        end
    end

end
