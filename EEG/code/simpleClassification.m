% Author:  Giovanni Di Liberto
% Date:    19/01/2015
% Project: Vocoding Project
%
% For each subject (vector of integers), this method fits a linear
% regression model which maps the amplitude envelope representation of the
% speech signal to the correspondent recorded EEG

function classificationResult = simpleClassification(modelParams, subjectsIdx, reference, downFreq, maxLatency, groupSize, trainCanonVar)
    conditionLabel = {'noTask';'task'};
    
    canon = true;
    interval = 1:50; %1:50;
    avgElecMastoids = [61:63 54:56 106:108 115:117]; 
    
    dataFreq = modelParams.fs; %fsOrig;
    erpLengthDown = round(downFreq*maxLatency); % maxLatency has to be in seconds
    erpLength = round(dataFreq*maxLatency);
    
    disp('Running epochsAvg function')
    for subIndex = subjectsIdx
        % Resetting previous counters
        if canon
            erp(1).data = zeros(0,1,length(interval));%erpLengthDown); % condition, erp, elec, timeWin500 ms
            erp(2).data = zeros(0,1,length(interval));%erpLengthDown); % condition, erp, elec, timeWin500 ms
        else
            erp(1).data = zeros(0,length(avgElecMastoids),length(interval)); % condition, erp, elec, timeWin500 ms
            erp(2).data = zeros(0,length(avgElecMastoids),length(interval)); % condition, erp, elec, timeWin500 ms
        end
        labelSyl(1).data = []; % array which contains the syllables lables for each 'erp'
        labelSyl(2).data = [];
        
        fileCount = 1;

        disp(['Subject ', num2str(subIndex)])

        % Given a subject - for each input file
        for fileIndex = modelParams.filesNum
            fileIndex
            disp(sprintf('\b.'))
            
            for condition = 1:2
                % Loading eeg
                filename = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
                        '/' (modelParams.subjectNames{subIndex}) '_' cell2mat(conditionLabel(condition)) ...
                        '_' num2str(fileIndex) '.' modelParams.fileFormat(subIndex,:)];
                load(strcat(filename(1:end-4), ['_preprocessed' modelParams.bandPassfilter '_afterNoiseRemoval.mat']))
                
                % Reference each electrodes:
                if (reference == 1)
                    eegData = double(eegData-repmat(squeeze(mean(eegData,1)),[modelParams.nElectrodes(subIndex) 1])); 
                elseif (reference == 0)
                    eegData = double(eegData-repmat(squeeze(mean(mastoids,1)),[modelParams.nElectrodes(subIndex) 1])); 
                end
                
                trigs = diff(localTrig);
                trigs(trigs<0) = 0;
                trigs(1) = localTrig(1); % diff doesn't work for the first state
                for syl = 1:28
                    phIdxs(syl).idxs = find(trigs==syl+100);
%                     length(phIdxs(ph).idxs)
                end
                                
%                 eegData = downsample(eegData',dataFreq/downFreq)';
                % Canonical correlation
                if canon
                    B = trainCanonVar.B(condition).data;
                    % V = (Y - repmat(mean(Y),N,1))*B
                    Y = eegData';
                    N = size(Y,1);
                    eegData = ((Y-repmat(mean(Y),N,1))*B)';
                end

                for syl = 1:28
                    for idx = phIdxs(syl).idxs
                        tmpData = eegData(:,idx:idx+erpLength-1);
                        tmpData = tmpData(:,interval);
                        if ~canon
                            tmpData = tmpData(avgElecMastoids,:);
                        end
                        erp(condition).data(size(erp(condition).data,1)+1,:,:) = tmpData;
                        labelSyl(condition).data(size(labelSyl(condition).data)+1) = syl;
                    end
                end
            end
            
            fileCount = fileCount + 1;
        end

        % Concat
        labelSyl(3).data = [labelSyl(1).data,labelSyl(2).data];
        erp(3).data = [erp(1).data;erp(2).data];
        
        % Is this cut needed after the change to pool avg?
        minLength = min(length(labelSyl(1).data),length(labelSyl(2).data));
        labelSyl(1).data = labelSyl(1).data(1:minLength);
        labelSyl(2).data = labelSyl(2).data(1:minLength);
        erp(1).data = erp(1).data(1:minLength,:,:); % forward % TODO: to check
        erp(2).data = erp(2).data(1:minLength,:,:);  % time-reversed

        % Preparing the 'groupSize' erp matrix
        for condition = 1:2
            % Same size, but averaged over a number of repetitions
            newErp(condition).data = zeros(size(erp(condition).data)); % ~180 repetition for each consonant
            
            [~,idx] = sort(labelSyl(condition).data);
            labelSyl(condition).data = labelSyl(condition).data(idx);
            erp(condition).data = erp(condition).data(idx,:,:,:);
            
            i = 1;
            while i <= length(labelSyl(condition).data)-groupSize
%                 if labelSyl(condition).data(i) == labelSyl(condition).data(i+groupSize-1)
                currentPh = labelSyl(condition).data(i);
                if mod(currentPh,2) == 0 % even number
                    currentPh = currentPh - 1; % the consonant is the same
                end
                firstPhIdx = find(labelSyl(condition).data == currentPh,1,'first');
                lastPhIdx = find(labelSyl(condition).data == currentPh+1,1,'last');
                
                phIdx = randi(lastPhIdx-firstPhIdx+1,1,groupSize)+firstPhIdx-1;
                % avg replace each row
                newErp(condition).data(i,:,:) = mean(erp(condition).data(phIdx,:,:),1);
                labelSyl(condition).data(i) = labelSyl(condition).data(i);

                i = i + 1;
            end
            erp(condition).data = newErp(condition).data;
            clear newErp(condition).data
            % Cut unused rows
%             erp(condition).data = erp(condition).data(1:erpCount,:,:);
%             labelSyl(condition).data = labelSyl(condition).data(1:erpCount);
            
            % MDS
            %data = squeeze(erp(condition).data(:,60,:));
%             data = reshape(erp(condition).data,size(erp(condition).data,1),size(erp(condition).data,3)*size(erp(condition).data,2));
            
            if ~canon
                data = erp(condition).data(:,:,:);%[3:9,18:28]);
                data = reshape(data,size(data,1),size(data,3)*size(data,2));
            end
            
            % Canonical correlation
            data = erp(condition).data;
            data = reshape(data,size(data,1),size(data,3)*size(data,2));
            
            Y = pdist(data, 'euclidean');
            [x,~] = mdscale(Y,128); % multidimensional scaling ph features
