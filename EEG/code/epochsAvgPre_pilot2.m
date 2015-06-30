% Author:  Giovanni Di Liberto
% Date:    19/01/2015
% Project: Vocoding Project
%
% For each subject (vector of integers), this method fits a linear
% regression model which maps the amplitude envelope representation of the
% speech signal to the correspondent recorded EEG

function epocsResult = epochsAvgPre_pilot2(modelParams, subjectsIdx, reference, verbose)
    conditionLabel = {'fwd_rev'};

    disp('Running epochsAvg function')
    for subIndex = subjectsIdx
        % Resetting previous counters
        for condition = 1
            for ph = 1:28*2
                wSum(condition,ph).data = zeros(34,modelParams.downFs*0.5); % 500 ms
            end
        end
        fileCount = 1;

        disp(['Subject ', num2str(subIndex)])

        % Given a subject - for each input file
        for fileIndex = modelParams.filesNum
            fileIndex
            if (verbose > 1)
                disp(['Trial ', num2str(fileIndex)])
            else
                disp(sprintf('\b.'))
            end

            for condition = 1
                % Loading eeg
                filename = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
                        '/' (modelParams.subjectNames{subIndex}) cell2mat(conditionLabel(condition)) ...
                        '_' num2str(fileIndex) '.' modelParams.fileFormat(subIndex,:)];
                load(strcat(filename(1:end-4), ['_preprocessed' modelParams.bandPassfilter '.mat']));% '_afterNoiseRemoval.mat']))
                
                % Reference each electrodes:
                eegData = eegData(1:modelParams.nElectrodes(subIndex),:);
                if (reference == 1)
                    eegData = eegData-repmat(squeeze(mean(eegData,1)),[modelParams.nElectrodes(subIndex) 1]); 
                elseif (reference == 0)
                    eegData = eegData-repmat(squeeze(mean(mastoids,1)),[modelParams.nElectrodes(subIndex) 1]); 
                end

%                 if (verbose > 1)
%                     disp('Downsampling')
%                 end
% 
%                 eegData = downsample(eegData',modelParams.fs/modelParams.downFs)';

%                 trigs = diff(localTrig);
%                 trigs(trigs<0) = 0;
%                 for ph = 1:28
%                     phIdxs(ph).idxs = find(trigs==ph+100);
% %                     length(phIdxs(ph).idxs)
%                 end
%

                for syl = 1:28*2
                    phIdxs(syl).idxs = round(startIdx(sylCode==syl)/44100*modelParams.fs)+1;
                end
                
                for ph = 1:28*2
%                     ph
                    for idx = phIdxs(ph).idxs
%                         idx
                        wSum(condition,ph).data = wSum(condition,ph).data + eegData(:,idx:idx+modelParams.downFs*0.5-1);
                    end
                end
            end
            
            fileCount = fileCount + 1;
        end

        % Trial average
        for ph = 1:28*2
            epocsResult.trialsAvg(subIndex,1).data(ph,:,:) = (wSum(1,ph).data / length(modelParams.filesNum));
        end
    end

end
