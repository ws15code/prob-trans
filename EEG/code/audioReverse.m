[filenames, pathname, filterindex] = uigetfile( '*.wav','WAV-files (*.wav)', 'Pick a file', 'MultiSelect', 'on');
filenames = cellstr(filenames);   %in case only one selected
for K = 1:length(filename)
  thisfullname = fullfile(pathname, filenames{K});
  [speechIn6,FS6]=audioread(thisfullname);
  speechIn6 = flip(speechIn6);
  audiowrite(fullfile([pathname 'reverse/'], filenames{K}),speechIn6,FS6)
%   speechIn6 = myVAD(speechIn6);
%   fMatrix6(1,o) = {mfccf(ncoeff,speechIn6,FS6)};
end