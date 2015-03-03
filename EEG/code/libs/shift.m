% shift
%   shiftedMat = shift(mat, pos) shifts the values in the matrix 'mat' by
%   'pos' elements along the first dimension. The returned matrix
%   will have zero-padding on the top or bottom part, if pos is positive or
%   negative respectively.
%
%   Inputs:
%   mat         - data matrix
%   pos         - number of position to shift
%   
%   Outputs:
%   shiftedMat  - shifted data matrix (with zero-padding)
%
function shiftedMat = shift(mat, pos)
    shiftedMat = circshift(mat,pos);
    % Zero-padding portion
    if pos < 0
        shiftedMat(end-abs(pos)+1:end,:) = 0;
    else
        shiftedMat(1:pos,:) = 0;
    end
end