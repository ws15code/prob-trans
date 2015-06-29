% Author:  Giovanni Di Liberto
% Date:    03/03/2015
% Project: Vocoding Project
%
% This code extracts from the speech data its amplitude envelope. The
% Hilbert transform is used to get the analytical (complex) signal of the
% speech waveform. The amplitude of the analytical signal is referred as
% 'amplitude envelope', or simply 'envelope'.

function preprocessEnv(modelParams)
    stimulusName = {'ba','be','da','de','fa','fe','ga','ge','ka','ke','ma','me','na','ne','pa','pe','ta','te','va','ve','xda','xde','xsa','xse','xtxa','xtxe','za','ze'};
    for ph = 1:28
        % Dealing with the audio-based stimuli
        % Loading the input stimulus audio-based - clean
        auFilename = [modelParams.audioPath '/s_m102_' cell2mat(stimulusName(ph)) '.sph.wav'];
%         disp(['Audio file ' auFilename]);
        [auData,auFreq] = audioread(auFilename);
%         audio2Env(modelParams,auData,auFreq,auFilename);
        speech2spectro(modelParams, auData, auFreq, auFilename);

    end
end

% Preprocess function given the audio files in the folder 'audioPath'
% and the bandpass filters in 'STRFfilters'
%      >> speech2spectro('./STRFfilters',speechEnvelope', 512, 512)
function speech2spectro(modelParams, auData, auFreq, auFilename)
    load(modelParams.sgramFilters)
    for i = 1:length(Hd)
        disp(['Band' num2str(i) ': ' num2str(Fpass1(i)) '-' num2str(Fpass2(i))]);

        % Filtering
        filtAuData = filtfilthd(Hd(i), auData);

        % Getting the signal envelope
        hTrans = hilbert(mean(filtAuData,2));
        envelope = abs(hTrans); % Getting the average of the two stereo channels
%         fineStructure = angle(mean(hTrans,2)); % Getting the average of the two stereo channels

        % Filtering + downsampling the signal
        envelope = resample(envelope, modelParams.fs, auFreq);
%         fineStructure = resample(fineStructure, fs, auFreq);

        % Filtering artifact correction - the envelope of an auditory
        % stimulus can't have negative values
        origLength = length(envelope);
        envelope(envelope < 0) = 0;
        
        idx = i; %1+(i-1)*2;
        sgram(idx,:) = envelope;
%         STRFstimuli(idx+1,:) = fineStructure;
    end
    
    fsSgram = modelParams.fs;
    
    % Saving preprocessed stimuli
    figure; imagesc(flip(sgram,1));
    
    filename = [auFilename(1:end-4) '_sgram.mat'];
    disp(['Saving ' filename]);
    save(filename, 'sgram', 'fsSgram', 'origLength');
end
