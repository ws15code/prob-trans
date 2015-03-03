%% Conversion local functions samples-time[ms] %%
% Sample to time point, given the sampling frequency FS
function ret = samp2time(samp,FS)
	ret = samp/FS * 1000;
