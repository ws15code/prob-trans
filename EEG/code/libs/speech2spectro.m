% Preprocess function given the audio files in the folder 'audioPath'
% and the bandpass filters in 'STRFfilters'
%      >> speech2spectro('./STRFfilters',speechEnvelope', 512, 512)
function STRFstimuli = speech2spectro(STRFfilters, auData, auFreq, fs)
    load(STRFfilters)
    for i = 1:length(Hd)
        disp(['Band' num2str(i) ': ' num2str(Fpass1(i)) '-' num2str(Fpass2(i))]);

        % Filtering
        filtAuData = filtfilthd(Hd(i), auData);

        % Getting the signal envelope
        hTrans = hilbert(mean(filtAuData,2));
        envelope = abs(hTrans); % Getting the average of the two stereo channels
        fineStructure = angle(mean(hTrans,2)); % Getting the average of the two stereo channels

        % Filtering + downsampling the signal
        envelope = resample(envelope, fs, auFreq);
        fineStructure = resample(fineStructure, fs, auFreq);

        % Filtering artifact correction - the envelope of an auditory
        % stimulus can't have negative values
        envelope(envelope < 0) = 0;
        
        idx = i; %1+(i-1)*2;
        STRFstimuli(idx,:) = envelope;
%         STRFstimuli(idx+1,:) = fineStructure;
    end
end
