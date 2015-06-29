
clc;
close all
clear all

%%
% Data files parameters
modelParams.eegPath = '../data';
modelParams.audioPath = '../presentation'; %'../data/MM/stimuli';
modelParams.sgramFilters = './filters/sgram/sgramFilters.mat';
modelParams.subjectNames = {'MM'};
modelParams.fileFormat = ['mat']; % '.mat' because the files are in that format after the separation in trials and conditions
modelParams.nElectrodes = 34;

% Building elecPosFile
modelParams.elecPosFile = cell(1,length(modelParams.nElectrodes));
% modelParams.elecPosFile(modelParams.nElectrodes == 128) = cellstr('./HEADMAPS/chanlocs_128');
modelParams.elecPosFile(modelParams.nElectrodes == 34) = cellstr('./HEADMAPS/chanlocs_34');

modelParams.filesNum = 1:50; % 40 trials for each condition (slow / fast)
modelParams.fs = 1000; % Hz
modelParams.fsOrig = modelParams.fs;

% Preprocessing parameters
modelParams.bandPassfilter = 'BPF_1to25'; %'BSTOP50' %'BPF_05to25_stable'%'BPF_05to25_but'

% modelParams.highPassfilter = 'HPF_01';%'LPF_15';%'BPF_1to15'; %'BSTOP50' %'BPF_05to25_stable'%'BPF_05to25_but'
% modelParams.lowPassfilter = 'LPF_15';%'LPF_15';%'BPF_1to15'; %'BSTOP50' %'BPF_05to25_stable'%'BPF_05to25_but'
% modelParams.sgramFilters = './filters/sgram/sgramFilters.mat';
% 



% Ridge parameters
% ridgeEnv = 1;
% ridgeST  = 100;%100;
% ridgePh  = 10;%250;
% ridgeFea = 100;
% ridgeFS  = 250;

% Setting downsampling frequency and time lag
startLag = 0;
endLag = 400;

downFs = 1000;    % Hz - not in preprocessing, only in classification

freq = downFs;
lag_ms = [startLag, endLag]; % ms
lag = floor(freq*lag_ms(1)/1000):ceil(freq*lag_ms(2)/1000); % samples
lags_ms=lag/freq*1000; % labels for the plots
lag

modelParams.lag = lag;
modelParams.lags_ms = lags_ms;
modelParams.downFs = downFs;
% modelParams.ridgeEnv = ridgeEnv;
% modelParams.ridgeST  = ridgeST;
% modelParams.ridgePh  = ridgePh;
% modelParams.ridgeFea = ridgeFea;
% modelParams.ridgeFS  = ridgeFS;

verbose = 0;
subjects = [1];

featureMap = [1 1	0	1	1	0	0	1	1	0	0	0	0	0; ... % stop
            0	0	1	0	0	0	0	0	0	1	1	1	1	1; ... % fricative
            0	0	0	0	0	1	1	0	0	0	0	0	0	0; ... % nasal
            1	1	0	1	0	1	1	0	0	1	1	0	0	1; ... % voiced
            0	0	1	0	1	0	0	1	1	0	0	1	1	0; ... % voiceless
            1	0	0	0	0	1	0	1	0	0	0	0	0	0; ... % bilabial
            0	0	1	0	0	0	0	0	0	1	0	0	0	0; ... % labio-dental
            0	0	0	0	0	0	0	0	0	0	1	0	1	0; ... % lingua-dental
            0	1	0	0	0	0	1	0	1	0	0	0	0	1; ... % lingua-alveolar
            0	0	0	0	0	0	0	0	0	0	0	1	0	0; ... % lingua-palatal
            0	0	0	1	1	0	0	0	0	0	0	0	0	0];   % lingua-velar
modelParams.featureMap = zeros(size(featureMap,1),size(featureMap,2)*2);
for i=1:size(featureMap,2) % duplicate ('a' and 'e')
    modelParams.featureMap(:,i*2-1) = featureMap(:,i);
    modelParams.featureMap(:,i*2) = featureMap(:,i);
end

%% Preprocessing

modelParams.filesNum = 1:50;

preprocessEnv(modelParams);
preprocessSgram(modelParams);
modelParams = preprocessEEG_pilot3UW(modelParams, subjects, []); % Chopping + filtering

% exportEEG4ICA_3(modelParams, subjects);

% TODO: to Perform ICA here with EEG lab
% Issue: ICA requires downsampling (otherwise the data is too much)

% importEEGAfterICA_3(modelParams, subjects);

% noiseRemovalExport_3UW(modelParams, subjects, 0);

% preprocessEnv(modelParams, thresholdsToPreprocess);
% preprocessSgram(modelParams, thresholdsToPreprocess);
% preprocessPh(modelParams);
% modelParams = preprocessConcat(modelParams, subjects, [], 0);
% modelParams = preprocessPhConcat(modelParams, subjects, verbose); % stimSampleLength

%% Referencing
reference = 1; % 1: Global, 0: Mastoids, -1: none

if (reference == 1)
    disp('Using global reference')
elseif (reference == 0)
    disp('Using mastroids reference')
else
    disp('Warning: no references used!')
end

%% Epochs avg after preprocessing
verbose = 0;
epocsResult = epochsAvgPre_pilot2(modelParams, subjects, reference, verbose); % before preprocessing and after referencing

