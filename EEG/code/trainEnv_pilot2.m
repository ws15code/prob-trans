% Author:  Giovanni Di Liberto
% Date:    03/03/2015
% Project: WS15
%
% For each subject (vector of integers), this method fits a linear
% regression model which maps the amplitude envelope representation of the
% speech signal to the correspondent recorded EEG

function [trainData, modelParams] = trainEnv_pilot2(modelParams, subjectsIdx, reference, verbose)
    stimulusName = {'ba','be','da','de','fa','fe','ga','ge','ka','ke','ma','me','na','ne','pa','pe','ta','te','va','ve','xda','xde','xsa','xse','xtxa','xtxe','za','ze'};
    conditionLabel = {'noTask';'task'};
    
    % Loading envelope stimuli
    for ph = 1:28
        filename = [modelParams.audioPath '/s_m102_' cell2mat(stimulusName(ph)) '.sph_env.mat'];
        load(filename); % envelope, fsEnv
        env(ph).data = envelope;
    end
                
    disp('Running trainEnv function')
    for subIndex = subjectsIdx
         % Resetting previous counters
        for condition = 1:2
            wSum(condition).data = [];
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

            for conditionIdx = 1:2
                % Loading eeg
                filename = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
                        '/' (modelParams.subjectNames{subIndex}) '_' cell2mat(conditionLabel(conditionIdx)) ...
                        '_' num2str(fileIndex) '.' modelParams.fileFormat(subIndex,:)];
                load(strcat(filename(1:end-4), ['_preprocessed' modelParams.bandPassfilter '_afterICA.mat']))

                % Reference each electrodes:
                if (reference == 1)
                    eegData = eegData-repmat(squeeze(mean(eegData,1)),[modelParams.nElectrodes(subIndex) 1]); 
                elseif (reference == 0)
                    eegData = eegData-repmat(squeeze(mean(mastoids,1)),[modelParams.nElectrodes(subIndex) 1]); 
                end

                % Updating fs
%                 if (modelParams.fs ~= fs)
%                     if (verbose > 1)
%                         disp(['Warning: changing fs to the preprocessed file downsampling value: ' num2str(fs) ' Hz'])
%                     end
%                     modelParams.fs = fs;
%                 end

                % Preparing env concatenation
                envelopeConcat = zeros(28,length(localTrig));
                trigs = diff(localTrig);
                trigs(trigs<0) = 0;
                for idx = find(trigs)
                    if idx == 663
                        disp('')
                    end
                    phCode = trigs(idx) - 100;
                    if (phCode > 0) % This should always be the case
                        envelopeConcat(phCode,idx:idx+round(length(env(phCode).data)/4)-1) = 1;
                    end
%                     if phCode >= 1 && phCode <= 28
%                         envelopeConcat(idx:idx+length(env(phCode).data)-1) = envelopeConcat(idx:idx+length(env(phCode).data)-1) + env(phCode).data';
%                     end
                end
                envelope = envelopeConcat;
                
                % Check fsEnv
                if (exist('fsEnv','var')) && (modelParams.fs ~= fsEnv)
                    disp('Warning: envelope stimuli saved with a different sampling freq from the EEG')
                end

                if (verbose > 1)
                    disp('Downsampling')
                end
                
%                 eegData = downsample(eegData',modelParams.fs/modelParams.downFs)'; % Usually it doesn't do anything

%                 if (modelParams.downFs < modelParams.fs) % Usually false
% %                     envelope = resample(double(envelope),modelParams.downFs,modelParams.fs);
%                     envelope = downsample(double(envelope'),modelParams.fs/modelParams.downFs)';
%                     % Artifact correction - the envelope of an auditory
%                     % stimulus can't have negative values
% %                     envelope(envelope < 0) = 0;
%                 end
                %auContrastSignal = zscore(auContrastSignal')';

                trainData.stimulus(subIndex, fileCount, conditionIdx).data = envelope;

                if (verbose > 1)
                    disp('Running AESPA function')
                end

                % The followings shouldn't do anything
%                 trialLength = min(size(eegData,2), size(envelope,1));
%                 envelope = envelope(1:trialLength);
%                 eegData = eegData(1:size(eegData,1), 1:trialLength);
% 
%                 envelope = envelope(128:end); % cutting the first second (bad data)
%                 eegData = eegData(:,128:end);
%                 
%                 envelope = (tukeywin(length(envelope),(rand*0.05)+0.1).*envelope)'; % applying a windowing, in order to smooth onset/offset effects
%                 eegData = repmat(tukeywin(length(envelope),(rand*0.05)+0.1)',size(eegData,1),1).*eegData;
%                 
                [w,modelParams.lags_ms] = mTRF(envelope,eegData,modelParams.downFs,0,modelParams.lags_ms(1),modelParams.lags_ms(end),modelParams.ridgeEnv*10);
%                 figure;plot(modelParams.lags_ms,w');
%                 figure;plot(envelope);
                if (verbose > 1)
                    disp('Averaging with previous AESPAs')
                end

                % Weighting w using the repetition count
                
                
                % It sums the current only if it is a correct trial (non-target)
                if (isempty(wSum(conditionIdx).data))
                    wSum(conditionIdx).data = w;
                else
                    wSum(conditionIdx).data = wSum(conditionIdx).data + w;
                end

                % Saving the vespa into an array
                trainData.trials(subIndex, fileCount, conditionIdx).data = w;
            end
            
            fileCount = fileCount + 1;
        end

        % Trial average
        trainData.trialsAvg(subIndex,1).data = (wSum(1).data / length(modelParams.filesNum));
        trainData.trialsAvg(subIndex,2).data = (wSum(2).data / length(modelParams.filesNum));
    end

end
