function [W,t] = mTRF(stim,resp,Fs,dir,start,fin,lambda)
% mTRF Multivariate temporal response function.
%   [W,T] = MTRF(STIM,RESP,FS) performs a ridge regression on the stimulus 
%   input STIM and the neural response data RESP, both with a sampling 
%   frequency FS, to solve for the multivariate temporal response function 
%   (mTRF) W and its time axis T. The mTRF represents the linear forward- 
%   mapping from RESP to STIM and is described by the equation:
% 
%                       w = inv(X*X'+lamda*M)*(X*Y')                         
%
%   where X is a matrix of stimulus lags, Y is the neural response, M is 
%   the regularisation term used to prevent overfitting and LAMBDA is the 
%   ridge parameter.
% 
%   [W,T] = MTRF(STIM,RESP,FS,DIR,START,FIN,LAMBDA) calculates the mTRF in 
%   the direction DIR. Pass in DIR==0 to use the default forward mapping or 
%   1 to use backward mapping. The time window over which the mTRF is 
%   calculated with respect to the stimulus is set between time lags START 
%   and FIN in milliseconds. The regularisation uses a ridge parameter 
%   LAMBDA. 
% 
%   Inputs:
%   stim   - stimulus input signal (frequency x time)
%   resp   - neural response data (channels x time)
%   Fs     - sampling frequency of stimulus and neural data in Hertz
%   dir    - direction of mapping: 0 = forward, 1 = backward (default = 0)
%   start  - start time lag of mTRF in milliseconds (default = -100ms)
%   fin    - stop time lag of mTRF in milliseconds (default = 400ms)
%   lambda - ridge parameter for regularisation (default = max(XXT))
%   
%   Outputs:
%   W      - mTRF (channels x frequency x time)
%   t      - time axis of mTRF in milliseconds (1 x time)
% 
%   See Readme for examples of use. 
%
%   See also mTRFpredict mTRFreconstruct.

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
%   Last revision: 09 May 2014

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

if ~exist('dir','var') || isempty(dir) || dir == 0
    x = stim;
    y = resp;
    dir = 0;
elseif dir == 1
    x = resp;
    y = stim;
    [start,fin] = deal(-fin,-start);
end

% Calculate XXT matrix
X = LagGenerator(x',start:fin)';

% keepIdx = find(sum(X) > 0);
% X = X(:,keepIdx);
% x = x(:,keepIdx);
% y = y(:,keepIdx);

% x = zscore(x')';
% y = zscore(y')';

% [XL,YL,Xs,Ys,beta,pctVar,mse,stats] = plsregress(X',y',10);%,'CV',10); % env - 10 components; ph - 25-35 components (plateau large --> 30) (skewed left)
% % figure;plot(mse(2,:))
% W = beta(2:end,:)';

constant = ones(size(x,1),size(X,2));
X = [constant;X];
XXT = X*X';

% Calculate XY matrix
XY = X*y';

% Set up regularisation
if ~exist('lambda','var') || isempty(lambda)
    lambda = max(max(abs(XXT)));
end
d = 2*eye(size(XXT)); d(1,1) = 1; d(size(XXT,1),size(XXT,2)) = 1;
u = [zeros(size(XXT,1)-1,1),eye(size(XXT)-1);zeros(1,size(XXT,2))];    
l = [zeros(1,size(XXT,2));eye(size(XXT)-1),zeros(size(XXT,1)-1,1)];
M = d-u-l;
lambdaM = lambda*M;

% Calculate mTRF and its time axis
W = (XXT+lambdaM)\XY;
if dir == 0
    W = squeeze(reshape(W(size(stim,1)+1:end,:)',size(resp,1),size(stim,1),window));
elseif dir == 1
    W = squeeze(reshape(W(size(resp,1)+1:end,:)',size(stim,1),size(resp,1),window));
end
% W = squeeze(reshape(W,size(resp,1),size(stim,1),window));
t = (start:fin)/Fs*1e3;

end 
