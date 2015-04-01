% Author:  Giovanni Di Liberto
% Date:    19/01/2015
% Project: Vocoding Project
%
% This code splits the raw eeg into trials and conditions

clc
close all
clear all

subj = 'GDtask'; % be careful: with Martin, no padding at the end of the trial

currentTrialNumber = 0;

for fileIdx = 1:1
    % Reading raw .bdf file
    fileName = ['/media/diliberg/System/WS15/eeg/' subj '/original/' subj num2str(fileIdx) '.bdf'];
    [EEG_raw, trigs] = Read_bdf(fileName);

    % Getting triggers
%     trigs2 = trigs;
    trigs=trigs-min(trigs);
    trigs(trigs>256) = trigs(trigs>256)-min(trigs(trigs>256));
    trigs(trigs>256) = trigs(trigs>256)-min(trigs(trigs>256));

    % Trick to add trial numbers
	x=diff(trigs);
    x(x==254);
    trigs(find(x==254)) = [222,222,1:100]; % The first two trials were repeated

    % Separating Fast and slow
    slowTrialsIdxStart = [find(trigs>=1 & trigs<=25), find(trigs>=76 & trigs<=100)];
    fastTrialsIdxStart = find(trigs>=26 & trigs<=75);
    
    slowTrialsIdxEnd = [find(trigs>=2 & trigs<=26)-1, find(trigs>=77 & trigs<=100)-1, length(trigs)];
    fastTrialsIdxEnd = find(trigs>=27 & trigs<=76)-1;
    
    % For each trial Fast
    trialCount = 1;
    for i = 1:length(fastTrialsIdxStart);
        startSample = fastTrialsIdxStart(i);
        endSample = fastTrialsIdxEnd(i);

        eeg = EEG_raw(:,startSample:endSample);
        localTrig = trigs(:,startSample:endSample);
        
        % Channel swap (if needed)
%          eeg(135,:) = eeg(129,:);
%          eeg(136,:) = eeg(130,:);
        
        outputFileName = ['/media/diliberg/System/WS15/eeg/' subj '/' subj '_fast_' num2str(trialCount) '.mat'];
        save(outputFileName, 'eeg', 'localTrig');
        
        trialCount = trialCount + 1;
    end
    
    % For each trial Slow
    trialCount = 1;
    for i = 1:length(slowTrialsIdxStart);
        startSample = slowTrialsIdxStart(i);
        endSample = slowTrialsIdxEnd(i);

        eeg = EEG_raw(:,startSample:endSample);
        localTrig = trigs(:,startSample:endSample);
        
        % Channel swap (if needed)
%          eeg(135,:) = eeg(129,:);
%          eeg(136,:) = eeg(130,:);
        
        outputFileName = ['/media/diliberg/System/WS15/eeg/' subj '/' subj '_slow_' num2str(trialCount) '.mat'];
        save(outputFileName, 'eeg', 'localTrig');
        
        trialCount = trialCount + 1;
    end
end