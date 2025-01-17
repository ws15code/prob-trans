% Author:  Giovanni Di Liberto
% Date:    19/01/2015
% Project: Vocoding Project
%
% For each subject (vector of integers), this method fits a linear
% regression model which maps the amplitude envelope representation of the
% speech signal to the correspondent recorded EEG

function classificationResult = simpleClassification_3UW(modelParams, subjectsIdx, reference, downFreq, maxLatency, groupSize, trainCanonVar)
    stimulusName = {'ba','be','da','de','fa','fe','ga','ge','ka','ke','ma','me','na','ne','pa','pe','ta','te','va','ve','xda','xde','xsa','xse','xtxa','xtxe','za','ze'};
    conditionLabel = {'fwd_rev'};

    if isempty(trainCanonVar)
        canon = false;
    else
        canon = true;
    end
    
    tInterval = 1; % time samples step
%     usedElec = 1:2:34;
    
    feaMap(1,:) = modelParams.featureMap(1,:);
    feaMap(2,:) = modelParams.featureMap(2,:);
    feaMap(3,:) = modelParams.featureMap(3,:);
    feaMap(4,:) = modelParams.featureMap(4,:);
    feaMap(5,:) = modelParams.featureMap(6,:)+modelParams.featureMap(7,:); % labial
    feaMap(6,:) = modelParams.featureMap(9,:)+modelParams.featureMap(10,:)+modelParams.featureMap(11,:); % coronal

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
                lenEEGTrial = floor(lenTrial * size(eegData,1) / tInterval);
                sgramTrial = zeros(0,lenSgramTrial); %zeros(0,size(sgramAll(1).data,1));
                eegTrial = zeros(0,lenEEGTrial);
                labelsClass = zeros(0,1);
            
                %for idx = find(trigs)
                for syl = 1:28*2
                    for idx = phIdxs(syl).idxs
                        if ~isempty(idx)
                            phCode = syl;
                            localSgram = flip(sgramAll(phCode).data,2)';
                            localSgram = localSgram(:)'; % If reverse (>28), it's already flipped
%                                 figure;plot(localSgram)
                            localEEG = eegData(:,idx:tInterval:idx+lenTrial-1)';
                            localEEG = localEEG(:)';

                            sgramTrial = [sgramTrial;zeros(1,lenSgramTrial)];
                            sgramTrial(end,1:length(localSgram)) = localSgram;
                            
                            eegTrial = [eegTrial;zeros(1,lenEEGTrial)];
                            eegTrial(end,1:length(localEEG)) = localEEG;
                            
                            labelsClass = [labelsClass,syl];
                            
                            globalCountSyl = globalCountSyl + 1;
                        end
                    end
                end
                
