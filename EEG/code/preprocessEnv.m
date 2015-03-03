% Author:  Giovanni Di Liberto
% Date:    19/01/2015
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
        audio2Env(modelParams,auData,auFreq,auFilename);
    end
end

function audio2Env(modelParams,auData,auFreq,auFilename)
    % Getting the signal envelope
    hTrans = hilbert(mean(auData,2));
%   envelope = angle(hTrans); % I take the average of the 2 stereo channels
    envelope = abs(hTrans);   % I take the average of the 2 stereo channels

    % Filtering + downsampling the signal
    fsEnv = modelParams.fs;
    envelope = resample(envelope, fsEnv, auFreq);

    % Artifact correction - the envelope of an auditory
    % stimulus can't have negative values
    envelope(envelope < 0) = 0;

    % Chopping off the tail of the experiment
    origLength = length(envelope);
%     envelope = envelope(1:modelParams.trialsDuration*fsEnv); 

    % Saving preprocessed stimuli
    filename = [auFilename(1:end-4) '_env.mat'];
    disp(['Saving ' filename]);
    save(filename, 'envelope', 'fsEnv', 'origLength');
end
