function [stim] = mTRFreconstruct(resp,G,Fs,start,fin)
% mTRFpredict Multivariate temporal response function prediction code.
%   [RESP] = MTRFRECONSTRUCT(RESP,G,FS,START,FIN) given a neural response EEG,
%   this function computes a reconstruction of the input stimulus based on the
%   provided model G, previously evaluated with the function mTRF.
%   The sampling frequency FS and the time-lags defined by START and FIN
%   must be the same used for building G with the function mTRF.
% 
%   Inputs:
%   resp   - neural response data (channels x time)
%   G      - backward mTRF (channels x frequency x time)
%   Fs     - sampling frequency of stimulus and neural data in Hertz
%   start  - start time lag of mTRF in milliseconds (default = -100ms)
%   fin    - stop time lag of mTRF in milliseconds (default = 400ms)
%   
%   Outputs:
%   stim   - stimulus input signal (frequency x time)
% 
%   Example:
%   128-channel EEG was recorded at 512Hz. Stimulus was natural speech, 
%   presented at 48kHz for 2 minutes. The envelope of the speech waveform 
%   was got using a Hilbert transform and was then downsampled to 512Hz.
%
%    %%%  Backward model  %%%
%    >> speech64 = resample(speechEnvelope, 64, 512);
%    >> EEG64 = resample(EEG', 64, 512)';
%    >> [G,t] = mTRF(speech64,EEG64,64,1,-200,500,[]);
%    >> [stim] = mTRFreconstruct(EEG64,G,64,-200,500);
%    >> recToPlot = (stim - mean(stim)) / std(stim);
%    >> stimToPlot = (speech64 - mean(speech64)) / std(speech64);
%    >> figure; hold on; plot(recToPlot, 'b'); plot(stimToPlot, 'r')
%    >> [r,p] = corr(recToPlot',stimToPlot');
%    >> disp(['[r, p] = [' num2str(r) ', ' num2str(p) ']' ])
%
%    %%%  Backward spectrotemporal model  %%%
%    >> spectro64 = resample(spectro', 64, 512)';
%    >> [G,t] = mTRF(spectro64,EEG64,64,1,-20,300,[]);
%    >> figure;
%    >> surface(t,1:128,squeeze(G(3,:,:))); shading('flat');
%    >> [stim] = mTRFreconstruct(EEG64,G,64,-20,300);
%    >> freqIdx = 1;
%    >> stimToPlot = (stim(freqIdx,:) - mean(stim(freqIdx,:))) / std(stim(freqIdx,:));
%    >> eegToPlot = (EEG64(freqIdx,:) - mean(EEG64(freqIdx,:))) / std(EEG64(freqIdx,:));
%    >> figure; hold on; plot(stimToPlot, 'b'); plot(eegToPlot, 'r')
%    >> [r,p] = corr(stimToPlot',eegToPlot');
%    >> disp(['[r, p] = [' num2str(r) ', ' num2str(p) ']' ])

%% Training/Testing on distinct chunks of data
%%%  Backward model  %%%
% speech64 = resample(speechEnvelope, 64, 512);
% EEG64 = resample(EEG', 64, 512)';
% len = size(EEG64,2);
% speechTrain = speech64(1:len/2);
% speechTest  = speech64(len/2+1:end);
% EEGTrain    = EEG64(:,1:len/2);
% EEGTest     = EEG64(:,len/2+1:end);
% [G,t] = mTRF(speechTrain,EEGTrain,64,1,-200,500,[]);
% [stim] = mTRFreconstruct(EEGTest,G,64,-200,500);
% recToPlot = (stim - mean(stim)) / std(stim);
% stimToPlot = (speechTest - mean(speechTest)) / std(speechTest);
% figure; hold on; plot(recToPlot, 'b'); plot(stimToPlot, 'r')
% [r,p] = corr(recToPlot',stimToPlot');
% disp(['[r, p] = [' num2str(r) ', ' num2str(p) ']' ])

%   See also mTRF.

%   References:
%      [1] Lalor EC, Pearlmutter BA, Reilly RB, McDarby G, Foxe JJ (2006). 
%          The VESPA: a method for the rapid estimation of a visual evoked 
%          potential. NeuroImage, 32:1549-1561.
%      [2] Lalor EC, Power AP, Reilly RB, Foxe JJ (2009). Resolving precise 
%          temporal processing properties of the auditory system using 
%          continuous stimuli. Journal of Neurophysiology, 102(1):349-359.

%   Author: Edmund Lalor & Lab, Trinity College Dublin
%   Email: edmundlalor@gmail.com
%   Website: http://sourceforge.net/projects/aespa/
%   Version: 1.0
%   Last revision: 15 May 2014

[start,fin] = deal(-fin,-start);
if ~exist('start','var') || isempty(start)
    start = floor(-0.1*Fs);
else
    start = floor(start/1e3*Fs);
end
if ~exist('fin','var') || isempty(fin)
    fin = ceil(0.4*Fs);
else
    fin = ceil(fin/1e3*Fs);
end

% Lag generation
Y = LagGenerator(resp', start:fin)';
if (ndims(G) == 3)
    g = reshape(G, size(G,1), size(G,2)*size(G,3));
else
    g = reshape(G, 1, size(G,1)*size(G,2));
end

stim = g * Y;

end
