% Generate stimulus trials code

% Load presentation order
load('order.mat')

% Load syllables
stimulusName = {'ba','be','da','de','fa','fe','ga','ge','ka','ke','ma','me','na','ne','pa','pe','ta','te','va','ve','xda','xde','xsa','xse','xtxa','xtxe','za','ze'};
for i = 1:28
    auFilename 
    = ['./s_m102_' cell2mat(stimulusName(i)) '.sph.wav'];
    [auData(i).data,auFreq] = audioread(auFilename);
end
for i = 1:28
    auFilename = ['./reverse/s_m102_' cell2mat(stimulusName(i)) '.sph.wav'];
    [auDataRev(i).data,auFreq] = audioread(auFilename);
end

%% Slow - Fast experiment
% Slow condition
nTrials = 50;          % number of trials to generate for this condition
sylPerTrial = 80;      % how many syllables for each trial
silenceLen = 400;      % gap [ms] between syllables
silenceMaxJitter = 50; % max jitter for the gap between syllables (plus or minus)

idxSyl = 1;
orderIdx = order1; % this is the pseudorandom order used in the experiment here. This can be changed indeed
for trial = 1:nTrials
    audioConcat = [];
    sylCode = [];
    startIdx = [];
    for i = 1:sylPerTrial
        % Concat syllable
        currentSyl = auData(orderIdx(idxSyl)).data;
        sylCode(i) = orderIdx(idxSyl);
        startIdx(i) = size(audioConcat,1)+1;
        
        audioConcat = [audioConcat;currentSyl];
        % Concat silence
        currentJitter = (rand*2-1)*silenceMaxJitter; % ms
        currentGap = silenceLen + currentJitter; % ms
        currentGap = currentGap/1000*auFreq; % samples
        audioConcat = [audioConcat;zeros(round(currentGap),2)];
        
        idxSyl = idxSyl + 1;
    end
    % Output trial audio file
    audiowrite(['slowFast_slow_' num2str(trial) '.wav'],audioConcat,auFreq);
    % Output trigger variable
    save(['slowFast_slow_' num2str(trial) '.mat'],'startIdx','sylCode')
end

% Fast condition
nTrials = 50;
sylPerTrial = 140;
silenceLen = 100;
silenceMaxJitter = 50;
idxSyl = 1;
orderIdx = order2;
for trial = 1:nTrials
    audioConcat = [];
    sylCode = [];
    startIdx = [];
    for i = 1:sylPerTrial
        % Concat syllable
        currentSyl = auData(orderIdx(idxSyl)).data;
        sylCode(i) = orderIdx(idxSyl);
        startIdx(i) = size(currentSyl,1)+1;
        
        audioConcat = [audioConcat;currentSyl];
        % Concat silence
        currentJitter = (rand*2-1)*silenceMaxJitter; % ms
        currentGap = silenceLen + currentJitter; % ms
        currentGap = currentGap/1000*auFreq; % samples
        audioConcat = [audioConcat;zeros(round(currentGap),2)];
        
        idxSyl = idxSyl + 1;
    end
    % Output trial audio file
    audiowrite(['slowFast_fast_' num2str(trial) '.wav'],audioConcat,auFreq);
    % Output trigger variable
    save(['slowFast_fast_' num2str(trial) '.mat'],'startIdx','sylCode')
end

%% NoTask VS Task
% slow - noTask
nTrials = 50;
sylPerTrial = 80;
silenceLen = 350;
silenceMaxJitter = 50;
idxSyl = 1;
orderIdx = order2;
for trial = 1:nTrials
    audioConcat = [];
    sylCode = [];
    startIdx = [];
    for i = 1:sylPerTrial
        % Concat syllable
        currentSyl = auData(orderIdx(idxSyl)).data;
        sylCode(i) = orderIdx(idxSyl);
        startIdx(i) = size(audioConcat,1)+1;
        
        audioConcat = [audioConcat;currentSyl];
        % Concat silence
        currentJitter = (rand*2-1)*silenceMaxJitter; % ms
        currentGap = silenceLen + currentJitter; % ms
        currentGap = currentGap/1000*auFreq; % samples
        audioConcat = [audioConcat;zeros(round(currentGap),2)];
        
        idxSyl = idxSyl + 1;
    end
    % Output trial audio file
    audiowrite(['slowTask_' num2str(trial) '.wav'],audioConcat,auFreq);
    % Output trigger variable
    save(['slowTask_' num2str(trial) '.mat'],'startIdx','sylCode')
