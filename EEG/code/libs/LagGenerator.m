function [lagMat] = LagGenerator(mat,lags)
% LagGenerator
%   [lagMat]=LagGenerator(mat,lags) returns a lag matrix obtained from the
%   input matrix 'mat'. The returned matrix will have some zero-padded
%   parts when any positive or negative time lag is used.
%
%   Inputs:
%   mat         - data matrix (time x channels) or (time x frequencies)
%   lags        - array of the time-lags to use (e.g.: 1:3:15)
%   
%   Outputs:
%   lagMat      - lag data matrix (time x (channels x length(lags))) or
%                                 (time x (frequencies x length(lags)))
%
    dim = size(mat,2);
    % Init output
    lagMat = zeros(size(mat,1),dim*length(lags));
    % Init output index
    idx = 1;
    % For each time lag specified
    for i = 1:length(lags)
        % Shifts with zero-padding
        localLagMat = shift(mat,lags(i));
        % Updates the output with the shifted matrix
        lagMat(:,idx:idx+dim-1) = localLagMat(1:size(mat,1),:);
        % Updates the output index
        idx = idx + dim;
    end
end