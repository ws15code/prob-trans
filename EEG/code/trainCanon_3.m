% Author:  Giovanni Di Liberto
% Date:    03/03/2015
% Project: WS15
%
% For each subject (vector of integers), this method fits a linear
% regression model which maps the amplitude envelope representation of the
% speech signal to the correspondent recorded EEG

function trainCanonVar = trainCanon_3(modelParams, subjectsIdx, reference)
    stimulusName = {'ba','be','da','de','fa','fe','ga','ge','ka','ke','ma','me','na','ne','pa','pe','ta','te','va','ve','xda','xde','xsa','xse','xtxa','xtxe','za','ze'};
    conditionLabel = {'fwd_rev'};

    % Loading sgram stimuli
    for syl = 1:28
        filename = [modelParams.audioPath '/s_m102_' cell2mat(stimulusName(syl)) '.sph_sgram.mat'];
        load(filename); % sgram, fsSgram
        sgramAll(syl).data = sgram;
%         sgram(ph).data = resample(sgram,128,modelParams.fsOrig); %envelope;
%         figure;plot(resample(envelope,128,512))
    end
    for syl = 29:28*2
        filename = [modelParams.audioPath '/s_m102_' cell2mat(stimulusName(syl-28)) '.sph_sgram.mat'];
        load(filename); % sgram, fsSgram
        sgramAll(syl).data = flip(sgram,2);
    end
           
    % Reducing fBands
    for syl = 1:28*2
        count = 1;
        for i=1:4:128
            sgramAll(syl).data(count,:) = sum(sgramAll(syl).data(i:i+3,:),1);
            count = count + 1;
        end
        sgramAll(syl).data = sgramAll(syl).data(1:128/4,:);
    end   
                
    disp('Running trainEnv function')
    for subIndex = subjectsIdx
         % Resetting previous counters
        for condition = 1
            wSum(condition).data = [];
        end

        disp(['Subject ', num2str(subIndex)])

        % Given a subject - for each input file
        for conditionIdx = 1
            fileCount = 1;
            globalCountSyl = 1;
            for fileIndex = modelParams.filesNum
                disp(sprintf('\b.'))
            
                % Loading eeg
                filename = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
                        '/' (modelParams.subjectNames{subIndex}) cell2mat(conditionLabel(conditionIdx)) ...
                        '_' num2str(fileIndex) '.' modelParams.fileFormat(subIndex,:)];
                load(strcat(filename(1:end-4), ['_preprocessed' modelParams.bandPassfilter '.mat']))% '_afterNoiseRemoval.mat']))

                % Reference each electrodes:
                eegData = eegData(1:modelParams.nElectrodes(subIndex),:);
                if (reference == 1)
                    eegData = eegData-repmat(squeeze(mean(eegData,1)),[modelParams.nElectrodes(subIndex) 1]); 
                elseif (reference == 0)
                    eegData = eegData-repmat(squeeze(mean(mastoids,1)),[modelParams.nElectrodes(subIndex) 1]); 
                end

                % Preparing env concatenation
%                 trigs = diff(localTrig);
%                 trigs(trigs<0) = 0;
%                 trigs(1) = localTrig(1);
                maxIdx = 0;
                for syl = 1:28*2
                    phIdxs(syl).idxs = round(startIdx(sylCode==syl)/44100*modelParams.fs)+1;
                    if ~isempty(phIdxs(syl).idxs)
                        maxIdx = max(maxIdx,max(phIdxs(syl).idxs));
                    end
                %                     length(phIdxs(ph).idxs)
                end
                
                lenTrial = 0.55*modelParams.fs;
                lenSgramTrial = lenTrial * 32;
                lenEEGTrial = lenTrial * size(eegData,1);
                sgramTrial = zeros(0,lenSgramTrial); %zeros(0,size(sgramAll(1).data,1));
                eegTrial = zeros(0,lenEEGTrial);
            
                %for idx = find(trigs)
                for syl = 1:28*2
                    syl
                    for idx = phIdxs(syl).idxs
                        if ~isempty(idx)
                            phCode = syl;
                            localSgram = flip(sgramAll(phCode).data,2)';
                            localSgram = localSgram(:)'; % If reverse (>28), it's already flipped
%                                 figure;plot(localSgram)
                            localEEG = eegData(:,idx:idx+lenTrial-1)';
                            localEEG = localEEG(:)';

                            sgramTrial = [sgramTrial;zeros(1,lenSgramTrial)];
                            sgramTrial(end,1:length(localSgram)) = localSgram;
                            
                            eegTrial = [eegTrial;zeros(1,lenEEGTrial)];
                            eegTrial(end,1:length(localEEG)) = localEEG;
                            
                            globalCountSyl = globalCountSyl + 1;
                        end
                    end
                end
                
%                 sgram = resample(sgram',modelParams.downFs,modelParams.fs)'; 
%                 eegData = downsample(eegData',modelParams.fs/modelParams.downFs)'; % Usually it doesn't do anything
                if fileIndex == 1
                    stimConcat = sgramTrial;
                    eegDataConcat = eegTrial;
                else
                    stimConcat = [stimConcat;sgramTrial];
                    eegDataConcat = [eegDataConcat;eegTrial];
                end
                
%                 % Saving the vespa into an array
%                 trainData.trials(subIndex, fileCount, conditionIdx).data = w;
                fileCount = fileCount + 1;
            end
            
%             stimConcat = sum(stimConcat')';
%             stimConcat(stimConcat<0) = 0;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Does order matter? Random sorting
            idxPerm = randperm(1:size(stimConcat,1));
            [A,B,r,U,V,stats] = canoncorr(stimConcat(idxPerm,:),eegDataConcat(idxPerm,:));
            
%             [w,modelParams.lags_ms] = mTRF(stimConcat',eegDataConcat',modelParams.downFs,0,modelParams.lags_ms(1),modelParams.lags_ms(end),modelParams.ridgeEnv);
%             [w,modelParams.lags_ms] = mTRF(U',V',modelParams.downFs,0,modelParams.lags_ms(1),modelParams.lags_ms(end),modelParams.ridgeEnv);

            % Trial average
%             trainCanonVar.trialsAvg(subIndex,conditionIdx).data = w;
            trainCanonVar.A(conditionIdx).data = A;
            trainCanonVar.B(conditionIdx).data = B;
            trainCanonVar.r(conditionIdx).data = r;
        end
    end

end
