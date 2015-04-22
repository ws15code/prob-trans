% Author:  Giovanni Di Liberto
% Date:    03/03/2015
% Project: WS15 - pilot 1
%
% This code performs the preprocessing of the EEG data

function modelParams = preprocessEEG_pilot2(modelParams, subjectsIdx, rejectedChannels)
    load(['filters/' modelParams.bandPassfilter]);
    conditionLabel = {'noTask';'task'};
    
    for subIndex=subjectsIdx
        % Given a subject - for each input file
        for file_index = modelParams.filesNum
            for condition = 1:2
                % Dealing with the eeg
                % Loading eeg file
                if strcmp(modelParams.fileFormat(subIndex,:), 'mat')
                    filename = [modelParams.eegPath '/' (modelParams.subjectNames{subIndex}) ... 
                        '/' (modelParams.subjectNames{subIndex}) '_' cell2mat(conditionLabel(condition)) ...
                        '_' num2str(file_index) '.mat'];
                    disp(['Preprocessing ' filename]);
                    load(filename); % eeg, localTrig
                    eegData = double(eeg);
                    
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

%                 % Removing badChannels
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
%                 % Downsampling % The later the better
% %                 eegData = resample(double(eegData)', modelParams.downFs, modelParams.fs, 0)';
% %                 mastoids = resample(double(mastoids)', modelParams.downFs, modelParams.fs, 0)';
% %                 eegData = downsample(double(eegData)', modelParams.fs/modelParams.downFs)';
% %                 mastoids = downsample(double(mastoids)', modelParams.fs/modelParams.downFs)';
% %                 localTrig = downsample(double(localTrig)', modelParams.fs/modelParams.downFs)';
% % 
% %                 fs = modelParams.downFs;
% 
%                 
% 
                fs = modelParams.fs;
%                 
%                 % Removing polinomial trends
% %                 eeg = nt_detrend([eegData;mastoids],50);%,w,basis);
% %                 eegData = eeg(1:128,:);
% %                 mastoids = eeg(129:130,:);
% %                 clear eeg
                
                
                save(strcat(filename(1:end-4), ['_preprocessed' modelParams.bandPassfilter '.mat']), 'eegData', 'startSample', 'endSample', 'fs', 'mastoids', 'localTrig');
            end
        end
    end
end

