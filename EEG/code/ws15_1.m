
clc;
close all
clear all

%%
% Data files parameters
modelParams.eegPath = '/media/System/WS15/eeg';
modelParams.audioPath = '/media/System/WS15/stimuli';
modelParams.subjectNames = {'GD'};
modelParams.fileFormat = ['mat']; % '.mat' because the files are in that format after the separation in trials and conditions
modelParams.nElectrodes = [128];

% Building elecPosFile
modelParams.elecPosFile = cell(1,length(modelParams.nElectrodes));
modelParams.elecPosFile(modelParams.nElectrodes == 128) = cellstr('/media/System/WS15/eeg/HEADMAPS/chanlocs_128');

modelParams.filesNum = 1:50; % 50 trials for each condition (slow / fast)
modelParams.fs = 512; % Hz
modelParams.fsOrig = modelParams.fs;

% Preprocessing parameters
modelParams.bandPassfilter = 'BPF_1to15'; %'BSTOP50' %'BPF_05to25_stable'%'BPF_05to25_but'

% modelParams.highPassfilter = 'HPF_01';%'LPF_15';%'BPF_1to15'; %'BSTOP50' %'BPF_05to25_stable'%'BPF_05to25_but'
% modelParams.lowPassfilter = 'LPF_15';%'LPF_15';%'BPF_1to15'; %'BSTOP50' %'BPF_05to25_stable'%'BPF_05to25_but'
% modelParams.sgramFilters = './filters/sgram/sgramFilters.mat';

startLag = -150;
endLag = 600;


% Ridge parameters
ridgeEnv = 1;
% ridgeST  = 100;%100;
% ridgePh  = 10;%250;
% ridgeFea = 100;
% ridgeFS  = 250;

% Setting downsampling frequency and time lag
downFs = 128;    % Hz

freq = downFs;
lag_ms = [startLag, endLag]; % ms
lag = floor(freq*lag_ms(1)/1000):ceil(freq*lag_ms(2)/1000); % samples
lags_ms=lag/freq*1000; % labels for the plots
lag

modelParams.lag = lag;
modelParams.lags_ms = lags_ms;
modelParams.ridgeEnv = ridgeEnv;
% modelParams.ridgeST  = ridgeST;
% modelParams.ridgePh  = ridgePh;
% modelParams.ridgeFea = ridgeFea;
% modelParams.ridgeFS  = ridgeFS;
modelParams.downFs = downFs;

%% Preprocessing
verbose = 0;
subjects = [1];
% preprocess eeg
modelParams = preprocessEEG_pilot1(modelParams, subjects, []);
preprocessEnv(modelParams);

% preprocessEnv(modelParams, thresholdsToPreprocess);
% preprocessSgram(modelParams, thresholdsToPreprocess);
% preprocessPh(modelParams);
% modelParams = preprocessConcat(modelParams, subjects, [], 0);
% modelParams = preprocessPhConcat(modelParams, subjects, verbose); % stimSampleLength

%% ICA export/import
% toExport = false;
% modelParams = exportForICA(modelParams,128,toExport);
% modelParams = importAfterICA(modelParams,128);

%% Referencing
% reference = 1; % Global
reference = 0; % Mastoids
% reference = -1; % None
if (reference == 1)
    disp('Using global reference')
elseif (reference == 0)
    disp('Using mastroids reference')
else
    disp('Warning: no references used!')
end

%%

% avgElecMastoids = [61:63 54:56]; % right
avgElecMastoids = [61:63 54:56 106:108 115:117]; % [49,49];
% avgElecMastoids = [106:108 115:117]; % left
% avgElecGlobalFront = [63 64 108 109];


%% Epochs avg
verbose = 0;
epocsResult = epochsAvg(modelParams, subjects, reference, verbose); % before preprocessing and after referencing

sub=1;
x = epocsResult.trialsAvg(sub,1).data;
figure;plot(detrend(x'))
figure;plot(detrend(x(60,:)))
figure;plot(x')

x = epocsResult.trialsAvg(sub,2).data;
figure;plot(detrend(x'))
figure;plot(detrend(x(60,:)))
figure;plot(x')



%% Epochs avg after preprocessing
verbose = 0;
modelParams.filesNum = [1:28,30,32:33,35:50];
epocsResult = epochsAvgPre(modelParams, subjects, reference, verbose); % before preprocessing and after referencing

% Avg all phonemes
sub=1;
x = squeeze(mean(epocsResult.trialsAvg(sub,1).data));
figure;plot(detrend(x'))
% figure;plot(detrend(x(60,:)))
% figure;plot(x')

x = squeeze(mean(epocsResult.trialsAvg(sub,2).data));
figure;plot(detrend(x'))
% figure;plot(detrend(x(60,:)))
% figure;plot(x')

% Gfp ph comparison
clear toPlot
sub=1;
for condition = 1:2
    clear x
    for ph = 1:28
        x(ph,:,:) = squeeze(epocsResult.trialsAvg(sub,condition).data(ph,:,:));
    end

    figure; imagesc(squeeze(sum(x)))

    figure;
    for ph = 1:28
       subplot(5,6,ph)
       toPlot(ph,:) = detrend(squeeze(mean(x(ph,avgElecMastoids,:),2)))';
       plot(toPlot(ph,:))
    end
    
    figure; imagesc(toPlot./repmat(std(toPlot'),size(toPlot,2),1)')
    
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

%% Forward model fit %%

% Training
verbose = 0;

% trainEnvelope
subjects = 1;
[trainDataEnv,modelParams] = trainEnv(modelParams, subjects, reference, verbose);

figure;imagesc(modelParams.lags_ms,1:28,squeeze(mean(trainDataEnv.trialsAvg(1,1).data(avgElecMastoids,:,:))))
figure;imagesc(modelParams.lags_ms,1:28,squeeze(mean(trainDataEnv.trialsAvg(1,2).data(avgElecMastoids,:,:))))

for condition = 1:2
    figure;
    for trial = [1:28,30,32:33,35:50]
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
    stimulusName = {'ba','be','da','de','fa','fe','ga','ge','ka','ke','ma','me','na','ne','pa','pe','ta','te','va','ve','xda','xde','xsa','xse','xtxa','xtxe','za','ze'};
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


