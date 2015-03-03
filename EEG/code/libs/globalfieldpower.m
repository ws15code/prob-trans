% This is a function to calculate the global field power a la Skrandies.

% Written by Ed Lalor. 24/06/08

function [gfp] = globalfieldpower(EEG)
    gfp = zeros(1, size(EEG,2));
    for i = 1:size(EEG,2)
        gfp(i) = sqrt(sum((EEG(:,i) - mean(EEG(:,i))).^2));
    end
end