%                 sgram = resample(sgram',modelParams.downFs,modelParams.fs)'; 
%                 eegData = downsample(eegData',modelParams.fs/modelParams.downFs)'; % Usually it doesn't do anything
                if fileCount == 1
                    stimConcat = sgramTrial;
                    eegDataConcat = eegTrial;
                    labelsClassConcat = labelsClass;
                else
                    stimConcat = [stimConcat;sgramTrial];
                    eegDataConcat = [eegDataConcat;eegTrial];
                    labelsClassConcat = [labelsClassConcat,labelsClass];
                end
                
%                 % Saving the vespa into an array
%                 trainData.trials(subIndex, fileCount, conditionIdx).data = w;
                fileCount = fileCount + 1;
            end
            
            % Random perm - instances order doesn't matter - important for 
            % getting randomised averages for the ERPs
            idxPerm = randperm(size(stimConcat,1));
            labelsClassConcat = labelsClassConcat(idxPerm);
            eegDataConcat = eegDataConcat(idxPerm,:);
            
            if canon
                B = trainCanonVar.B(condition).data;
                % V = (Y - repmat(mean(Y),N,1))*B
                Y = eegDataConcat;
                N = size(Y,1);
                eegDataConcat = ((Y-repmat(mean(Y),N,1))*B);
            end
            
            % Grouping epochs
%             arrayfun( @(x)sum(labelsClassConcat==x), unique(labelsClassConcat) )
%             std(arrayfun( @(x)sum(labelsClassConcat==x), unique(labelsClassConcat) ))
            eegDataGrouped = zeros(0,size(eegDataConcat,2));
            labelsGrouped = zeros(1,0);
            for syl = 1:28*2
                localIdx = find(labelsClassConcat == syl);
                while length(localIdx) >= groupSize
                    localEEG = mean(eegDataConcat(localIdx(1:groupSize),:));
                    eegDataGrouped = [eegDataGrouped;localEEG];
                    labelsGrouped = [labelsGrouped,syl];
                    
                    % Pop of the used epochs
                    localIdx = localIdx((groupSize + 1):end);
                end
            end
            
            clear eegDataConcat
            clear stimConcat
            
            % Random perm - instances order doesn't matter % important for
            % cross-valid folds
            idxPerm = randperm(length(labelsGrouped));
            labelsGrouped = labelsGrouped(idxPerm);
            eegDataGrouped = eegDataGrouped(idxPerm,:);
            
%             [A,B,r,U,V,stats] = canoncorr(stimConcat(idxPerm,:),eegDataConcat(idxPerm,:));
            
            % Separating conditions
            idxCond(1).data = labelsGrouped <= 28; % for
            idxCond(2).data = labelsGrouped > 28;  % rev
            
            % Cross-valid
            for condition = 1:2
                idxCondition = find(idxCond(condition).data);
                localEEG = eegDataGrouped(idxCondition,:);
                localLabels = labelsGrouped(idxCondition)-(condition-1)*28;
                
                numInst = length(idxCondition);
                nFolds = 5;
                idxStart = 1;
                for crossValid = 1:nFolds
                    disp(sprintf('\b_'))

                    % Determining idx train and test folds
                    if crossValid == nFolds
                        idxEnd = numInst;
                    else
                        idxEnd = idxStart + round(numInst / nFolds);
                    end

                    testIdx = zeros(1,numInst);
                    testIdx(idxStart:idxEnd) = 1;
                    testIdx = logical(testIdx);
                    trainIdx = ~testIdx;

    %                 [class, err] = classify(data(testIdx,:),data(trainIdx,:),ceil(labelSyl(condition).data(trainIdx)/2),'diagQuadratic');

                    % Classification
                    for featureNum = 1:size(feaMap,1)
                        label2Classify = logical(feaMap(featureNum,localLabels));

                        [class, err] = classify(localEEG(testIdx,:),localEEG(trainIdx,:),label2Classify(trainIdx),'diagLinear');
%                         model = svmtrain(localEEG(trainIdx,:),label2Classify(trainIdx), 'kernel_function', 'rbf');
%                         class = svmclassify(model, localEEG(testIdx,:));

                        if crossValid == 1
                            conf(featureNum).data = confusionmat(class,label2Classify(testIdx));
                        else
                            conf(featureNum).data = conf(featureNum).data + confusionmat(class,label2Classify(testIdx));
                        end
                    end

                    idxStart = idxEnd + 1;
                end
                for featureNum = 1:size(feaMap,1)
                    label2Classify = logical(feaMap(featureNum,localLabels));

                    acc(featureNum) = (conf(featureNum).data(1,1)+conf(featureNum).data(2,2))/(conf(featureNum).data(1,1)+conf(featureNum).data(1,2)+conf(featureNum).data(2,2)+conf(featureNum).data(2,1));
                    ratio(featureNum) = length(find(label2Classify))/length(label2Classify);    
                end
                acc
                ratio
            end













% 
% 
% 
% conditionLabel = 'fwd_rev';
%     
%     if isempty(trainCanonVar)
%         canon = false;
%     else
%         canon = true;
%     end
%     
%     interval = 1:5:(maxLatency*1000);
%     usedElec = 1:4:34;
%     
%     dataFreq = modelParams.fs; %fsOrig;
%     erpLengthDown = round(downFreq*maxLatency); % maxLatency has to be in seconds
%     erpLength = round(dataFreq*maxLatency);
%     
%     currentFreq = downFreq;
%     currentErpLength = erpLengthDown;
%     
%     disp('Running epochsAvg function')
%     condition = 3;
%     for subIndex = subjectsIdx
%         % Resetting previous counters
%         if canon
%             erp(1).data = zeros(0,1,length(interval));%erpLengthDown); % condition, erp, elec, timeWin500 ms
%             erp(2).data = zeros(0,1,length(interval));%erpLengthDown); % condition, erp, elec, timeWin500 ms
%             erp(3).data = zeros(0,1,length(interval));%erpLengthDown); % condition, erp, elec, timeWin500 ms
%         else
%             erp(1).data = zeros(0,length(usedElec),length(interval)); % condition, erp, elec, timeWin500 ms
%             erp(2).data = zeros(0,length(usedElec),length(interval)); % condition, erp, elec, timeWin500 ms
%             erp(3).data = zeros(0,length(usedElec),length(interval)); % condition, erp, elec, timeWin500 ms
%         end
%         labelSyl(1).data = []; % array which contains the syllables lables for each 'erp'
%         labelSyl(2).data = [];
%         labelSyl(3).data = [];
%         
%         fileCount = 1;
% 
%         disp(['Subject ', num2str(subIndex)])
% 
%         % Given a subject - for each input file
%         for fileIndex = modelParams.filesNum
%             fileIndex
%             disp(sprintf('\b.'))
%             
%             filename = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
%                     '/stimuli/slowForRevPart1_' num2str(fileIndex) '.' modelParams.fileFormat(subIndex,:)];
% %                 load(strcat(filename(1:end-4), ['_preprocessed' modelParams.bandPassfilter '_afterNoiseRemoval.mat']))
%             load(strcat(filename(1:end-4), ['_preprocessed' modelParams.bandPassfilter '.mat']))
% 
%             eegData = eegData(1:modelParams.nElectrodes(subIndex),:);
%             
%             % Reference each electrodes:
%             if (reference == 1)
%                 eegData = double(eegData-repmat(squeeze(mean(eegData,1)),[modelParams.nElectrodes(subIndex) 1])); 
%             elseif (reference == 0)
%                 eegData = double(eegData-repmat(squeeze(mean(mastoids,1)),[modelParams.nElectrodes(subIndex) 1])); 
%             end
% 
% %             trigs = diff(localTrig);
% %             trigs(trigs<0) = 0;
% %             trigs(1) = localTrig(1); % diff doesn't work for the first state
%             for syl = 1:28*2
%                 phIdxs(syl).idxs = round(startIdx(sylCode==syl)/44100*currentFreq)+1;
% %                     length(phIdxs(ph).idxs)
%             end
% 
%             eegData = downsample(eegData',dataFreq/downFreq)';
%             % Canonical correlation
%             if canon
%                 B = trainCanonVar.B(condition).data;
%                 % V = (Y - repmat(mean(Y),N,1))*B
%                 Y = eegData';
%                 N = size(Y,1);
%                 eegData = ((Y-repmat(mean(Y),N,1))*B)';
%             end
% 
%             for syl = 1:28*2
%                 for idx = phIdxs(syl).idxs
%                     tmpData = eegData(:,idx:idx+currentErpLength-1);
%                     tmpData = tmpData(:,interval);
%                     if ~canon
%                         tmpData = tmpData(usedElec,:);
%                     end
%                     erp(condition).data(size(erp(condition).data,1)+1,:,:) = tmpData;
%                     labelSyl(condition).data(size(labelSyl(condition).data)+1) = syl;
%                 end
%             end
%             
%             fileCount = fileCount + 1;
%         end
% 
%                 
%         % Splitting in forward/time-reversed
%         revIdx = labelSyl(3).data>28;
%         labelSyl(1).data = labelSyl(3).data(~revIdx); % forward
%         labelSyl(2).data = labelSyl(3).data(revIdx);  % time-reversed
%         erp(1).data = erp(3).data(~revIdx,:,:); % forward % TODO: to check
%         erp(2).data = erp(3).data(revIdx,:,:);  % time-reversed
%         
%         % Is this cut needed after the change to pool avg?
%         minLength = min(length(labelSyl(1).data),length(labelSyl(2).data));
%         labelSyl(1).data = labelSyl(1).data(1:minLength);
%         labelSyl(2).data = labelSyl(2).data(1:minLength);
%         erp(1).data = erp(1).data(1:minLength,:,:); % forward % TODO: to check
%         erp(2).data = erp(2).data(1:minLength,:,:);  % time-reversed
% 
%         % Preparing the 'groupSize' erp matrix
%         for condition = 1:2
%             % Same size, but averaged over a number of repetitions
%             newErp(condition).data = zeros(size(erp(condition).data)); % ~180 repetition for each consonant
%             
%             [~,idx] = sort(labelSyl(condition).data);
%             labelSyl(condition).data = labelSyl(condition).data(idx);
%             erp(condition).data = erp(condition).data(idx,:,:,:);
%             
%             i = 1;
%             while i <= length(labelSyl(condition).data)-groupSize
% %                 if labelSyl(condition).data(i) == labelSyl(condition).data(i+groupSize-1)
%                 currentPh = labelSyl(condition).data(i);
%                 if mod(currentPh,2) == 0 % even number
%                     currentPh = currentPh - 1; % the consonant is the same
%                 end
%                 firstPhIdx = find(labelSyl(condition).data == currentPh,1,'first');
%                 lastPhIdx = find(labelSyl(condition).data == currentPh+1,1,'last');
%                 
%                 phIdx = randi(lastPhIdx-firstPhIdx+1,1,groupSize)+firstPhIdx-1;
%                 % avg replace each row
%                 newErp(condition).data(i,:,:) = mean(erp(condition).data(phIdx,:,:),1);
%                 labelSyl(condition).data(i) = labelSyl(condition).data(i);
% 
%                 i = i + 1;
%             end
%             erp(condition).data = newErp(condition).data;
%             clear newErp(condition).data
%             % Cut unused rows
% %             erp(condition).data = erp(condition).data(1:erpCount,:,:);
% %             labelSyl(condition).data = labelSyl(condition).data(1:erpCount);
%             
%             % MDS
%             %data = squeeze(erp(condition).data(:,60,:));
% %             data = reshape(erp(condition).data,size(erp(condition).data,1),size(erp(condition).data,3)*size(erp(condition).data,2));
%             
%             if ~canon
%                 data = erp(condition).data(:,:,:);%[3:9,18:28]);
%                 data = reshape(data,size(data,1),size(data,3)*size(data,2));
%             end
%             
%             % Canonical correlation
%             data = erp(condition).data;
%             data = reshape(data,size(data,1),size(data,3)*size(data,2));
%             
% %             Y = pdist(data, 'seuclidean');
% %             [x,~] = mdscale(Y,3); % multidimensional scaling ph features
% % 
% %             figure;
% %             colors = ['r','r','m','m','b','b','g','g','c','c','k','K','y','y','r','r','m','m','b','b','g','g','c','c','k','K','y','y','r','r','m','m','b','b','g','g','c','c','k','K','y','y','r','r','m','m','b','b','g','g','c','c','k','K','y','y'];
% % 
% %             dim1 = 1;
% %             dim2 = 2;
% %             
% %             markerSize = 50;
% %             scatter(x(:,dim1),x(:,dim2),markerSize,'w','filled'); hold on
% %             
% %             title('MDS syllables','fontsize',14)
% %             
% %             stimulusName = {'ba','be','da','de','fa','fe','ga','ge','ka','ke','ma','me','na','ne','pa','pe','ta','te','va','ve','xda','xde','xsa','xse','xtxa','xtxe','za','ze'};
% %             for i = 1:28
% %                 text(x(labelSyl(condition).data==i,dim1),x(labelSyl(condition).data==i,dim2), stimulusName(i), 'horizontal','left', 'vertical','bottom','FontSize',20,'Color',colors(i))
% %             end
% %             
% %             % Random train/test division
% %             tmp = 1:length(labelSyl(condition).data);
% %             tmp = tmp(randperm(length(tmp)));
% %             trainIdx = tmp(1:floor(length(tmp)/2));
% %             testIdx  = tmp(floor(length(tmp)/2)+1:end);
% 
%             % Preparing for cross-valid
%             % same # presentations for each syl
%             tmp = labelSyl(condition).data;
%             tmp = [1,diff(tmp)];
%             findTmp = find(tmp);
%             findTmp = findTmp(find(mod(1:length(findTmp),2))); % start idx for each consonant (eg. 'ba', 'be')
%             findTmp2 = [findTmp(2:end), length(tmp)+1];
%             minSyl = min(findTmp2-findTmp);
%             % Removing extra pairs
%             count = 0;
%             for i=1:length(labelSyl(condition).data)
%                 count = count + 1;
%                 if sum(findTmp==i) % new consonant
%                     count = 1;
%                 end
%                 if count > minSyl
%                     idxToKeep(i) = 0;
%                 else
%                     idxToKeep(i) = 1;
%                 end
%             end
%             labelSyl(condition).data = labelSyl(condition).data(find(idxToKeep));
%             data = data(find(idxToKeep),:);
% 
%             feaMap(1,:) = modelParams.featureMap(1,:);
%             feaMap(2,:) = modelParams.featureMap(2,:);
%             feaMap(3,:) = modelParams.featureMap(3,:);
%             feaMap(4,:) = modelParams.featureMap(4,:);
%             feaMap(5,:) = modelParams.featureMap(6,:)+modelParams.featureMap(7,:); % labial
%             feaMap(6,:) = modelParams.featureMap(9,:)+modelParams.featureMap(10,:)+modelParams.featureMap(11,:); % coronal
%             
%             for crossValid = 1:minSyl
%                 disp(sprintf('\b_'))
%                 trainIdx = ones(1,minSyl * 14); % 14 consonants
%                 trainIdx(find(mod((1:length(trainIdx))-crossValid,21)==0)) = 0;
%                 trainIdx = logical(trainIdx);
%                 testIdx = ~trainIdx;
%                 
% %                 [class, err] = classify(data(testIdx,:),data(trainIdx,:),ceil(labelSyl(condition).data(trainIdx)/2),'diagQuadratic');
% 
%                 for featureNum = 1:size(feaMap,1) % stop
%                     label2Classify = feaMap(featureNum,labelSyl(condition).data-28*(condition-1));
% 
%                     [class, err] = classify(data(testIdx,:),data(trainIdx,:),label2Classify(trainIdx),'diagLinear');
%         %             model = svmtrain(data(trainIdx,:),labelSyl(condition).data(trainIdx));
%         %             class = svmclassify(data(testIdx,:),data(trainIdx,:),labelSyl(condition).data(trainIdx),'diagQuadratic');
%                     if crossValid == 1
%                         conf(featureNum).data = confusionmat(class,label2Classify(testIdx));
%                     else
%                         conf(featureNum).data = conf(featureNum).data + confusionmat(class,label2Classify(testIdx));
%                     end
%                 end
%             end
%             for featureNum = 1:size(feaMap,1)
%                 label2Classify = feaMap(featureNum,labelSyl(condition).data-28*(condition-1));
% 
%                 acc(featureNum) = (conf(featureNum).data(1,1)+conf(featureNum).data(2,2))/(conf(featureNum).data(1,1)+conf(featureNum).data(1,2)+conf(featureNum).data(2,2)+conf(featureNum).data(2,1));
%                 ratio(featureNum) = length(find(label2Classify))/length(label2Classify);    
%             end
%             acc
%             ratio
% %             figure;surface(conf);
% 
% %                 conf = confusionmat(class,ceil(labelSyl(condition).data(testIdx)/2));
% %                 figure;surface(conf);
%         end
    end

end
