stimuliIdx = 1:28; % 28 audio files

% Pilot experiment 1, part 1
repetitions = 143;
presentationOrder1 = repmat(stimuliIdx,1,repetitions);
presentationOrder1 = presentationOrder1(randperm(length(presentationOrder1)));

% Pilot experiment 1, part 2
repetitions = 250;
presentationOrder2 = repmat(stimuliIdx,1,repetitions);
presentationOrder2 = presentationOrder2(randperm(length(presentationOrder2)));

toSave = 0;
if toSave
    save('presentationOrder.mat','presentationOrder1','presentationOrder2')

    fid=fopen('presentationOrder1.txt','wt');
    fprintf(fid,'%d,',presentationOrder1(1:(end-1)));
    fprintf(fid,'%d',presentationOrder1(end));
    fclose(fid);

    fid=fopen('presentationOrder2.txt','wt');
    fprintf(fid,'%d,',presentationOrder2(1:(end-1)));
    fprintf(fid,'%d',presentationOrder2(end));
    fclose(fid);
end