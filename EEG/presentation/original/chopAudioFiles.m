% Multiselection
% Chop off, volume correction, upsampling, mono2stereo
% Needed in postprocessing: to check the chopping time-points
%                           to check quality ('te' corrected)

[filenames, pathname, filterindex] = uigetfile( ...
                                    '*.wav','WAV-files (*.wav)', ... 
                                    'Pick a file', ... 
                                    'MultiSelect', 'on');
for K = 1 : length(filenames)
    thisfullname = fullfile(pathname, filenames{K});
    [speechIn,FS]=audioread(thisfullname);
    % Chop off the silence
    cutValue = std(speechIn)/2;
    timeCutStart = find((abs(speechIn)<abs(cutValue))==0,1,'first') - FS*0.07; % adding 100 ms at the beginning
    timeCutEnd = find((abs(speechIn)<abs(cutValue))==0,1,'last') + FS*0.07;     % adding 50 ms at the beginning
    speechIn = speechIn(max(1,timeCutStart):min(length(speechIn),timeCutEnd));
    % Volume correction
    if K == 1
        vol = std(speechIn);
    else
        speechIn = speechIn .* (vol / std(speechIn));
    end
    % Upsampling to 44100Hz
    speechIn = resample(speechIn,44100,FS);
    FS = 44100;
    % Mono 2 Stereo
    speechIn = [speechIn,speechIn];
    % Saving
    thisfullname = fullfile([pathname 'chopped/'], filenames{K});
    audiowrite(thisfullname,speechIn,FS)
end