% Avg all phonemes
sub=1;
x = squeeze(mean(epocsResult.trialsAvg(sub,1).data));
figure;plot((x'))

x = squeeze(mean(epocsResult.trialsAvg(sub,2).data));
figure;plot((x'))

% Gfp ph comparison
clear toPlot
sub=1;
for condition = 1:2
    clear x
    for ph = 1:28
        x(ph,:,:) = squeeze(epocsResult.trialsAvg(sub,condition).data(ph,:,:));
    end

    stimulusName = {'ba','be','da','de','fa','fe','ga','ge','ka','ke','ma','me','na','ne','pa','pe','ta','te','va','ve','xda','xde','xsa','xse','xtxa','xtxe','za','ze'};
    figure; imagesc(squeeze(sum(x)))

    figure;
    for ph = 1:28
       subplot(5,6,ph)
       toPlot(ph,:) = (squeeze(mean(x(ph,avgElecMastoids,:),2)))';
       plot(toPlot(ph,:))
    end
    
    figure; imagesc(toPlot./repmat(std(toPlot'),size(toPlot,2),1)')
    
    set(gca,'yticklabel',[])
    set(gca,'YTick',1:28)
    yTicks = get(gca,'ytick');
    ax = axis; %Get left most x-position
    HorizontalOffset = 2;
    % Reset the ytick labels in desired font
%     for i = 1:length(yTicks)
%         %Create text box and set appropriate properties
%          text(ax(1) - HorizontalOffset,yTicks(i)+0.15,stimulusName(i),...
%              'HorizontalAlignment','Right','interpreter', 'tex');   
%     end
end

%% Canonical correlation
modelParams.filesNum = 1:10; % Subset used for canonical correlation (can't be used for classification)
trainCanonVar = trainCanon_3(modelParams, subjects, reference);


%% Simple classification (on groups of size 'm')
modelParams.filesNum = 11:50; % Subset used for canonical correlation (can't be used for classification)

maxLatency = endLag / 1000; % seconds
groupSize = 25;
% Classification
classificationResult = simpleClassification_3UW(modelParams, subjects, reference, downFs, maxLatency, groupSize, []); % before preprocessing and after referencing
% Classification with canonical correlation mapping
classificationResultCanon = simpleClassification_3UW(modelParams, subjects, reference, downFs, maxLatency, groupSize, trainCanonVar); % before preprocessing and after referencing

%% Forward model fit %%

% Training
verbose = 0;

% trainEnvelope
subjects = 1;
[trainDataEnv,modelParams] = trainEnv_pilot2(modelParams, subjects, reference, verbose);

stimulusName = {'ba','be','da','de','fa','fe','ga','ge','ka','ke','ma','me','na','ne','pa','pe','ta','te','va','ve','xda','xde','xsa','xse','xtxa','xtxe','za','ze'};
    

figure;imagesc(modelParams.lags_ms,1:28,squeeze(mean(trainDataEnv.trialsAvg(1,1).data(avgElecMastoids,:,:))))
set(gca,'yticklabel',[])
set(gca,'YTick',1:28)
yTicks = get(gca,'ytick');
ax = axis; %Get left most x-position
HorizontalOffset = 2;
% Reset the ytick labels in desired font
for i = 1:length(yTicks)
    %Create text box and set appropriate properties
     text(ax(1) - HorizontalOffset,yTicks(i)+0.15,stimulusName(i),...
         'HorizontalAlignment','Right','interpreter', 'tex');   
end
    
figure;imagesc(modelParams.lags_ms,1:28,squeeze(mean(trainDataEnv.trialsAvg(1,2).data(avgElecMastoids,:,:))))
set(gca,'yticklabel',[])
set(gca,'YTick',1:28)
yTicks = get(gca,'ytick');
ax = axis; %Get left most x-position
HorizontalOffset = 2;
% Reset the ytick labels in desired font
for i = 1:length(yTicks)
    %Create text box and set appropriate properties
     text(ax(1) - HorizontalOffset,yTicks(i)+0.15,stimulusName(i),...
         'HorizontalAlignment','Right','interpreter', 'tex');   
end
    
for condition = 1:2
    figure;
    for trial = 1:40
        subplot(5,10,trial)
        toPlot = squeeze(mean(trainDataEnv.trials(1,trial,condition).data(avgElecMastoids,:,:)));
        imagesc(modelParams.lags_ms,1:28,toPlot)
        caxis([-5,5])

        if trial == 1
    %         sumPlot = zscore(toPlot')';
            sumPlot2 = toPlot;
        else
    %         sumPlot = sumPlot + zscore(toPlot')';
            sumPlot2 = sumPlot2 + toPlot;
        end
    %     figure;imagesc(modelParams.lags_ms,1:28,squeeze(mean(trainDataEnv.trials(1,2).data(avgElecMastoids,:,:))))
    end

    % figure; imagesc(modelParams.lags_ms,1:28,sumPlot)
    figure; imagesc(modelParams.lags_ms,1:28,sumPlot2./repmat(std(sumPlot2'),size(sumPlot2,2),1)')

    set(gca,'yticklabel',[])
    set(gca,'YTick',1:28)
    yTicks = get(gca,'ytick');
    ax = axis; %Get left most x-position
    HorizontalOffset = 2;
    % Reset the ytick labels in desired font
    for i = 1:length(yTicks)
        %Create text box and set appropriate properties
         text(ax(1) - HorizontalOffset,yTicks(i)+0.15,stimulusName(i),...
             'HorizontalAlignment','Right','interpreter', 'tex');   
    end
end

%%
figPosition = [1649,275,620,500];
figPosition = figPosition-[1500,0,0,0];

title('Syllables discrete model - Fast presentation of CV','fontsize',14)
title('Syllables discrete model - Slow presentation of CV','fontsize',14)
title('Time-locked average - Fast presentation of CV','fontsize',14)
title('Time-locked average - Slow presentation of CV','fontsize',14)
xlabel('Time [ms]','fontsize',14);
% ylabel('Phonemes','fontsize',14)
set(gcf,'color','w');
set(findobj(gca,'type','line'), 'LineWidth', 3);
set(gcf,'OuterPosition',figPosition);export_fig('-tif','-r150', 'phFast')