end

% slow task
nTrials = 50;
sylPerTrial = 80;
silenceLen = 350;
silenceMaxJitter = 50;
idxSyl = 1;
orderIdx = order1;
for trial = 1:nTrials
    audioConcat = [];
    sylCode = [];
    startIdx = [];
    for i = 1:sylPerTrial
        % Concat syllable
        currentSyl = auData(orderIdx(idxSyl)).data;
        sylCode(i) = orderIdx(idxSyl);
        startIdx(i) = size(audioConcat,1)+1;
        
        audioConcat = [audioConcat;currentSyl];
        % Concat silence
        currentJitter = (rand*2-1)*silenceMaxJitter; % ms
        currentGap = silenceLen + currentJitter; % ms
        currentGap = currentGap/1000*auFreq; % samples
        audioConcat = [audioConcat;zeros(round(currentGap),2)];
        
        idxSyl = idxSyl + 1;
    end
    % Output trial audio file
    audiowrite(['slowNoTask_' num2str(trial) '.wav'],audioConcat,auFreq);
    % Output trigger variable
    save(['slowNoTask_' num2str(trial) '.mat'],'startIdx','sylCode')
end

%% Forward vs Time reversed
% Part1
nTrials = 50;
sylPerTrial = 80;
silenceLen = 350;
silenceMaxJitter = 50;
idxSyl = 1;
orderIdx = order1;
for trial = 1:nTrials
    audioConcat = [];
    sylCode = [];
    startIdx = [];
    for i = 1:sylPerTrial
        % Concat syllable
        if (rand > 0.5)
            currentSyl = auData(orderIdx(idxSyl)).data;
            sylCode(i) = orderIdx(idxSyl);
        else
            currentSyl = auDataRev(orderIdx(idxSyl)).data;
            sylCode(i) = orderIdx(idxSyl)+28;
        end
        startIdx(i) = size(audioConcat,1)+1;
        
        audioConcat = [audioConcat;currentSyl];
        % Concat silence
        currentJitter = (rand*2-1)*silenceMaxJitter; % ms
        currentGap = silenceLen + currentJitter; % ms
        currentGap = currentGap/1000*auFreq; % samples
        audioConcat = [audioConcat;zeros(round(currentGap),2)];
        
        idxSyl = idxSyl + 1;
    end
    % Output trial audio file
    audiowrite(['slowForRevPart1_' num2str(trial) '.wav'],audioConcat,auFreq);
    % Output trigger variable
    save(['slowForRevPart1_' num2str(trial) '.mat'],'startIdx','sylCode')
end


% Part2
nTrials = 50;
sylPerTrial = 80;
silenceLen = 350;
silenceMaxJitter = 50;
idxSyl = 1;
orderIdx = order2;
for trial = 1:nTrials
    audioConcat = [];
    sylCode = [];
    startIdx = [];
    for i = 1:sylPerTrial
        % Concat syllable
        if (rand > 0.5)
            currentSyl = auData(orderIdx(idxSyl)).data;
            sylCode(i) = orderIdx(idxSyl);
        else
            currentSyl = auDataRev(orderIdx(idxSyl)).data;
            sylCode(i) = orderIdx(idxSyl)+28;
        end
        startIdx(i) = size(audioConcat,1)+1;
        
        audioConcat = [audioConcat;currentSyl];
        % Concat silence
        currentJitter = (rand*2-1)*silenceMaxJitter; % ms
        currentGap = silenceLen + currentJitter; % ms
        currentGap = currentGap/1000*auFreq; % samples
        audioConcat = [audioConcat;zeros(round(currentGap),2)];
        
        idxSyl = idxSyl + 1;
    end
    % Output trial audio file
    audiowrite(['slowForRevPart2_' num2str(trial) '.wav'],audioConcat,auFreq);
    % Output trigger variable
    save(['slowForRevPart2_' num2str(trial) '.mat'],'startIdx','sylCode')
end
