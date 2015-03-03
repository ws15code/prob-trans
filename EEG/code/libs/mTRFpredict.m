function [resp] = mTRFpredict(stim,W,Fs,start,fin)
% mTRFpredict Multivariate temporal response function prediction code.
%   [RESP] = MTRFPREDICT(STIM,W,FS,START,FIN) given an input stimulus STIM,
%   this function computes a prediction of the neural response based on the
%   provided model W, previously evaluated with the function mTRF.
%   The sampling frequency FS and the time-lags defined by START and FIN
%   must be the same used for building W with the function mTRF.
% 
%   Inputs:
%   stim   - stimulus input signal (frequency x time)
%   W      - forward mTRF (channels x frequency x time)
%   Fs     - sampling frequency of stimulus and neural data in Hertz
%   start  - start time lag of mTRF in milliseconds (default = -100ms)
%   fin    - stop time lag of mTRF in milliseconds (default = 400ms)
%   
%   Outputs:
%   resp   - neural response data (channels x time)
% 
%   Example: 
%   128-channel EEG was recorded at 512Hz. Stimulus was natural speech, 
%   presented at 48kHz for 2 minutes. The envelope of the speech waveform 
%   was got using a Hilbert transform and was then downsampled to 512Hz.
%
%    %%%  Forward model  %%%
%    >> [W,t] = mTRF(speechEnvelope,EEG,512,0,-200,500,[]);
%    >> chan = 85;
%    >> figure; plot(t,W(chan,:));
%    >> [resp] = mTRFpredict(speechEnvelope,W,512,-200,500);
%    >> respToPlot = (resp(chan,:) - mean(resp(chan,:))) / std(resp(chan,:));
%    >> eegToPlot = (EEG(chan,:) - mean(EEG(chan,:))) / std(EEG(chan,:));
%    >> figure; hold on; plot(respToPlot, 'b'); plot(eegToPlot, 'r')
%    >> [r,p] = corr(respToPlot',eegToPlot');
%    >> disp(['[r, p] = [' num2str(r) ', ' num2str(p) ']' ])
%
%    %%%  Forward spectrotemporal model  %%%
%    >> load('spectroSpeech.mat')
%    >> chan = 85;
%    >> [W,t] = mTRF(spectro,EEG,512,0,-20,300,10);
%    >> figure;
%    >> surface(t,1:16,squeeze(W(chan,:,:))); shading('flat'); caxis([-5.0 5.0])
%    >> [resp] = mTRFpredict(spectro,W,512,-20,300);
%    >> respToPlot = (resp(chan,:) - mean(resp(chan,:))) / std(resp(chan,:));
%    >> eegToPlot = (EEG(chan,:) - mean(EEG(chan,:))) / std(EEG(chan,:));
%    >> figure; hold on; plot(respToPlot, 'b'); plot(eegToPlot, 'r')
%    >> [r,p] = corr(respToPlot',eegToPlot');
%    >> disp(['[r, p] = [' num2str(r) ', ' num2str(p) ']' ])
%
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
window = length(start:fin);

% Lag generation
X = LagGenerator(stim', start:fin)';
w = reshape(W, size(W,1), size(X,1));
resp = w * X;

end 