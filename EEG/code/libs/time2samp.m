%% Conversion local functions samples-time[ms] %%
% Time to sample point, given the sampling frequency FS
function ret = time2samp(time,FS)
	ret = time/1000 * FS;