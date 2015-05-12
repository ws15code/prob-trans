% Author:  Giovanni Di Liberto
% Date:    19/01/2015
% Project: Vocoding Project
%
% This code splits the raw eeg into trials and conditions

clc
close all
clear all

subj = 'GDreverse';

currentTrialNumber = 0;

for fileIdx = 1:2
    % Reading raw .bdf file
    fileName = ['./' subj '/original/' subj num2str(fileIdx) '.bdf'];
    [EEG_raw, trigs] = Read_bdf(fileName);

    % Getting triggers
%     trigs2 = trigs;
    trigs=trigs-min(trigs);
    trigs(trigs>256) = trigs(trigs>256)-min(trigs(trigs>256));
    trigs(trigs>256) = trigs(trigs>256)-min(trigs(trigs>256));

    % Trick to add trial numbers
	x=diff(trigs);
%     x(x==254);
%     trigs(find(x==254)) = [222,222,1:100]; % The first two trials were repeated
    trialsIdxStart = find(x==254);
%     if fileIdx == 1
%         trialsIdxStart = trialsIdxStart(3:end); % The first two trials were repeated
%     end
    trialsIdxEnd = [trialsIdxStart(2:end)-8,length(trigs)];
    trialsIdxEnd - trialsIdxStart; % This should give us the trial length.. why is the variability so bad? Anyway, We trust the 254 as trial start, that should be guaranteed

    % For each trial Slow
    trialCount = 1;
    for i = 1:length(trialsIdxStart);
        trialCount
        
        startSample = trialsIdxStart(i);
        endSample = trialsIdxEnd(i);

        eeg = EEG_raw(:,startSample:endSample);
        localTrig = trigs(:,startSample:endSample);
        
        % Channel swap (if needed)
%          eeg(135,:) = eeg(129,:);
%          eeg(136,:) = eeg(130,:);
        
        if fileIdx == 1
            outputFileName = ['./' subj '/' subj '_part1_' num2str(trialCount) '.mat'];
        elseif fileIdx == 2
            outputFileName = ['./' subj '/' subj '_part2_' num2str(trialCount) '.mat'];
        end
        save(outputFileName, 'eeg', 'localTrig');
        
        trialCount = trialCount + 1;
    end
end