%%
%             figure;
% %             colors = ['r','r','m','m','b','b','g','g','c','c','k','K','y','y','r','r','m','m','b','b','g','g','c','c','k','K','y','y','r','r','m','m','b','b','g','g','c','c','k','K','y','y','r','r','m','m','b','b','g','g','c','c','k','K','y','y'];
%             colors = ['r','b'];
% 
%             dim1 = 2;
%             dim2 = 3;
%             fea = 4;
%             
%             markerSize = 50;
%             scatter(x(:,dim1),x(:,dim2),markerSize,'w','filled'); hold on
%             
%             title('MDS syllables','fontsize',14)
%             
%             stimulusName = {'ba','be','da','de','fa','fe','ga','ge','ka','ke','ma','me','na','ne','pa','pe','ta','te','va','ve','xda','xde','xsa','xse','xtxa','xtxe','za','ze'};
%             for i = 1:28
% %                 text(x(labelSyl(condition).data==i,dim1),x(labelSyl(condition).data==i,dim2), stimulusName(i), 'horizontal','left', 'vertical','bottom','FontSize',20,'Color',colors(feaMap(1,i)+1))
%                 scatter(x(labelSyl(condition).data==i,dim1),x(labelSyl(condition).data==i,dim2), markerSize, colors(feaMap(fea,i)+1),'filled')
%             end
            %%
%             % Random train/test division
%             tmp = 1:length(labelSyl(condition).data);
%             tmp = tmp(randperm(length(tmp)));
%             trainIdx = tmp(1:floor(length(tmp)/2));
%             testIdx  = tmp(floor(length(tmp)/2)+1:end);

            % Preparing for cross-valid
            % same # presentations for each syl
            tmp = labelSyl(condition).data;
            tmp = [1,diff(tmp)];
            findTmp = find(tmp);
            findTmp = findTmp(find(mod(1:length(findTmp),2))); % start idx for each consonant (eg. 'ba', 'be')
            findTmp2 = [findTmp(2:end), length(tmp)+1];
            minSyl = min(findTmp2-findTmp);
            % Removing extra pairs
            count = 0;
            for i=1:length(labelSyl(condition).data)
                count = count + 1;
                if sum(findTmp==i) % new consonant
                    count = 1;
                end
                if count > minSyl
                    idxToKeep(i) = 0;
                else
                    idxToKeep(i) = 1;
                end
            end
            labelSyl(condition).data = labelSyl(condition).data(find(idxToKeep));
            data = data(find(idxToKeep),:);

            feaMap(1,:) = modelParams.featureMap(1,:);
            feaMap(2,:) = modelParams.featureMap(2,:);
            feaMap(3,:) = modelParams.featureMap(3,:);
            feaMap(4,:) = modelParams.featureMap(4,:);
            feaMap(5,:) = modelParams.featureMap(6,:)+modelParams.featureMap(7,:); % labial
            feaMap(6,:) = modelParams.featureMap(9,:)+modelParams.featureMap(10,:)+modelParams.featureMap(11,:); % coronal
            
            for crossValid = 1:minSyl
                trainIdx = ones(1,minSyl * 14); % 14 consonants
                trainIdx(find(mod((1:length(trainIdx))-crossValid,21)==0)) = 0;
                trainIdx = logical(trainIdx);
                testIdx = ~trainIdx;
                
%                 [class, err] = classify(data(testIdx,:),data(trainIdx,:),ceil(labelSyl(condition).data(trainIdx)/2),'diagQuadratic');

                for featureNum = 1:size(feaMap,1) % stop
                    label2Classify = feaMap(featureNum,labelSyl(condition).data);

                    [class, err] = classify(data(testIdx,:),data(trainIdx,:),label2Classify(trainIdx),'diagLinear');
        %             model = svmtrain(data(trainIdx,:),labelSyl(condition).data(trainIdx));
        %             class = svmclassify(data(testIdx,:),data(trainIdx,:),labelSyl(condition).data(trainIdx),'diagQuadratic');
                    if crossValid == 1
                        conf(featureNum).data = confusionmat(class,label2Classify(testIdx));
                    else
                        conf(featureNum).data = conf(featureNum).data + confusionmat(class,label2Classify(testIdx));
                    end
                end
            end
            
            for featureNum = 1:size(feaMap,1)
                label2Classify = feaMap(featureNum,labelSyl(condition).data);

                acc(featureNum) = (conf(featureNum).data(1,1)+conf(featureNum).data(2,2))/(conf(featureNum).data(1,1)+conf(featureNum).data(1,2)+conf(featureNum).data(2,2)+conf(featureNum).data(2,1));
                ratio(featureNum) = length(find(label2Classify))/length(label2Classify);    
            end
            acc
            ratio
%             figure;surface(conf);

%                 conf = confusionmat(class,ceil(labelSyl(condition).data(testIdx)/2));
%                 figure;surface(conf);
        end
    end

end
